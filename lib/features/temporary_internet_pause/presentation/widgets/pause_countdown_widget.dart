import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PauseCountdownWidget extends StatelessWidget {
  const PauseCountdownWidget({
    super.key,
    required this.remaining,
    required this.progress,
  });

  final Duration remaining;
  final double progress;

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    final sMinutes = minutes.toString().padLeft(2, '0');
    final sSeconds = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$sMinutes:$sSeconds';
    }
    return '$sMinutes:$sSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatDuration(remaining);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: Color(0xFFFBBF24),
                ),
                const SizedBox(width: 4),
                Text(
                  formatted,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: Color(0xFFFBBF24),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              '${(progress * 100).toInt()}% elapsed',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.iconBoxBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
          ),
        ),
      ],
    );
  }
}
