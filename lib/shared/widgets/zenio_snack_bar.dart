import 'package:flutter/material.dart';

enum ZenioSnackBarType { info, success, error, warning }

class ZenioSnackBar {
  ZenioSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    ZenioSnackBarType type = ZenioSnackBarType.info,
    Duration duration = const Duration(milliseconds: 2500),
    double bottomMargin = 92,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    final (badgeBg, iconColor, iconData) = switch (type) {
      ZenioSnackBarType.success => (
          const Color(0xFFE8F8F0),
          const Color(0xFF10B981),
          Icons.check_circle_rounded,
        ),
      ZenioSnackBarType.error => (
          const Color(0xFFFFEAEA),
          const Color(0xFFDD3D34),
          Icons.error_rounded,
        ),
      ZenioSnackBarType.warning => (
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
          Icons.warning_rounded,
        ),
      ZenioSnackBarType.info => (
          const Color(0xFFF4ECFB),
          const Color(0xFF8C43E6),
          Icons.info_rounded,
        ),
    };

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                    height: 1.3,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
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
