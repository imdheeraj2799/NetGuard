import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class StatMetricCard extends StatelessWidget {
  const StatMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.trendText,
    required this.isIncrease,
  });

  final String label;
  final String value;
  final String trendText;
  final bool isIncrease;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTextStyles.metricLabel),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.metricValue),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isIncrease ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  trendText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
