import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_controller.g.dart';

@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';

  @override
  Future<bool> build() async {
    return _checkIfCompleted();
  }

  Future<bool> _checkIfCompleted() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getBool(keyHasSeenOnboarding) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> completeOnboarding() async {
    state = const AsyncValue.data(true);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(keyHasSeenOnboarding, true);
    } catch (_) {}
  }

  Future<void> resetOnboarding() async {
    state = const AsyncValue.data(false);
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(keyHasSeenOnboarding);
    } catch (_) {}
  }
}
