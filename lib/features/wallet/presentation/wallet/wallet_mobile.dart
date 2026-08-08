import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/custom_navigation_bar.dart';

class WalletScreenMobile extends ConsumerStatefulWidget {
  const WalletScreenMobile({
    this.onTabSelected,
    super.key,
  });

  final ValueChanged<int>? onTabSelected;

  @override
  ConsumerState<WalletScreenMobile> createState() => _WalletScreenMobileState();
}

class _WalletScreenMobileState extends ConsumerState<WalletScreenMobile> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatWholePart(double amount) {
    final whole = amount.toInt();
    final formatter = NumberFormat('#,##0');
    return formatter.format(whole);
  }

  String _formatDecimalPart(double amount) {
    final decimal = ((amount - amount.toInt()).abs() * 100).round();
    return '.${decimal.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletNotifierProvider);
    final notifier = ref.read(walletNotifierProvider.notifier);

    final cardBalance = state.cardBalance;
    final cards = state.cards;
    final activeIndex = state.activeCardIndex;
    final isFrozen = state.isFrozen;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: '₹ ',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: _formatWholePart(cardBalance),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: _formatDecimalPart(cardBalance),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7A7A80),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Card balance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),

                  // + Add Pill Button
                  GestureDetector(
                    onTap: () {
                      notifier.topUpBalance(500);
                    },
                    behavior: HitTestBehavior.opaque,
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
                              fontWeight: FontWeight.bold,
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

            // Light Curved Content Sheet
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
                  child: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 110),
                        children: [
                          // Card Carousel PageView
                          SizedBox(
                            height: 216,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: cards.length,
                              onPageChanged: notifier.onCardPageChanged,
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                return WalletCardWidget(
                                  card: card,
                                  isFrozen: isFrozen && index == activeIndex,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Page Indicator Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(cards.length, (index) {
                              final isSelected = index == activeIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFE0E0E0),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 32),

                          // Quick Action Buttons (Top up, Freeze, Details, Settings)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _buildActionButton(
                                  label: 'Top up',
                                  backgroundColor: const Color(0xFF10B981),
                                  iconWidget: Assets.icons.add.svg(
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () {
                                    notifier.topUpBalance(1000);
                                  },
                                ),
                                _buildActionButton(
                                  label: 'Freeze',
                                  backgroundColor: const Color(0xFFEAEAEA),
                                  iconWidget: Assets.icons.freeze.svg(
                                    width: 24,
                                    height: 24,
                                  ),
                                  onTap: notifier.toggleFreezeCard,
                                ),
                                _buildActionButton(
                                  label: 'Details',
                                  backgroundColor: const Color(0xFFEAEAEA),
                                  iconWidget: Assets.icons.card.svg(
                                    width: 24,
                                    height: 24,
                                  ),
                                  onTap: () {},
                                ),
                                _buildActionButton(
                                  label: 'Settings',
                                  backgroundColor: const Color(0xFFEAEAEA),
                                  iconWidget: Assets.icons.settings.svg(
                                    width: 24,
                                    height: 24,
                                  ),
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Floating Navigation Bar (Selected Index = 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CustomNavigationBar(
                          selectedIndex: 1,
                          onTabSelected: (index) {
                            widget.onTabSelected?.call(index);
                          },
                          onAddTap: () {},
                        ),
                      ),
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

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Widget iconWidget,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 54,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(27),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F1F1F),
            ),
          ),
        ],
      ),
    );
  }
}
