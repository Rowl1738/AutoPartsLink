import '../core/utils/firestore_parsing.dart';

class AppNotification {
  final String id;
  final String event;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({required this.id, required this.event, required this.message, required this.isRead, required this.createdAt});

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) => AppNotification(
        id: id,
        event: data["event"] ?? "",
        message: data["message"] ?? "",
        isRead: data["isRead"] ?? false,
        createdAt: toDateTime(data["createdAt"]),
      );
}
