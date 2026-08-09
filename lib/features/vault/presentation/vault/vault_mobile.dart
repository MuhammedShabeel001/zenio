import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/vault/controller/vault/vault_state.dart';
import 'package:zenio/features/vault/presentation/widgets/vault_card_item.dart';
import 'package:zenio/features/vault/presentation/widgets/vault_note_item.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';

class VaultScreenMobile extends ConsumerStatefulWidget {
  const VaultScreenMobile({super.key});

  @override
  ConsumerState<VaultScreenMobile> createState() => _VaultScreenMobileState();
}

class _VaultScreenMobileState extends ConsumerState<VaultScreenMobile> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultNotifierProvider);
    final notifier = ref.read(vaultNotifierProvider.notifier);

    final isCardsMode = state.mode == VaultMode.cards;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dark Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                      AddTransactionBottomSheet.show(context);
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
                  color: Color(0xFFF7F7F7),
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
                      if (isCardsMode) ...[
                        if (state.cards.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No cards found in vault',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          )
                        else
                          ...state.cards
                              .map((card) => VaultCardItem(card: card)),
                      ] else ...[
                        if (state.notes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No notes found in vault',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          )
                        else
                          ...state.notes
                              .map((note) => VaultNoteItem(note: note)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: VaultMode.cards,
          child: Text(
            'Cards',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
        ),
        const PopupMenuItem(
          value: VaultMode.notes,
          child: Text(
            'Notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF19191B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF2C2C2E),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD1D1D6),
              ),
            ),
            const SizedBox(width: 8),
            Assets.icons.dropDown.svg(
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(
                Color(0xFF8E8E93),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
