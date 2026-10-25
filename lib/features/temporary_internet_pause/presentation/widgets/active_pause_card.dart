import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/temporary_pause_entity.dart';
import 'pause_countdown_widget.dart';

class ActivePauseCard extends StatelessWidget {
  const ActivePauseCard({
    super.key,
    required this.pause,
    required this.onCancel,
    this.iconBytes,
  });

  final TemporaryPauseEntity pause;
  final VoidCallback onCancel;
  final List<int>? iconBytes;

  void _confirmCancel(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFF87171), size: 22),
            SizedBox(width: 8),
            Text(
              'Cancel Pause?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel the temporary internet pause for "${pause.appName}"? Internet access will be restored if no other schedule or rule blocks it.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Keep Paused',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onCancel();
            },
            child: const Text('Cancel Pause'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = pause.remainingTime();
    final progress = pause.progressFraction();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.iconBoxBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.pause_circle_filled_rounded,
                    color: Color(0xFFFBBF24),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pause.appName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pause.packageName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF382A0D),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD97706)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pause_rounded,
                      size: 11,
                      color: Color(0xFFFBBF24),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'PAUSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFBBF24),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PauseCountdownWidget(remaining: remaining, progress: progress),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded, size: 14),
                label: const Text('Cancel Pause'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF87171),
                  side: const BorderSide(color: Color(0xFF7F1D1D)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _confirmCancel(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
