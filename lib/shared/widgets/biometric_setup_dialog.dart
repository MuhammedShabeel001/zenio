import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class BiometricSetupDialog extends StatelessWidget {
  const BiometricSetupDialog({
    this.title = 'Set Up Biometrics',
    this.message =
        'Biometric authentication (Fingerprint or Face ID) is not configured on this device. Please set it up in your device settings to secure your Vault.',
    super.key,
  });

  final String title;
  final String message;

  static Future<void> show(
    BuildContext context, {
    String title = 'Set Up Biometrics',
    String message =
        'Biometric authentication (Fingerprint or Face ID) is not configured on this device. Please set it up in your device settings to secure your Vault.',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => BiometricSetupDialog(
        title: title,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Badge
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Assets.icons.biometric.svg(
                width: 32,
                height: 32,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF10B981),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 10),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
