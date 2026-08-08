// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars

abstract class IEnvironment {
  const IEnvironment();
  String get SERVER_URL;
  String get ANON_KEY;
  Duration get CONNECT_TIMEOUT;
  Duration get RECEIVE_TIMEOUT;
}

class ProductionEnv extends IEnvironment {
  const ProductionEnv();
  @override
  String get SERVER_URL => '';
  @override
  String get ANON_KEY => '';
  @override
  Duration get CONNECT_TIMEOUT => const Duration(seconds: 5000);
  @override
  Duration get RECEIVE_TIMEOUT => const Duration(seconds: 3000);
}

class StagingEnv extends IEnvironment {
  const StagingEnv();
  @override
  String get SERVER_URL => '';
  @override
  String get ANON_KEY => '';
  @override
  Duration get CONNECT_TIMEOUT => const Duration(seconds: 5000);
  @override
  Duration get RECEIVE_TIMEOUT => const Duration(seconds: 3000);
}

class DevelopmentEnv extends IEnvironment {
  const DevelopmentEnv();
  @override
  String get SERVER_URL => '';
  @override
  String get ANON_KEY => '';
  @override
  Duration get CONNECT_TIMEOUT => const Duration(seconds: 5000);
  @override
  Duration get RECEIVE_TIMEOUT => const Duration(seconds: 3000);
}
