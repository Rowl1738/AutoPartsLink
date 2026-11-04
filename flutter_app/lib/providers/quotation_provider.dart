import 'package:flutter/foundation.dart';
import '../core/utils/app_error.dart';
import '../models/quotation.dart';
import '../repositories/quotation_repository.dart';

class QuotationProvider extends ChangeNotifier {
  final _repository = QuotationRepository();

  List<Quotation> _quotations = [];
  bool _loading = false;
  String? _error;

  List<Quotation> get quotations => _quotations;
  bool get loading => _loading;
  String? get error => _error;

  List<Quotation> forRequest(String requestId) => _quotations.where((q) => q.requestId == requestId).toList();

  Future<void> loadQuotations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _quotations = await _repository.listQuotations();
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't load quotations.");
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> submitQuotation({
    required String requestId,
    int? expectedFulfilmentDays,
    String notes = "",
    DateTime? validUntil,
    required List<QuotationItem> items,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _repository.createQuotation(
        requestId: requestId, expectedFulfilmentDays: expectedFulfilmentDays,
        notes: notes, validUntil: validUntil, items: items,
      );
      _quotations = [created, ..._quotations];
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't submit the quotation.");
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editQuotation(Quotation existing, {
    int? expectedFulfilmentDays,
    String notes = "",
    DateTime? validUntil,
    required List<QuotationItem> items,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _repository.updateQuotation(
        existing.id, requestId: existing.requestId, expectedFulfilmentDays: expectedFulfilmentDays,
        notes: notes, validUntil: validUntil, items: items,
      );
      _quotations = _quotations.map((q) => q.id == updated.id ? updated : q).toList();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't update the quotation.");
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
