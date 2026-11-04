import '../models/rating.dart';
import '../models/supplier_listing.dart';
import '../services/supplier_service.dart';

class SupplierRepository {
  final _service = SupplierService();

  Future<List<SupplierListing>> listSuppliers({String? search}) => _service.listSuppliers(search: search);
  Future<SupplierListing> getSupplier(String id) => _service.getSupplier(id);
  Future<List<Rating>> getSupplierRatings(String id) => _service.getSupplierRatings(id);
  Future<void> updateMyProfile(Map<String, dynamic> data) => _service.updateMyProfile(data);
}
