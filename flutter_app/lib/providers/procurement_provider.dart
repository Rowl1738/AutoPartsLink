import 'package:flutter/foundation.dart';
import '../core/utils/app_error.dart';
import '../models/procurement_request.dart';
import '../repositories/procurement_repository.dart';

class ProcurementProvider extends ChangeNotifier {
  final _repository = ProcurementRepository();

  List<ProcurementRequest> _requests = [];
  bool _loading = false;
  String? _error;

  List<ProcurementRequest> get requests => _requests;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadRequests() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _requests = await _repository.listRequests();
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't load procurement requests.");
    }
    _loading = false;
    notifyListeners();
  }

  Future<ProcurementRequest?> getRequest(String id) async {
    try {
      return await _repository.getRequest(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> createRequest({
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String description,
    required String urgency,
    required String preferredLocation,
    required List<ProcurementRequestItem> items,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _repository.createRequest(
        vehicleMake: vehicleMake, vehicleModel: vehicleModel, vehicleYear: vehicleYear,
        description: description, urgency: urgency, preferredLocation: preferredLocation, items: items,
      );
      _requests = [created, ..._requests];
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't create the procurement request.");
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRequest(String id) async {
    try {
      await _repository.deleteRequest(id);
      _requests = _requests.where((r) => r.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't delete the request.");
      notifyListeners();
      return false;
    }
  }
}
