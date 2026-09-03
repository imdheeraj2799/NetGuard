import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({
    super.key,
    this.averageText = 'AVG 5.2H/DAY',
    this.dayValues = const [0.45, 0.65, 0.70, 0.50, 0.90, 0.60, 0.85],
    this.dayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  });

  final String averageText;
  final List<double> dayValues;
  final List<String> dayLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WEEKLY ACTIVITY', style: AppTextStyles.metricLabel),
              Text(
                averageText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(dayValues.length, (index) {
                return _buildBarColumn(
                  dayLabels[index],
                  dayValues[index],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarColumn(String label, double ratio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 14,
              height: 100 * ratio.clamp(0.05, 1.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
