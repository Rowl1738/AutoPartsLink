import '../models/procurement_request.dart';
import '../services/procurement_service.dart';

class ProcurementRepository {
  final _service = ProcurementService();

  Future<List<ProcurementRequest>> listRequests() => _service.listRequests();
  Future<ProcurementRequest> getRequest(String id) => _service.getRequest(id);
  Future<void> deleteRequest(String id) => _service.deleteRequest(id);

  Future<ProcurementRequest> createRequest({
    required String vehicleMake,
    required String vehicleModel,
    required int vehicleYear,
    required String description,
    required String urgency,
    required String preferredLocation,
    required List<ProcurementRequestItem> items,
  }) =>
      _service.createRequest(
        vehicleMake: vehicleMake, vehicleModel: vehicleModel, vehicleYear: vehicleYear,
        description: description, urgency: urgency, preferredLocation: preferredLocation, items: items,
      );
}
