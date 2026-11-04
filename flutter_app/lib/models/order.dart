import '../core/utils/firestore_parsing.dart';

enum OrderStatus { orderPlaced, orderAccepted, processing, readyForCollection, outForDelivery, completed, cancelled }
enum FulfilmentMethod { delivery, collection }

OrderStatus orderStatusFromString(String s) {
  switch (s.toUpperCase()) {
    case "ORDER_ACCEPTED":
      return OrderStatus.orderAccepted;
    case "PROCESSING":
      return OrderStatus.processing;
    case "READY_FOR_COLLECTION":
      return OrderStatus.readyForCollection;
    case "OUT_FOR_DELIVERY":
      return OrderStatus.outForDelivery;
    case "COMPLETED":
      return OrderStatus.completed;
    case "CANCELLED":
      return OrderStatus.cancelled;
    default:
      return OrderStatus.orderPlaced;
  }
}

String orderStatusToApiString(OrderStatus s) {
  switch (s) {
    case OrderStatus.orderPlaced:
      return "ORDER_PLACED";
    case OrderStatus.orderAccepted:
      return "ORDER_ACCEPTED";
    case OrderStatus.processing:
      return "PROCESSING";
    case OrderStatus.readyForCollection:
      return "READY_FOR_COLLECTION";
    case OrderStatus.outForDelivery:
      return "OUT_FOR_DELIVERY";
    case OrderStatus.completed:
      return "COMPLETED";
    case OrderStatus.cancelled:
      return "CANCELLED";
  }
}

String orderStatusLabel(OrderStatus s) {
  switch (s) {
    case OrderStatus.orderPlaced:
      return "Order Placed";
    case OrderStatus.orderAccepted:
      return "Order Accepted";
    case OrderStatus.processing:
      return "Processing";
    case OrderStatus.readyForCollection:
      return "Ready for Collection";
    case OrderStatus.outForDelivery:
      return "Out for Delivery";
    case OrderStatus.completed:
      return "Completed";
    case OrderStatus.cancelled:
      return "Cancelled";
  }
}

/// The forward progression a supplier can move an order through (excludes
/// CANCELLED, which is offered separately as an escape hatch in the UI).
const List<OrderStatus> orderStatusFlow = [
  OrderStatus.orderPlaced,
  OrderStatus.orderAccepted,
  OrderStatus.processing,
  OrderStatus.readyForCollection,
  OrderStatus.outForDelivery,
  OrderStatus.completed,
];

class OrderItem {
  final String requestItemId;
  final String partName;
  final int quantity;
  final double unitPrice;

  OrderItem({required this.requestItemId, required this.partName, required this.quantity, required this.unitPrice});

  double get subtotal => quantity * unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> data) => OrderItem(
        requestItemId: data["requestItemId"] ?? "",
        partName: data["partName"] ?? "",
        quantity: toInt(data["quantity"]),
        unitPrice: toDouble(data["unitPrice"]),
      );
}

class OrderStatusHistoryEntry {
  final String fromStatus;
  final String toStatus;
  final String? changedByName;
  final String note;
  final DateTime changedAt;

  OrderStatusHistoryEntry({
    required this.fromStatus,
    required this.toStatus,
    this.changedByName,
    this.note = "",
    required this.changedAt,
  });

  factory OrderStatusHistoryEntry.fromMap(Map<String, dynamic> data) => OrderStatusHistoryEntry(
        fromStatus: data["fromStatus"] ?? "",
        toStatus: data["toStatus"] ?? "",
        changedByName: data["changedByName"],
        note: data["note"] ?? "",
        changedAt: toDateTime(data["changedAt"]),
      );
}

class Order {
  /// Same as [quotationId] — orders/{quotationId} allows one order per quotation.
  final String id;
  final String quotationId;
  final String requestId;
  final String customerId;
  final String customerName;
  final String supplierId;
  final String supplierName;
  final OrderStatus status;
  final FulfilmentMethod fulfilmentMethod;
  final String deliveryAddress;
  final List<OrderItem> items;
  final List<OrderStatusHistoryEntry> statusHistory;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.quotationId,
    required this.requestId,
    required this.customerId,
    required this.customerName,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.fulfilmentMethod,
    this.deliveryAddress = "",
    this.items = const [],
    this.statusHistory = const [],
    required this.createdAt,
  });

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Short display reference, e.g. "Order #K3F9QZ".
  String get reference => shortRef(id);

  factory Order.fromMap(String id, Map<String, dynamic> data) => Order(
        id: id,
        quotationId: data["quotationId"] ?? id,
        requestId: data["requestId"] ?? "",
        customerId: data["customerId"] ?? "",
        customerName: data["customerName"] ?? "",
        supplierId: data["supplierId"] ?? "",
        supplierName: data["supplierName"] ?? "",
        status: orderStatusFromString(data["status"] ?? "ORDER_PLACED"),
        fulfilmentMethod: (data["fulfilmentMethod"] ?? "DELIVERY") == "COLLECTION" ? FulfilmentMethod.collection : FulfilmentMethod.delivery,
        deliveryAddress: data["deliveryAddress"] ?? "",
        items: (data["items"] as List? ?? []).map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e))).toList(),
        // Stored oldest-first (appended on each change); shown newest-first like the old API.
        statusHistory: (data["statusHistory"] as List? ?? [])
            .map((e) => OrderStatusHistoryEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList()
            .reversed
            .toList(),
        createdAt: toDateTime(data["createdAt"]),
      );
}
