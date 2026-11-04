import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../screens/common/notifications_screen.dart';

/// Self-contained: loads the notification list itself on first build, so it
/// can be dropped into any dashboard header and just work.
class NotificationBell extends StatefulWidget {
  final Color? color;
  const NotificationBell({super.key, this.color});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationProvider>().loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;
    return IconButton(
      tooltip: "Notifications",
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text("$unread"),
        child: Icon(Icons.notifications_outlined, color: widget.color),
      ),
    );
  }
}
