import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_collections.dart';
import '../core/services/session.dart';
import '../models/app_notification.dart';

/// Event names for notifications/{id}.event (unchanged from the old API).
class NotificationEvent {
  static const newProcurementRequest = "NEW_PROCUREMENT_REQUEST";
  static const quotationReceived = "QUOTATION_RECEIVED";
  static const quotationRejected = "QUOTATION_REJECTED";
  static const orderPlaced = "ORDER_PLACED";
  static const newOrder = "NEW_ORDER";
  static const orderStatusChanged = "ORDER_STATUS_CHANGED";
  static const orderCompleted = "ORDER_COMPLETED";
  static const supplierApproved = "SUPPLIER_APPROVED";
}

class NotificationService {
  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(FirestoreCollections.notifications);

  Future<List<AppNotification>> listNotifications() async {
    final snapshot = await _collection.where("recipientId", isEqualTo: Session.uid).get();
    return snapshot.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markRead(String id) => _collection.doc(id).update({"isRead": true});

  /// Notifications are written alongside the change that triggers them, in
  /// the same batch/transaction — callers do `tx.set(newRef(), payload(...))`.
  static DocumentReference<Map<String, dynamic>> newRef() => _collection.doc();

  static Map<String, dynamic> payload({required String recipientId, required String event, required String message}) => {
        "recipientId": recipientId,
        "senderId": Session.uid,
        "event": event,
        "message": message,
        "isRead": false,
        "createdAt": FieldValue.serverTimestamp(),
      };
}
