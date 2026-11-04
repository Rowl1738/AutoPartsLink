import '../models/quotation.dart';
import '../services/quotation_service.dart';

class QuotationRepository {
  final _service = QuotationService();

  Future<List<Quotation>> listQuotations() => _service.listQuotations();
  Future<Quotation> getQuotation(String id) => _service.getQuotation(id);

  Future<Quotation> createQuotation({
    required String requestId,
    int? expectedFulfilmentDays,
    String notes = "",
    DateTime? validUntil,
    required List<QuotationItem> items,
  }) =>
      _service.createQuotation(
        requestId: requestId, expectedFulfilmentDays: expectedFulfilmentDays,
        notes: notes, validUntil: validUntil, items: items,
      );

  Future<Quotation> updateQuotation(String id, {
    required String requestId,
    int? expectedFulfilmentDays,
    String notes = "",
    DateTime? validUntil,
    required List<QuotationItem> items,
  }) =>
      _service.updateQuotation(
        id, requestId: requestId, expectedFulfilmentDays: expectedFulfilmentDays,
        notes: notes, validUntil: validUntil, items: items,
      );
}
