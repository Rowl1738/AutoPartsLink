import 'package:flutter/foundation.dart';
import '../core/utils/app_error.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final _repository = NotificationRepository();

  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _repository.listNotifications();
    } catch (e) {
      _error = friendlyErrorMessage(e, fallback: "Couldn't load notifications.");
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    try {
      await _repository.markRead(id);
      final n = _notifications[index];
      _notifications[index] = AppNotification(id: n.id, event: n.event, message: n.message, isRead: true, createdAt: n.createdAt);
      notifyListeners();
    } catch (_) {
      // Silently ignore — read-state is a minor UX nicety, not worth surfacing an error for.
    }
  }
}
