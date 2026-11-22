import 'package:flutter/foundation.dart';
import '../core/utils/app_error.dart';
import '../models/order.dart';
import '../models/platform_stats.dart';
import '../models/procurement_request.dart';
import '../models/quotation.dart';
import '../models/user.dart';
import '../repositories/admin_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/procurement_repository.dart';
import '../repositories/quotation_repository.dart';

/// Loads every collection the admin can see and reduces it to [PlatformStats].
class ReportsProvider extends ChangeNotifier {
  final _admin = AdminRepository();
  final _requests = ProcurementRepository();
  final _quotations = QuotationRepository();
  final _orders = OrderRepository();

  PlatformStats? _stats;
  bool _loading = false;
  String? _error;

  PlatformStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Fetched in parallel; Future.wait surfaces the first failure as-is.
      final results = await Future.wait<Object>([
        _admin.listUsers(),
        _requests.listRequests(),
        _quotations.listQuotations(),
        _orders.listOrders(),
      ]);
      _stats = PlatformStats.compute(
        users: results[0] as List<AppUser>,
        requests: results[1] as List<ProcurementRequest>,
        quotations: results[2] as List<Quotation>,
        orders: results[3] as List<Order>,
      );
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't load platform statistics.");
    }
    _loading = false;
    notifyListeners();
  }
}
