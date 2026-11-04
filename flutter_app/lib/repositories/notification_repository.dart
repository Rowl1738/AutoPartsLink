import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  final _service = NotificationService();

  Future<List<AppNotification>> listNotifications() => _service.listNotifications();
  Future<void> markRead(String id) => _service.markRead(id);
}
