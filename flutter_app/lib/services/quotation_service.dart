import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../core/services/session.dart';
import '../core/utils/app_error.dart';
import '../models/quotation.dart';
import '../models/user.dart';
import 'notification_service.dart';
import 'procurement_service.dart';

class QuotationService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _quotations => _db.collection(FirestoreCollections.quotations);
  CollectionReference<Map<String, dynamic>> get _requests => _db.collection(FirestoreCollections.procurementRequests);

  Future<List<Quotation>> listQuotations() async {
    final user = Session.user;
    final Query<Map<String, dynamic>> query = switch (user.role) {
      UserRole.admin => _quotations,
      UserRole.supplier => _quotations.where("supplierId", isEqualTo: user.id),
      UserRole.customer => _quotations.where("customerId", isEqualTo: user.id),
    };
    final snapshot = await query.get();
    return snapshot.docs.map((d) => Quotation.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Quotation> getQuotation(String id) async {
    final doc = await _quotations.doc(id).get();
    if (!doc.exists) throw const AppException("Quotation not found.");
    return Quotation.fromMap(doc.id, doc.data()!);
  }

  /// Maps each line to the request's item (for its partName), rejecting
  /// lines that don't belong to this request.
  List<Map<String, dynamic>> _itemsFor(Map<String, dynamic> request, List<QuotationItem> items) {
    if (items.isEmpty) throw const AppException("A quotation must contain at least one item.");
    final partNames = {
      for (final item in (request["items"] as List? ?? [])) item["id"] as String: item["partName"] as String? ?? "",
    };
    return items.map((item) {
      final partName = partNames[item.requestItemId];
      if (partName == null) throw const AppException("Quotation items must match the request's items.");
      if (item.quantity <= 0 || item.unitPrice < 0) throw const AppException("Enter a valid price and quantity.");
      return item.toMap(partName: partName);
    }).toList();
  }

  Future<Quotation> createQuotation({
    required String requestId,
    int? expectedFulfilmentDays,
    String notes = "",
    DateTime? validUntil,
    required List<QuotationItem> items,
  }) async {
    final supplier = Session.user;
    if (supplier.role != UserRole.supplier || !supplier.isApproved) {
      throw const AppException("Supplier must be approved before submitting quotations.");
    }
    final quotationRef = _quotations.doc(Quotation.idFor(requestId: requestId, supplierId: supplier.id));
    final requestRef = _requests.doc(requestId);

    await _db.runTransaction((tx) async {
      final request = (await tx.get(requestRef)).data();
      if (request == null) throw const AppException("Request not found.");
      if (!ProcurementService.openStatuses.contains(request["status"])) {
        throw const AppException("This procurement request is no longer accepting quotations.");
      }

      tx.set(quotationRef, {
        "requestId": requestId,
        "customerId": request["customerId"],
        "supplierId": supplier.id,
        "supplierName": supplier.supplierProfile?.businessName.isNotEmpty == true
            ? supplier.supplierProfile!.businessName
            : supplier.username,
        "status": "SUBMITTED",
        "expectedFulfilmentDays": expectedFulfilmentDays,
        "notes": notes,
        "validUntil": validUntil == null ? null : Timestamp.fromDate(validUntil),
        "items": _itemsFor(request, items),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
      if (request["status"] == "OPEN") {
        tx.update(requestRef, {"status": "QUOTATIONS_RECEIVED", "updatedAt": FieldValue.serverTimestamp()});
      }
      tx.set(NotificationService.newRef(), NotificationService.payload(
        recipientId: request["customerId"],
        event: NotificationEvent.quotationReceived,
        message: "${supplier.username} submitted a quotation for your request.",
      ));
    }).catchError((Object e) {
      // Rules reject a second create on {requestId}_{supplierId}.
      if (e is FirebaseException && e.code == "permission-denied") {
        throw const AppException("You have already submitted a quotation for this request.");
      }
      throw e;
    });

    return getQuotation(quotationRef.id);
  }

  /// Always resends the full line list (no partial item edits), and only
  /// while the quotation is still SUBMITTED.
  Future<Quotation> updateQuotation(String id, {
    required String requestId,
    int? expectedFulfilmentDays,
    String notes = "",
    DateTime? validUntil,
    required List<QuotationItem> items,
  }) async {
    final quotationRef = _quotations.doc(id);
    await _db.runTransaction((tx) async {
      final quotation = (await tx.get(quotationRef)).data();
      if (quotation == null || quotation["supplierId"] != Session.uid) throw const AppException("Quotation not found.");
      if (quotation["status"] != "SUBMITTED") {
        throw const AppException("Only a quotation still in SUBMITTED status can be edited.");
      }
      final request = (await tx.get(_requests.doc(requestId))).data();
      if (request == null) throw const AppException("Request not found.");

      tx.update(quotationRef, {
        "expectedFulfilmentDays": expectedFulfilmentDays,
        "notes": notes,
        "validUntil": validUntil == null ? null : Timestamp.fromDate(validUntil),
        "items": _itemsFor(request, items),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    });
    return getQuotation(id);
  }
}
