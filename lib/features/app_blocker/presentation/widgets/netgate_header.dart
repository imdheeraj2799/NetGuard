import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class NetgateHeader extends StatelessWidget {
  const NetgateHeader({
    super.key,
    required this.category,
    required this.title,
    this.trailingAction,
    this.activeDashIndex = 0,
    this.onBack,
  });

  final String category;
  final String title;
  final Widget? trailingAction;
  final int activeDashIndex;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (onBack != null) ...[
                      InkWell(
                        onTap: onBack,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        category.toUpperCase(),
                        style: AppTextStyles.categoryTag,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailingAction,
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: AppTextStyles.screenTitle),
          const SizedBox(height: 10),
          _buildDashes(),
        ],
      ),
    );
  }

  Widget _buildDashes() {
    return Row(
      children: List.generate(6, (index) {
        final isActive = index == activeDashIndex;
        return Expanded(
          child: Container(
            height: 2,
            margin: EdgeInsets.only(right: index == 5 ? 0 : 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}
