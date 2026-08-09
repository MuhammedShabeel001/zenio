import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/vault/controller/vault/vault_state.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_repository.dart';

part 'vault_notifier.g.dart';

@Riverpod(keepAlive: true)
class VaultNotifier extends _$VaultNotifier {
  @override
  VaultState build() {
    _loadData();
    return VaultState.initial();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(vaultRepositoryRepoProvider);
      final cardsList = await repo.getCards();
      final notesList = await repo.getNotes();
      state = state.copyWith(
        cards: cardsList,
        notes: notesList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setMode(VaultMode mode) {
    state = state.copyWith(mode: mode);
  }
}
