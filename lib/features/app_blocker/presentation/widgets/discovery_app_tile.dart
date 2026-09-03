import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DiscoveryAppTile extends StatelessWidget {
  const DiscoveryAppTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onChanged,
    this.iconBytes,
    this.fallbackIcon = Icons.grid_view_rounded,
    this.isDomain = false,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final Uint8List? iconBytes;
  final IconData fallbackIcon;
  final bool isDomain;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.itemSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildCheckbox(),
            ],
          ),
        ),
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

  Widget _buildCheckbox() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isSelected ? Colors.white : const Color(0xFF42536F),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: AppColors.background)
          : null,
    );
  }
}
