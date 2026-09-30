import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/vault/presentation/vault/vault_mobile.dart';
import 'package:zenio/shared/services/biometric_service.dart';
import 'package:zenio/shared/widgets/device_lock_dialog.dart';

/// The single way into the Vault.
///
/// When Vault Lock is on, the user must pass device authentication first:
/// fingerprint, face, or the device PIN/pattern/passcode.
Future<void> openVault(BuildContext context, WidgetRef ref) async {
  final lockEnabled =
      await ref.read(settingsNotifierProvider.notifier).isVaultLockEnabled();

  if (lockEnabled) {
    final auth = ref.read(biometricServiceProvider);
    if (!await auth.isDeviceSupported()) {
      if (!context.mounted) return;
      await DeviceLockDialog.show(
        context,
        message: 'Vault Lock is on, but this device has no screen lock, so '
            "Zenio can't check it's you. Set up a screen lock in your device "
            'settings, or turn off Vault Lock in Zenio Settings.',
      );
      return;
    }
    final unlocked = await auth.authenticate(
      localizedReason: 'Unlock your Vault',
    );
    if (!unlocked) return;
  }

  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const VaultScreenMobile()),
  );
}
