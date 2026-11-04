import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'logout_button.dart';
import 'notification_bell.dart';

/// Shared gradient header for the three role dashboards: avatar, welcome
/// text, role subtitle, and the logout action — one look across all roles.
class DashboardHeader extends StatelessWidget {
  final String greetingName;
  final String subtitle;
  final IconData icon;

  const DashboardHeader({super.key, required this.greetingName, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 26),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, $greetingName",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            const NotificationBell(color: Colors.white),
            const LogoutButton(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
