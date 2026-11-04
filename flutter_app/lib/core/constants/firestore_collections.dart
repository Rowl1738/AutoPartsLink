/// Top-level Firestore collection names. Must stay in sync with the
/// `match` paths in firestore.rules.
class FirestoreCollections {
  /// users/{uid} — private account record (role, approval, contact details).
  static const String users = "users";

  /// suppliers/{uid} — public supplier directory entry / business profile.
  static const String suppliers = "suppliers";

  static const String procurementRequests = "procurementRequests";

  /// quotations/{requestId}_{supplierUid} — the deterministic ID enforces
  /// one quotation per supplier per request.
  static const String quotations = "quotations";

  /// orders/{quotationId} — sharing the quotation's ID enforces one order
  /// per accepted quotation.
  static const String orders = "orders";

  /// ratings/{orderId} — one rating per completed order.
  static const String ratings = "ratings";

  static const String notifications = "notifications";
}
