import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../routing/route_names.dart';

class LogoutButton extends StatelessWidget {
  final Color? color;
  const LogoutButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.logout, color: color),
      tooltip: "Log out",
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Log out?"),
            content: const Text("You'll need to log in again to access your account."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Log out")),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.welcome, (route) => false);
        }
      },
    );
  }
}
