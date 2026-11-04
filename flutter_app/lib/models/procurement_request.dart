import '../core/utils/firestore_parsing.dart';

enum RequestStatus { submitted, open, quotationsReceived, supplierSelected, orderCreated, completed, cancelled }
enum RequestUrgency { low, normal, high, urgent }

RequestStatus requestStatusFromString(String s) {
  switch (s.toUpperCase()) {
    case "SUBMITTED":
      return RequestStatus.submitted;
    case "OPEN":
      return RequestStatus.open;
    case "QUOTATIONS_RECEIVED":
      return RequestStatus.quotationsReceived;
    case "SUPPLIER_SELECTED":
      return RequestStatus.supplierSelected;
    case "ORDER_CREATED":
      return RequestStatus.orderCreated;
    case "COMPLETED":
      return RequestStatus.completed;
    default:
      return RequestStatus.cancelled;
  }
}

String requestStatusToApiString(RequestStatus s) {
  switch (s) {
    case RequestStatus.submitted:
      return "SUBMITTED";
    case RequestStatus.open:
      return "OPEN";
    case RequestStatus.quotationsReceived:
      return "QUOTATIONS_RECEIVED";
    case RequestStatus.supplierSelected:
      return "SUPPLIER_SELECTED";
    case RequestStatus.orderCreated:
      return "ORDER_CREATED";
    case RequestStatus.completed:
      return "COMPLETED";
    case RequestStatus.cancelled:
      return "CANCELLED";
  }
}

String requestStatusLabel(RequestStatus s) {
  switch (s) {
    case RequestStatus.submitted:
      return "Submitted";
    case RequestStatus.open:
      return "Open";
    case RequestStatus.quotationsReceived:
      return "Quotations Received";
    case RequestStatus.supplierSelected:
      return "Supplier Selected";
    case RequestStatus.orderCreated:
      return "Order Created";
    case RequestStatus.completed:
      return "Completed";
    case RequestStatus.cancelled:
      return "Cancelled";
  }
}

RequestUrgency urgencyFromString(String s) {
  switch (s.toUpperCase()) {
    case "LOW":
      return RequestUrgency.low;
    case "HIGH":
      return RequestUrgency.high;
    case "URGENT":
      return RequestUrgency.urgent;
    default:
      return RequestUrgency.normal;
  }
}

String urgencyToString(RequestUrgency u) {
  switch (u) {
    case RequestUrgency.low:
      return "LOW";
    case RequestUrgency.normal:
      return "NORMAL";
    case RequestUrgency.high:
      return "HIGH";
    case RequestUrgency.urgent:
      return "URGENT";
  }
}

String urgencyLabel(RequestUrgency u) => urgencyToString(u)[0] + urgencyToString(u).substring(1).toLowerCase();

class ProcurementRequestItem {
  /// Stable ID within the request (e.g. "item-1"), referenced by quotation lines.
  final String? id;
  final String partName;
  final String partNumber;
  final int quantity;
  final String description;

  ProcurementRequestItem({
    this.id,
    required this.partName,
    this.partNumber = "",
    required this.quantity,
    this.description = "",
  });

  factory ProcurementRequestItem.fromMap(Map<String, dynamic> data) => ProcurementRequestItem(
        id: data["id"],
        partName: data["partName"] ?? "",
        partNumber: data["partNumber"] ?? "",
        quantity: toInt(data["quantity"]),
        description: data["description"] ?? "",
      );

  Map<String, dynamic> toMap({required String id}) => {
        "id": id,
        "partName": partName,
        "partNumber": partNumber,
        "quantity": quantity,
        "description": description,
      };
}

class ProcurementRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final String description;
  final String? imageUrl;
  final RequestUrgency urgency;
  final String preferredLocation;
  final RequestStatus status;
  final List<ProcurementRequestItem> items;
  final DateTime createdAt;

  ProcurementRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    this.description = "",
    this.imageUrl,
    required this.urgency,
    this.preferredLocation = "",
    required this.status,
    this.items = const [],
    required this.createdAt,
  });

  /// Short display reference, e.g. "Request #K3F9QZ".
  String get reference => shortRef(id);

  factory ProcurementRequest.fromMap(String id, Map<String, dynamic> data) => ProcurementRequest(
        id: id,
        customerId: data["customerId"] ?? "",
        customerName: data["customerName"] ?? "",
        vehicleMake: data["vehicleMake"] ?? "",
        vehicleModel: data["vehicleModel"] ?? "",
        vehicleYear: toInt(data["vehicleYear"]),
        description: data["description"] ?? "",
        imageUrl: data["imageUrl"],
        urgency: urgencyFromString(data["urgency"] ?? "NORMAL"),
        preferredLocation: data["preferredLocation"] ?? "",
        status: requestStatusFromString(data["status"] ?? "OPEN"),
        items: (data["items"] as List? ?? []).map((e) => ProcurementRequestItem.fromMap(Map<String, dynamic>.from(e))).toList(),
        createdAt: toDateTime(data["createdAt"]),
      );
}
