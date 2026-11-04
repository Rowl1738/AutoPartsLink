import 'package:flutter/foundation.dart';
import '../core/utils/app_error.dart';
import '../models/user.dart';
import '../repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final _repository = AdminRepository();

  List<AppUser> _users = [];
  bool _loading = false;
  String? _error;

  List<AppUser> get users => _users;
  bool get loading => _loading;
  String? get error => _error;

  List<AppUser> get customers => _users.where((u) => u.role == UserRole.customer).toList();
  List<AppUser> get suppliers => _users.where((u) => u.role == UserRole.supplier).toList();

  Future<void> loadUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _repository.listUsers();
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't load users.");
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> approveSupplier(String userId) async {
    try {
      await _repository.approveSupplier(userId);
      _users = _users.map((u) => u.id == userId ? u.copyWith(isApproved: true) : u).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't approve this supplier.");
      notifyListeners();
      return false;
    }
  }

  Future<bool> setActive(String userId, bool isActive) async {
    try {
      await _repository.setActive(userId, isActive);
      _users = _users.map((u) => u.id == userId ? u.copyWith(isActive: isActive) : u).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't update this account.");
      notifyListeners();
      return false;
    }
  }
}
