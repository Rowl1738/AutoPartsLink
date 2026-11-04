import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationProvider>().loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationProvider>().loadNotifications(),
        child: provider.loading && provider.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.notifications.isEmpty
                ? ListView(children: const [
                    Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 56, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text("No notifications yet", style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _NotificationTile(notification: provider.notifications[index]),
                  ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final meta = _eventMeta(notification.event);
    return ListTile(
      onTap: () => context.read<NotificationProvider>().markRead(notification.id),
      tileColor: notification.isRead ? null : AppColors.primary.withValues(alpha: 0.04),
      leading: CircleAvatar(
        backgroundColor: meta.$2.withValues(alpha: 0.12),
        child: Icon(meta.$1, color: meta.$2, size: 20),
      ),
      title: Text(notification.message, style: TextStyle(fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w700)),
      subtitle: Text(DateFormat.yMMMd().add_jm().format(notification.createdAt), style: const TextStyle(fontSize: 12)),
      trailing: notification.isRead ? null : const Icon(Icons.circle, size: 9, color: AppColors.primary),
    );
  }

  (IconData, Color) _eventMeta(String event) {
    switch (event) {
      case "NEW_PROCUREMENT_REQUEST":
        return (Icons.assignment_outlined, AppColors.primary);
      case "QUOTATION_RECEIVED":
        return (Icons.request_quote_outlined, AppColors.secondary);
      case "QUOTATION_ACCEPTED":
        return (Icons.check_circle_outline, AppColors.success);
      case "QUOTATION_REJECTED":
        return (Icons.cancel_outlined, AppColors.error);
      case "ORDER_PLACED":
        return (Icons.receipt_long_outlined, AppColors.primary);
      case "NEW_ORDER":
        return (Icons.local_shipping_outlined, AppColors.primary);
      case "ORDER_STATUS_CHANGED":
        return (Icons.sync_alt, AppColors.secondary);
      case "ORDER_COMPLETED":
        return (Icons.task_alt, AppColors.success);
      case "SUPPLIER_APPROVED":
        return (Icons.verified_outlined, AppColors.success);
      case "ADMIN_MESSAGE":
        return (Icons.campaign_outlined, AppColors.warning);
      default:
        return (Icons.notifications_none, AppColors.textSecondary);
    }
  }
}
