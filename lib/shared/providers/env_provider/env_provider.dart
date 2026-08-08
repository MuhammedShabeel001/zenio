import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/env.dart';

final envProvider = Provider<IEnvironment>((ref) => const DevelopmentEnv());
