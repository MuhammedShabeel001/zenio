import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Checks if hardware is supported
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Checks if biometric sensor is present and usable
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves list of enrolled biometric types (e.g., fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Checks if the device has enrolled biometrics configured
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;
      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;
      final available = await getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Performs biometric authentication with fallback handling
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
