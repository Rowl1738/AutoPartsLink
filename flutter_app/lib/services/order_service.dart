import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../core/constants/firestore_collections.dart';
import '../core/services/session.dart';
import '../core/utils/app_error.dart';
import '../core/utils/firestore_parsing.dart';
import '../models/order.dart';
import '../models/user.dart';
import 'notification_service.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection(FirestoreCollections.orders);
  CollectionReference<Map<String, dynamic>> get _quotations => _db.collection(FirestoreCollections.quotations);
  CollectionReference<Map<String, dynamic>> get _requests => _db.collection(FirestoreCollections.procurementRequests);

  Future<List<Order>> listOrders() async {
    final user = Session.user;
    final Query<Map<String, dynamic>> query = switch (user.role) {
      UserRole.admin => _orders,
      UserRole.customer => _orders.where("customerId", isEqualTo: user.id),
      UserRole.supplier => _orders.where("supplierId", isEqualTo: user.id),
    };
    final snapshot = await query.get();
    return snapshot.docs.map((d) => Order.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Order> getOrder(String id) async {
    final doc = await _orders.doc(id).get();
    if (!doc.exists) throw const AppException("Order not found.");
    return Order.fromMap(doc.id, doc.data()!);
  }

  /// Customer accepts a supplier's quotation, which becomes an Order.
  /// Marks the quotation ACCEPTED, rejects the request's other quotations,
  /// and advances the request to ORDER_CREATED — all in one transaction.
  Future<Order> acceptQuotation({
    required String quotationId,
    required String fulfilmentMethod,
    String deliveryAddress = "",
  }) async {
    final customer = Session.user;
    if (fulfilmentMethod == "DELIVERY" && deliveryAddress.trim().isEmpty) {
      throw const AppException("Delivery address is required for delivery orders.");
    }

    final quotationRef = _quotations.doc(quotationId);
    final first = (await quotationRef.get()).data();
    if (first == null || first["customerId"] != customer.id) {
      throw const AppException("You may only accept quotations on your own procurement requests.");
    }
    final requestId = first["requestId"] as String;
    // Transactions can't run queries, so find the sibling quotations first
    // and re-read each one inside the transaction.
    final siblings = await _quotations
        .where("requestId", isEqualTo: requestId)
        .where("customerId", isEqualTo: customer.id)
        .get();
    final siblingRefs = siblings.docs.where((d) => d.id != quotationId).map((d) => d.reference).toList();
    final requestRef = _requests.doc(requestId);
    final orderRef = _orders.doc(quotationId);

    await _db.runTransaction((tx) async {
      final quotation = (await tx.get(quotationRef)).data()!;
      if (quotation["status"] != "SUBMITTED") throw const AppException("This quotation is no longer available to accept.");
      final request = (await tx.get(requestRef)).data();
      if (request == null) throw const AppException("Request not found.");
      final rejected = <Map<String, dynamic>>[];
      for (final ref in siblingRefs) {
        final data = (await tx.get(ref)).data();
        if (data != null && data["status"] == "SUBMITTED") rejected.add({"ref": ref, ...data});
      }

      final orderRefCode = shortRef(orderRef.id);
      final now = Timestamp.now(); // serverTimestamp() isn't allowed inside arrays
      tx.set(orderRef, {
        "quotationId": quotationId,
        "requestId": requestId,
        "customerId": customer.id,
        "customerName": customer.username,
        "supplierId": quotation["supplierId"],
        "supplierName": quotation["supplierName"],
        "status": "ORDER_PLACED",
        "fulfilmentMethod": fulfilmentMethod,
        "deliveryAddress": deliveryAddress,
        "items": quotation["items"], // unit prices snapshotted from the quotation
        "statusHistory": [
          {"fromStatus": "", "toStatus": "ORDER_PLACED", "changedById": customer.id, "changedByName": customer.username, "note": "", "changedAt": now},
        ],
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
      tx.update(quotationRef, {"status": "ACCEPTED", "updatedAt": FieldValue.serverTimestamp()});
      for (final other in rejected) {
        tx.update(other["ref"] as DocumentReference, {"status": "REJECTED", "updatedAt": FieldValue.serverTimestamp()});
      }
      tx.update(requestRef, {"status": "ORDER_CREATED", "updatedAt": FieldValue.serverTimestamp()});

      tx.set(NotificationService.newRef(), NotificationService.payload(
        recipientId: quotation["supplierId"], event: NotificationEvent.newOrder,
        message: "${customer.username} accepted your quotation — order #$orderRefCode placed.",
      ));
      tx.set(NotificationService.newRef(), NotificationService.payload(
        recipientId: customer.id, event: NotificationEvent.orderPlaced,
        message: "Your order #$orderRefCode with ${quotation["supplierName"]} has been placed.",
      ));
      for (final other in rejected) {
        tx.set(NotificationService.newRef(), NotificationService.payload(
          recipientId: other["supplierId"], event: NotificationEvent.quotationRejected,
          message: "Your quotation for request #${shortRef(requestId)} was not selected.",
        ));
      }
    });

    return getOrder(orderRef.id);
  }

  /// Supplier (or admin) moves the order to a new status; every change is
  /// appended to statusHistory and the customer is notified.
  Future<Order> updateStatus(String orderId, {required String status, String note = ""}) async {
    final user = Session.user;
    final orderRef = _orders.doc(orderId);

    await _db.runTransaction((tx) async {
      final order = (await tx.get(orderRef)).data();
      if (order == null) throw const AppException("Order not found.");
      if (user.role != UserRole.admin && order["supplierId"] != user.id) {
        throw const AppException("Only this order's supplier can update its status.");
      }
      final oldStatus = order["status"] as String;
      if (oldStatus == "COMPLETED" || oldStatus == "CANCELLED") {
        throw AppException("Order is already $oldStatus and cannot be changed further.");
      }
      if (status == oldStatus) throw const AppException("Order is already in that status.");

      tx.update(orderRef, {
        "status": status,
        "statusHistory": FieldValue.arrayUnion([
          {"fromStatus": oldStatus, "toStatus": status, "changedById": user.id, "changedByName": user.username, "note": note, "changedAt": Timestamp.now()},
        ]),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      final ref = shortRef(orderId);
      if (status == "COMPLETED") {
        tx.update(_requests.doc(order["requestId"]), {"status": "COMPLETED", "updatedAt": FieldValue.serverTimestamp()});
      }
      tx.set(NotificationService.newRef(), NotificationService.payload(
        recipientId: order["customerId"],
        event: status == "COMPLETED" ? NotificationEvent.orderCompleted : NotificationEvent.orderStatusChanged,
        message: status == "COMPLETED"
            ? "Order #$ref is complete."
            : "Order #$ref is now ${orderStatusLabel(orderStatusFromString(status))}.",
      ));
    });

    return getOrder(orderId);
  }
}
