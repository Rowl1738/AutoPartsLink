import '../models/user.dart';
import '../services/admin_service.dart';

class AdminRepository {
  final _service = AdminService();

  Future<List<AppUser>> listUsers({String? role}) => _service.listUsers(role: role);
  Future<void> approveSupplier(String userId) => _service.approveSupplier(userId);
  Future<void> setActive(String userId, bool isActive) => _service.setActive(userId, isActive);
}
