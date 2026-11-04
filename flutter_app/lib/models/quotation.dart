import '../core/utils/firestore_parsing.dart';

enum QuotationStatus { submitted, accepted, rejected, withdrawn, expired }

QuotationStatus quotationStatusFromString(String s) {
  switch (s.toUpperCase()) {
    case "ACCEPTED":
      return QuotationStatus.accepted;
    case "REJECTED":
      return QuotationStatus.rejected;
    case "WITHDRAWN":
      return QuotationStatus.withdrawn;
    case "EXPIRED":
      return QuotationStatus.expired;
    default:
      return QuotationStatus.submitted;
  }
}

String quotationStatusLabel(QuotationStatus s) {
  switch (s) {
    case QuotationStatus.submitted:
      return "Submitted";
    case QuotationStatus.accepted:
      return "Accepted";
    case QuotationStatus.rejected:
      return "Rejected";
    case QuotationStatus.withdrawn:
      return "Withdrawn";
    case QuotationStatus.expired:
      return "Expired";
  }
}

class QuotationItem {
  final String requestItemId;
  final String partName;
  final double unitPrice;
  final int quantity;
  final bool isAvailable;
  final String notes;

  QuotationItem({
    required this.requestItemId,
    this.partName = "",
    required this.unitPrice,
    required this.quantity,
    this.isAvailable = true,
    this.notes = "",
  });

  double get subtotal => quantity * unitPrice;

  factory QuotationItem.fromMap(Map<String, dynamic> data) => QuotationItem(
        requestItemId: data["requestItemId"] ?? "",
        partName: data["partName"] ?? "",
        unitPrice: toDouble(data["unitPrice"]),
        quantity: toInt(data["quantity"]),
        isAvailable: data["isAvailable"] ?? true,
        notes: data["notes"] ?? "",
      );

  /// [partName] is passed in (looked up from the request) rather than trusted
  /// from the form, so a quotation line always matches the request it prices.
  Map<String, dynamic> toMap({required String partName}) => {
        "requestItemId": requestItemId,
        "partName": partName,
        "unitPrice": unitPrice,
        "quantity": quantity,
        "isAvailable": isAvailable,
        "notes": notes,
      };
}

class Quotation {
  /// "{requestId}_{supplierId}" — one quotation per supplier per request.
  final String id;
  final String requestId;
  final String customerId;
  final String supplierId;
  final String supplierName;
  final QuotationStatus status;
  final int? expectedFulfilmentDays;
  final String notes;
  final DateTime? validUntil;
  final List<QuotationItem> items;
  final DateTime createdAt;

  Quotation({
    required this.id,
    required this.requestId,
    required this.customerId,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    this.expectedFulfilmentDays,
    this.notes = "",
    this.validUntil,
    this.items = const [],
    required this.createdAt,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);

  static String idFor({required String requestId, required String supplierId}) => "${requestId}_$supplierId";

  factory Quotation.fromMap(String id, Map<String, dynamic> data) => Quotation(
        id: id,
        requestId: data["requestId"] ?? "",
        customerId: data["customerId"] ?? "",
        supplierId: data["supplierId"] ?? "",
        supplierName: data["supplierName"] ?? "",
        status: quotationStatusFromString(data["status"] ?? "SUBMITTED"),
        expectedFulfilmentDays: data["expectedFulfilmentDays"] == null ? null : toInt(data["expectedFulfilmentDays"]),
        notes: data["notes"] ?? "",
        validUntil: toDateTimeOrNull(data["validUntil"]),
        items: (data["items"] as List? ?? []).map((e) => QuotationItem.fromMap(Map<String, dynamic>.from(e))).toList(),
        createdAt: toDateTime(data["createdAt"]),
      );
}
