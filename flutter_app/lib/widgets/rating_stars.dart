import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Read-only star display for an average rating (e.g. "4.3").
class RatingStars extends StatelessWidget {
  final double? rating;
  final double size;
  const RatingStars({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return Text("No ratings yet", style: TextStyle(fontSize: size * 0.7, color: AppColors.textSecondary));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size, color: const Color(0xFFF5A623)),
        const SizedBox(width: 3),
        Text(rating!.toStringAsFixed(1), style: TextStyle(fontSize: size * 0.8, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Tappable 1-5 star input for submitting a rating.
class RatingStarsInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const RatingStarsInput({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          iconSize: 36,
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? const Color(0xFFF5A623) : AppColors.border,
          ),
        );
      }),
    );
  }
}
