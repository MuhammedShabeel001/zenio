import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key/value storage for sensitive data (iOS Keychain, Android
/// Keystore-backed storage).
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// Deletes everything, even when the stored data can no longer be
  /// decrypted (for example after the device's key store was reset).
  Future<void> deleteAllForcibly();
}

final secureKeyValueStoreProvider = Provider<SecureKeyValueStore>((ref) {
  return FlutterSecureKeyValueStore();
});

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            // The default wipes *all* stored data when a key cannot be
            // decrypted. Fail loudly instead so nothing is silently lost.
            resetOnError: false,
            migrateWithBackup: true,
          ),
          // Restorable through encrypted backups and device transfer, but
          // never synced to other devices through iCloud Keychain.
          iOptions:
              IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAllForcibly() {
    // resetOnError lets the plugin discard data it cannot decrypt, which is
    // exactly what a wipe needs.
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ).deleteAll();
  }
}
