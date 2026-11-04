import 'package:flutter/foundation.dart';
import '../core/utils/app_error.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final _authRepository = AuthRepository();

  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> tryAutoLogin() async {
    if (!await _authRepository.hasStoredSession()) return false;
    try {
      final user = await _authRepository.fetchProfile();
      if (!user.isActive) {
        await _authRepository.logout();
        return false;
      }
      _user = user;
      notifyListeners();
      return true;
    } catch (_) {
      await _authRepository.logout();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _startLoading();
    try {
      _user = await _authRepository.login(email, password);
      _finishLoading();
      return true;
    } catch (e) {
      _finishLoading(error: friendlyErrorMessage(e, fallback: "Login failed. Check your email and password."));
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required UserRole role,
    String phone = "",
    String address = "",
    String companyName = "",
    String businessName = "",
  }) async {
    _startLoading();
    try {
      _user = await _authRepository.register(
        username: username, email: email, password: password, role: role,
        phone: phone, address: address, companyName: companyName, businessName: businessName,
      );
      _finishLoading();
      return true;
    } catch (e, stack) {
      debugPrint("Registration failed: $e\n$stack");
      _finishLoading(
        error: friendlyErrorMessage(e, fallback: "Registration failed. Try a different email."),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }

  void _startLoading() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _finishLoading({String? error}) {
    _loading = false;
    _error = error;
    notifyListeners();
  }
}
