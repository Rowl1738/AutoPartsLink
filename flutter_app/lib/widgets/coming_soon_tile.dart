import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A feature tile for dashboard areas not built yet.
/// Used by the role home screens until each phase implements the real thing.
class ComingSoonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const ComingSoonTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
                child: const Text("Soon", style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
