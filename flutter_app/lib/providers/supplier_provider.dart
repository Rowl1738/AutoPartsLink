import 'package:flutter/foundation.dart';
import '../core/utils/app_error.dart';
import '../models/supplier_listing.dart';
import '../repositories/supplier_repository.dart';

class SupplierProvider extends ChangeNotifier {
  final _repository = SupplierRepository();

  List<SupplierListing> _suppliers = [];
  bool _loading = false;
  String? _error;

  List<SupplierListing> get suppliers => _suppliers;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSuppliers({String? search}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _suppliers = await _repository.listSuppliers(search: search);
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't load suppliers.");
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> updateMyProfile(Map<String, dynamic> data) async {
    try {
      await _repository.updateMyProfile(data);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't update your business profile.");
      notifyListeners();
      return false;
    }
  }
}
