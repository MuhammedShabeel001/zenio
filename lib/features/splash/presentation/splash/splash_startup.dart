import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/onboarding/controller/onboarding_controller.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_repository.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';
import 'package:zenio/shared/utils/router.dart';

/// Returns the route the splash screen should open.
///
/// Waits for local storage to open first, so that no screen, and no notifier
/// that loads or saves data, starts before the stored data can be read.
/// Throws if local storage cannot be opened.
Future<String> resolveStartupRoute(WidgetRef ref) async {
  await ref.read(sqlitePrefsProvider.future);

  // Move any plain-text vault data into secure storage right away rather than
  // waiting for the Vault to be opened. It never throws and never blocks.
  try {
    unawaited(ref.read(vaultRepositoryRepoProvider).migrateToSecureStorage());
  } catch (_) {}

  // Loading subscriptions moves passed billing dates on and reschedules the
  // reminders, so they stay right even if the Subscriptions screen is never
  // opened.
  ref.read(subscriptionsNotifierProvider);

  var hasSeenOnboarding = false;
  try {
    final sp = await SharedPreferences.getInstance();
    hasSeenOnboarding =
        sp.getBool(OnboardingController.keyHasSeenOnboarding) ?? false;
  } catch (_) {}

  return hasSeenOnboarding ? AppRouter.home : AppRouter.onboarding;
}

/// Lets the next [resolveStartupRoute] call try to open local storage again.
void retryStartup(WidgetRef ref) => ref.invalidate(sqlitePrefsProvider);
