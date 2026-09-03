import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RuleFilterCard extends StatelessWidget {
  const RuleFilterCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onChanged,
    this.iconBytes,
    this.fallbackIcon = Icons.grid_view_rounded,
    this.isDomain = false,
  });

  final String title;
  final String subtitle;
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final Uint8List? iconBytes;
  final IconData fallbackIcon;
  final bool isDomain;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _buildIconContainer(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.itemSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildSwitch(),
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.iconBoxBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: iconBytes != null
            ? Image.memory(
                iconBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallbackIcon(),
              )
            : _buildFallbackIcon(),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        isDomain ? Icons.language : fallbackIcon,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildSwitch() {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: isActive,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF6B7E98),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFF2C394F),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
