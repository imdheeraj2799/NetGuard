import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppNotificationType {
  success,
  error,
  warning,
  info,
}

/// Unified, themed notification component for NetGuard.
/// Ensures consistent dark-theme aesthetics, high-contrast readable typography,
/// distinct icons, and custom borders per notification type.
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      type: AppNotificationType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      message: message,
      type: AppNotificationType.error,
      action: action,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      type: AppNotificationType.warning,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      message: message,
      type: AppNotificationType.info,
      duration: duration,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required AppNotificationType type,
    SnackBarAction? action,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    final Color backgroundColor;
    final Color borderColor;
    final Color iconColor;
    final IconData iconData;

    switch (type) {
      case AppNotificationType.success:
        backgroundColor = const Color(0xFF132A1C);
        borderColor = const Color(0xFF16A34A);
        iconColor = AppColors.activeGreen;
        iconData = Icons.check_circle_rounded;
      case AppNotificationType.error:
        backgroundColor = const Color(0xFF2C1315);
        borderColor = const Color(0xFFDC2626);
        iconColor = const Color(0xFFF87171);
        iconData = Icons.error_outline_rounded;
      case AppNotificationType.warning:
        backgroundColor = const Color(0xFF2E220D);
        borderColor = const Color(0xFFD97706);
        iconColor = const Color(0xFFFBBF24);
        iconData = Icons.warning_amber_rounded;
      case AppNotificationType.info:
        backgroundColor = const Color(0xFF16253B);
        borderColor = const Color(0xFF0284C7);
        iconColor = AppColors.accentBlue;
        iconData = Icons.info_outline_rounded;
    }

    messenger.showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                iconData,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    action.onPressed();
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: action.textColor ?? AppColors.accentBlue,
                  ),
                  child: Text(
                    action.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
