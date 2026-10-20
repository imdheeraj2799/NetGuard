import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_info_entity.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.app,
    required this.onInternetAccessChanged,
    super.key,
  });

  final AppInfoEntity app;
  final ValueChanged<bool> onInternetAccessChanged;

  @override
  Widget build(BuildContext context) {
    final isAllowed = app.isInternetAllowed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAllowed
              ? AppColors.cardBorderSubtle
              : const Color(0xFF452222),
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
                Text(
                  app.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAllowed
                            ? AppColors.activeGreen
                            : const Color(0xFFF87171),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAllowed ? 'Internet Allowed' : 'Internet Blocked',
                      style: TextStyle(
                        color: isAllowed
                            ? AppColors.activeGreen
                            : const Color(0xFFF87171),
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
            child: Switch.adaptive(
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
