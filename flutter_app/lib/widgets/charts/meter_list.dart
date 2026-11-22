import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/platform_stats.dart';

/// Rows of name, figure and a horizontal bar, all bars sharing one scale and
/// one hue. Suits part-to-whole splits (statuses) and rankings (top suppliers).
class MeterList extends StatelessWidget {
  final List<LabeledValue> items;
  final String Function(double value) format;
  final Color color;

  /// When set, each figure also shows its share of this total, e.g. "4 · 20%".
  final double? shareOf;

  const MeterList({
    super.key,
    required this.items,
    required this.format,
    this.color = AppColors.primary,
    this.shareOf,
  });

  @override
  Widget build(BuildContext context) {
    final max = items.fold<double>(0, (m, e) => math.max(m, e.value));
    return Column(
      children: [
        for (final item in items) _row(item, max),
      ],
    );
  }

  Widget _row(LabeledValue item, double max) {
    final total = shareOf;
    final share = total != null && total > 0 ? " · ${(item.value / total * 100).round()}%" : "";
    final figure = "${format(item.value)}$share";
    final fraction = max <= 0 ? 0.0 : item.value / max;

    return Semantics(
      label: "${item.label}: $figure",
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 8),
                Text(figure, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                color: AppColors.background,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  // A non-zero value always shows a sliver, so 1 never reads as 0.
                  widthFactor: item.value > 0 ? math.max(fraction, 0.015) : 0,
                  child: Container(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
