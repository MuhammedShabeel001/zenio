import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/vault/controller/vault/vault_state.dart';
import 'package:zenio/features/vault/presentation/widgets/add_vault_item_bottom_sheet.dart';
import 'package:zenio/features/vault/presentation/widgets/edit_vault_item_dialog.dart';
import 'package:zenio/features/vault/presentation/widgets/vault_card_item.dart';
import 'package:zenio/features/vault/presentation/widgets/vault_note_item.dart';
import 'package:zenio/shared/services/secure_platform.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/list_state_message.dart';
import 'package:zenio/shared/widgets/screen_title_bar.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';


class VaultScreenMobile extends ConsumerStatefulWidget {
  const VaultScreenMobile({super.key});

  @override
  ConsumerState<VaultScreenMobile> createState() => _VaultScreenMobileState();
}

class _VaultScreenMobileState extends ConsumerState<VaultScreenMobile>
    with WidgetsBindingObserver {
  /// How long a revealed card number and CVV stay visible.
  static const Duration _revealDuration = Duration(seconds: 30);

  String? _openItemId;
  String? _revealedCardId;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SecurePlatform.holdSecureScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revealTimer?.cancel();
    SecurePlatform.releaseSecureScreen();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The app-wide PrivacyShield hides the Vault (and anything open over it)
    // whenever the app is not in front; Android also uses FLAG_SECURE.
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _hideRevealedCard();
      _lockIfEnabled();
    }
  }

  /// With Vault Lock on, leaving the app closes the Vault (and anything open
  /// on top of it) so that it must be unlocked again.
  void _lockIfEnabled() {
    if (!mounted) return;
    final lockEnabled =
        ref.read(settingsNotifierProvider.notifier).vaultLockRequired;
    final route = ModalRoute.of(context);
    if (!lockEnabled || route == null || !route.isActive) return;
    // Keep the shield up until the Vault has finished closing, so it does
    // not show while the closing animation plays on return.
    SecurePlatform.coverWhileClosing();
    Navigator.of(context)
      ..popUntil((r) => r == route)
      ..pop();
  }

  /// Vault items cannot be recovered once deleted, so ask first.
  Future<void> _confirmDelete({
    required String what,
    required Future<void> Function() onConfirmed,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete this $what?'),
        content: Text(
          'It will be removed from your Vault and cannot be recovered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: ZenioColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await onConfirmed();
    } catch (_) {
      if (!mounted) return;
      ZenioSnackBar.show(
        context,
        message: "Couldn't delete the $what. Please try again.",
        type: ZenioSnackBarType.error,
      );
    }
  }

  void _toggleRevealCard(String cardId) {
    _revealTimer?.cancel();
    if (_revealedCardId == cardId) {
      setState(() => _revealedCardId = null);
      return;
    }
    setState(() => _revealedCardId = cardId);
    _revealTimer = Timer(_revealDuration, _hideRevealedCard);
  }

  void _hideRevealedCard() {
    _revealTimer?.cancel();
    if (mounted && _revealedCardId != null) {
      setState(() => _revealedCardId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultNotifierProvider);
    final notifier = ref.read(vaultNotifierProvider.notifier);

    final isCardsMode = state.mode == VaultMode.cards;

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildContent(context, state, notifier, isCardsMode),
    );
  }

  Widget _buildContent(
    BuildContext context,
    VaultState state,
    VaultNotifier notifier,
    bool isCardsMode,
  ) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const ScreenTitleBar(title: 'Vault'),
          // Dark Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Filter Dropdown Pill (Cards v / Notes v)
                _buildFilterPickerPill(
                  currentMode: state.mode,
                  onModeSelected: notifier.setMode,
                ),

                // + Add Action Button Pill
                GestureDetector(
                  onTap: () {
                    AddVaultItemBottomSheet.show(context, state.mode);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19191B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF2C2C2E),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Light Curved Content Sheet (#F7F7F7)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: ZenioColors.sheet,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    if (state.isLoading)
                      const ListStateMessage.loading()
                    else if (state.errorMessage != null &&
                        state.cards.isEmpty &&
                        state.notes.isEmpty)
                      ListStateMessage.error(onRetry: notifier.loadData)
                    else if (isCardsMode) ...[
                      if (state.cards.isEmpty)
                        ListStateMessage(
                          title: 'No cards saved',
                          message: 'Keep card details here, protected by Vault Lock if you turn it on.',
                          icon: Icons.credit_card_outlined,
                          actionLabel: 'Add card',
                          onAction: () =>
                              AddVaultItemBottomSheet.show(context, state.mode),
                        )
                      else
                        ...state.cards.map(
                          (card) => VaultCardItem(
                            key: ValueKey(card.id),
                            card: card,
                            isRevealed: _revealedCardId == card.id,
                            onToggleReveal: () => _toggleRevealCard(card.id),
                            isOpen: _openItemId == card.id,
                            onOpen: () {
                              if (_openItemId != card.id) {
                                setState(() {
                                  _openItemId = card.id;
                                });
                              }
                            },
                            onClose: () {
                              if (_openItemId == card.id) {
                                setState(() {
                                  _openItemId = null;
                                });
                              }
                            },
                            onDelete: () => _confirmDelete(
                            what: 'card',
                            onConfirmed: () => notifier.deleteCard(card.id),
                          ),
                            onEdit: () {
                              EditVaultItemDialog.showCard(
                                context,
                                card: card,
                              );
                            },
                          ),
                        ),
                    ] else ...[
                      if (state.notes.isEmpty)
                        ListStateMessage(
                          title: 'No notes saved',
                          message: 'Keep private notes here, such as PINs or account details.',
                          icon: Icons.sticky_note_2_outlined,
                          actionLabel: 'Add note',
                          onAction: () =>
                              AddVaultItemBottomSheet.show(context, state.mode),
                        )
                      else
                        ...state.notes.map(
                          (note) => VaultNoteItem(
                            key: ValueKey(note.id),
                            note: note,
                            isOpen: _openItemId == note.id,
                            onOpen: () {
                              if (_openItemId != note.id) {
                                setState(() {
                                  _openItemId = note.id;
                                });
                              }
                            },
                            onClose: () {
                              if (_openItemId == note.id) {
                                setState(() {
                                  _openItemId = null;
                                });
                              }
                            },
                            onDelete: () => _confirmDelete(
                            what: 'note',
                            onConfirmed: () => notifier.deleteNote(note.id),
                          ),
                            onEdit: () {
                              EditVaultItemDialog.showNote(
                                context,
                                note: note,
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPickerPill({
    required VaultMode currentMode,
    required ValueChanged<VaultMode> onModeSelected,
  }) {
    final labelText = currentMode == VaultMode.cards ? 'Cards' : 'Notes';

    return PopupMenuButton<VaultMode>(
      onSelected: onModeSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: VaultMode.cards,
          child: Text('Cards', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: VaultMode.notes,
          child: Text('Notes', style: TextStyle(color: Colors.white)),
        ),
      ],
      offset: const Offset(0, 40),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ZenioColors.border,
              ),
            ),
            const SizedBox(width: 8),
            Assets.icons.dropDown.svg(
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
