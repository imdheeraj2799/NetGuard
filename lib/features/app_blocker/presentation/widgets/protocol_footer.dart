import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProtocolFooter extends StatelessWidget {
  const ProtocolFooter({
    super.key,
    this.text = 'SASHIKO PROTOCOL ACTIVE',
    this.icon = Icons.close,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.protocolText),
        ],
      ),
    );
  }
}
