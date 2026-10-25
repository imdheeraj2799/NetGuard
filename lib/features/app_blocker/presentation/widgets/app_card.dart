import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_info_entity.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.app,
    required this.onInternetAccessChanged,
    this.onRestrictedTap,
    this.isTemporarilyPaused = false,
    this.pauseRemainingText,
    super.key,
  });

  final AppInfoEntity app;
  final ValueChanged<bool> onInternetAccessChanged;
  final VoidCallback? onRestrictedTap;
  final bool isTemporarilyPaused;
  final String? pauseRemainingText;

  @override
  Widget build(BuildContext context) {
    final isAllowed = app.isInternetAllowed && !isTemporarilyPaused;
    final isScheduled = app.isSchedulePart == true && app.whichSchedule != null;
    final isRestricted = isScheduled || isTemporarilyPaused;

    final cardContent = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTemporarilyPaused
              ? const Color(0xFF5B4310)
              : (isScheduled
                  ? const Color(0xFF1E3A5F)
                  : (isAllowed
                      ? AppColors.cardBorderSubtle
                      : const Color(0xFF452222))),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // App Icon
          _buildAppIcon(),
          const SizedBox(width: 14),

          // App Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        app.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isTemporarilyPaused) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF382A0D),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFD97706),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hourglass_top_rounded,
                              size: 10,
                              color: Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              pauseRemainingText ?? 'Paused',
                              style: const TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ] else if (isScheduled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF0284C7),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 10,
                              color: Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              app.whichSchedule ?? 'Scheduled',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTemporarilyPaused
                            ? const Color(0xFFFBBF24)
                            : (isAllowed
                                ? AppColors.activeGreen
                                : const Color(0xFFF87171)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTemporarilyPaused
                          ? 'Temporarily Paused'
                          : (isAllowed ? 'Internet Allowed' : 'Internet Blocked'),
                      style: TextStyle(
                        color: isTemporarilyPaused
                            ? const Color(0xFFFBBF24)
                            : (isAllowed
                                ? AppColors.activeGreen
                                : const Color(0xFFF87171)),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Internet Access Toggle
          Semantics(
            label: 'Internet access for ${app.appName}',
            toggled: isAllowed,
            child: isRestricted
                ? GestureDetector(
                    key: Key('app_card_toggle_${app.packageName}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onRestrictedTap,
                    child: IgnorePointer(
                      child: Switch.adaptive(
                        value: isAllowed,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.activeGreen,
                        inactiveThumbColor: AppColors.textSecondary,
                        inactiveTrackColor: AppColors.switchTrackInactive,
                        onChanged: null,
                      ),
                    ),
                  )
                : Switch.adaptive(
                    key: Key('app_card_toggle_${app.packageName}'),
                    value: isAllowed,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.activeGreen,
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.switchTrackInactive,
                    onChanged: onInternetAccessChanged,
                  ),
          ),
        ],
      ),
    );

    if (isRestricted && onRestrictedTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRestrictedTap,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildAppIcon() {
    final iconBytes = app.iconBytes;
    if (iconBytes != null && iconBytes.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          iconBytes,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.iconBoxBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.android_rounded,
        color: AppColors.accentBlue,
        size: 26,
      ),
    );
  }
}
