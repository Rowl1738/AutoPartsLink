import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

Color requestStatusColor(String status) {
  switch (status) {
    case "OPEN":
      return AppColors.primary;
    case "QUOTATIONS_RECEIVED":
      return AppColors.secondary;
    case "SUPPLIER_SELECTED":
    case "ORDER_CREATED":
      return AppColors.success;
    case "COMPLETED":
      return AppColors.success;
    case "CANCELLED":
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

Color quotationStatusColor(String status) {
  switch (status) {
    case "ACCEPTED":
      return AppColors.success;
    case "REJECTED":
    case "WITHDRAWN":
    case "EXPIRED":
      return AppColors.error;
    default:
      return AppColors.secondary;
  }
}

Color orderStatusColor(String status) {
  switch (status) {
    case "COMPLETED":
      return AppColors.success;
    case "CANCELLED":
      return AppColors.error;
    case "ORDER_PLACED":
      return AppColors.textSecondary;
    default:
      return AppColors.primary;
  }
}
