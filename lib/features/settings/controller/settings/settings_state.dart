import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';

part 'settings_state.freezed.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required SettingsModel settings,
    required bool isLoading,
    String? errorMessage,
  }) = _SettingsState;

  factory SettingsState.initial() => const SettingsState(
        settings: SettingsModel(
          primaryCurrency: 'INR',
          defaultWallet: 'SBI (Debit Card)',
          isBiometricEnabled: true,
          supportEmail: 'support@zenio.app',
          appVersion: '',
        ),
        isLoading: false,
      );
}
