import 'package:flutter/foundation.dart';
import '../core/utils/app_error.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final _repository = OrderRepository();

  List<Order> _orders = [];
  bool _loading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadOrders() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repository.listOrders();
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't load orders.");
    }
    _loading = false;
    notifyListeners();
  }

  Future<Order?> getOrder(String id) async {
    try {
      return await _repository.getOrder(id);
    } catch (_) {
      return null;
    }
  }

  Future<Order?> acceptQuotation({required String quotationId, required String fulfilmentMethod, String deliveryAddress = ""}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final order = await _repository.acceptQuotation(
        quotationId: quotationId, fulfilmentMethod: fulfilmentMethod, deliveryAddress: deliveryAddress,
      );
      _orders = [order, ..._orders];
      _loading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't place the order.");
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Order?> updateStatus(String orderId, {required String status, String note = ""}) async {
    try {
      final updated = await _repository.updateStatus(orderId, status: status, note: note);
      _orders = _orders.map((o) => o.id == updated.id ? updated : o).toList();
      notifyListeners();
      return updated;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't update the order status.");
      notifyListeners();
      return null;
    }
  }

  Future<bool> rateOrder({required String orderId, required int score, String? reviewTitle, String? reviewBody}) async {
    try {
      await _repository.rateOrder(orderId: orderId, score: score, reviewTitle: reviewTitle, reviewBody: reviewBody);
      return true;
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't submit your rating.");
      notifyListeners();
      return false;
    }
  }
}
