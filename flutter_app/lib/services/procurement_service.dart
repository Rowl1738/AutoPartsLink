import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../core/services/session.dart';
import '../core/utils/app_error.dart';
import '../models/procurement_request.dart';
import '../models/user.dart';
import 'notification_service.dart';

class ProcurementService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests => _db.collection(FirestoreCollections.procurementRequests);

  static const openStatuses = ["OPEN", "QUOTATIONS_RECEIVED"];

  /// Customers see their own requests; suppliers see requests still taking
  /// quotations plus any they've already quoted on; admins see everything.
  Future<List<ProcurementRequest>> listRequests() async {
    final user = Session.user;
    final docs = <String, Map<String, dynamic>>{};

    switch (user.role) {
      case UserRole.admin:
        for (final d in (await _requests.get()).docs) {
          docs[d.id] = d.data();
        }
      case UserRole.customer:
        for (final d in (await _requests.where("customerId", isEqualTo: user.id).get()).docs) {
          docs[d.id] = d.data();
        }
      case UserRole.supplier:
        for (final d in (await _requests.where("status", whereIn: openStatuses).get()).docs) {
          docs[d.id] = d.data();
        }
        final myQuotes = await _db.collection(FirestoreCollections.quotations).where("supplierId", isEqualTo: user.id).get();
        final quotedIds = myQuotes.docs.map((d) => d.data()["requestId"] as String).where((id) => !docs.containsKey(id)).toList();
        // whereIn accepts at most 30 values per query.
        for (var i = 0; i < quotedIds.length; i += 30) {
          final chunk = quotedIds.sublist(i, i + 30 > quotedIds.length ? quotedIds.length : i + 30);
          for (final d in (await _requests.where(FieldPath.documentId, whereIn: chunk).get()).docs) {
            docs[d.id] = d.data();
          }
        }
    }

    return docs.entries.map((e) => ProcurementRequest.fromMap(e.key, e.value)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<ProcurementRequest> getRequest(String id) async {
    final doc = await _requests.doc(id).get();
    if (!doc.exists) throw const AppException("Request not found.");
    return ProcurementRequest.fromMap(doc.id, doc.data()!);
  }

  Future<ProcurementRequest> createRequest({
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String description,
    required String urgency,
    required String preferredLocation,
    required List<ProcurementRequestItem> items,
  }) async {
    final user = Session.user;
    if (user.role != UserRole.customer) throw const AppException("Only customers can create procurement requests.");
    if (items.isEmpty) throw const AppException("A procurement request must contain at least one item.");
    if (vehicleYear < 1970 || vehicleYear > DateTime.now().year + 1) {
      throw const AppException("Enter a valid vehicle year.");
    }

    final ref = _requests.doc();
    await ref.set({
      "customerId": user.id,
      "customerName": user.username,
      "vehicleMake": vehicleMake,
      "vehicleModel": vehicleModel,
      "vehicleYear": vehicleYear,
      "description": description,
      "imageUrl": null,
      "urgency": urgency,
      "preferredLocation": preferredLocation,
      "status": "OPEN", // immediately visible to suppliers
      "items": [for (var i = 0; i < items.length; i++) items[i].toMap(id: "item-${i + 1}")],
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await _notifyApprovedSuppliers(
      "New request from ${user.username}: $vehicleMake $vehicleModel ($vehicleYear).",
    );
    return getRequest(ref.id);
  }

  Future<void> _notifyApprovedSuppliers(String message) async {
    final suppliers = await _db.collection(FirestoreCollections.suppliers).where("isApproved", isEqualTo: true).get();
    // A batch holds at most 500 writes.
    for (var i = 0; i < suppliers.docs.length; i += 450) {
      final batch = _db.batch();
      for (final supplier in suppliers.docs.skip(i).take(450)) {
        batch.set(NotificationService.newRef(), NotificationService.payload(
          recipientId: supplier.id, event: NotificationEvent.newProcurementRequest, message: message,
        ));
      }
      await batch.commit();
    }
  }

  Future<void> deleteRequest(String id) async {
    final request = await getRequest(id);
    if (request.status != RequestStatus.submitted && request.status != RequestStatus.open) {
      throw const AppException("This request can no longer be deleted (quotations are already in progress).");
    }
    await _requests.doc(id).delete();
  }
}
