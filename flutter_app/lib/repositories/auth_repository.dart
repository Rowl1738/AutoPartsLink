import '../core/services/session.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Sits between AuthProvider and AuthService: owns the "what does a
/// successful login actually involve" business logic (remember the signed-in
/// profile for the data services) so the provider only deals in app state,
/// not Firebase plumbing. Firebase Auth persists the session on-device itself.
class AuthRepository {
  final _authService = AuthService();

  Future<AppUser> login(String email, String password) async =>
      Session.currentUser = await _authService.login(email, password);

  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required UserRole role,
    String phone = "",
    String address = "",
    String companyName = "",
    String businessName = "",
  }) async =>
      Session.currentUser = await _authService.register(
        username: username, email: email, password: password, role: role,
        phone: phone, address: address, companyName: companyName, businessName: businessName,
      );

  Future<AppUser> fetchProfile() async => Session.currentUser = await _authService.fetchProfile();

  Future<AppUser> updateProfile({String? phone, String? address, CustomerProfile? customerProfile}) async =>
      Session.currentUser = await _authService.updateProfile(phone: phone, address: address, customerProfile: customerProfile);

  Future<bool> hasStoredSession() async => (await _authService.restoredSessionUid()) != null;

  Future<void> logout() async {
    Session.currentUser = null;
    await _authService.logout();
  }
}
