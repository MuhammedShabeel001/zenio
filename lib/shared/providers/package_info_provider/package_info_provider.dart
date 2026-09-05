import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provides PackageInfo fetched from the native platform.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

/// Provides dynamic app version formatted with 'v ' prefix (e.g. 'v 2.0.0').
final appVersionProvider = Provider<String>((ref) {
  final infoAsync = ref.watch(packageInfoProvider);
  return infoAsync.when(
    data: (info) => 'v ${info.version}',
    loading: () => '',
    error: (_, __) => 'v 1.0.0',
  );
});
