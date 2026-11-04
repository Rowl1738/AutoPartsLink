import '../models/order.dart';
import '../models/rating.dart';
import '../services/order_service.dart';
import '../services/rating_service.dart';

class OrderRepository {
  final _orderService = OrderService();
  final _ratingService = RatingService();

  Future<List<Order>> listOrders() => _orderService.listOrders();
  Future<Order> getOrder(String id) => _orderService.getOrder(id);

  Future<Order> acceptQuotation({required String quotationId, required String fulfilmentMethod, String deliveryAddress = ""}) =>
      _orderService.acceptQuotation(quotationId: quotationId, fulfilmentMethod: fulfilmentMethod, deliveryAddress: deliveryAddress);

  Future<Order> updateStatus(String orderId, {required String status, String note = ""}) =>
      _orderService.updateStatus(orderId, status: status, note: note);

  Future<Rating> rateOrder({required String orderId, required int score, String? reviewTitle, String? reviewBody}) =>
      _ratingService.rateOrder(orderId: orderId, score: score, reviewTitle: reviewTitle, reviewBody: reviewBody);
}
