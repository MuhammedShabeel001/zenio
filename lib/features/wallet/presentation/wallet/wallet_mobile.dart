import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_detail_widget.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';
import 'package:zenio/features/wallet/presentation/widgets/add_wallet_bottom_sheet.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_settings_bottom_sheet.dart';
import 'package:zenio/features/wallet/presentation/widgets/top_up_wallet_bottom_sheet.dart';
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
  PageController? _pageController;
  bool _isCardDetailExpanded = false;
  int _tappedCardIndex = 0;
  int _lastKnownPage = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  int _getActiveCardIndex(int length) {
    if (length == 0) return 0;
    if (length == 1 || _pageController == null || !_pageController!.hasClients) {
      return 0;
    }
    return (_pageController!.page?.round() ?? 0) % length;
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

    final cards = state.cards;
    final activeIndex = state.activeCardIndex;
    
    double displayBalance = 0.0;
    bool isActiveCardFrozen = false;
    if (cards.isNotEmpty) {
      final actualIndex = _getActiveCardIndex(cards.length);
      displayBalance = cards[actualIndex].balance;
      isActiveCardFrozen = cards[actualIndex].isFrozen;
    }

    // Dynamically initialize controller to start at a clean multiple of cards.length
    if (_pageController == null && cards.isNotEmpty) {
      final initialPage = _lastKnownPage > 0 ? _lastKnownPage : 1000 * cards.length;
      _pageController =
          PageController(initialPage: initialPage, viewportFraction: 0.84);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.onCardPageChanged(initialPage);
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Dark Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
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
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatWholePart(displayBalance),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatDecimalPart(displayBalance),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF808080),
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
                              color: Color(0xFF808080),
                            ),
                          ),
                        ],
                      ),

                      // + Add Pill Button
                      GestureDetector(
                        onTap: () {
                          AddWalletBottomSheet.show(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 17,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF313131),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 15,
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

                // Main Content Sheet (Morphing into Card Detail)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fullHeight = constraints.maxHeight;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: null,
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.fastOutSlowIn,
                            height: _isCardDetailExpanded ? 365 : fullHeight,
                            width: double.infinity,
                            margin: _isCardDetailExpanded
                                ? const EdgeInsets.only(top: 40, left: 24, right: 24)
                                : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: _isCardDetailExpanded ? Colors.white : const Color(0xFFF7F7F7),
                        borderRadius: _isCardDetailExpanded
                            ? BorderRadius.circular(30)
                            : const BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: _isCardDetailExpanded
                            ? const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: _isCardDetailExpanded
                            ? BorderRadius.circular(30)
                            : const BorderRadius.vertical(top: Radius.circular(30)),

                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.fastOutSlowIn,
                          opacity: _isCardDetailExpanded ? 0.0 : 1.0,
                          child: IgnorePointer(
                            ignoring: _isCardDetailExpanded,
                            child: OverflowBox(
                              maxWidth: constraints.maxWidth,
                              child: cards.isEmpty
                                  ? _buildEmptyWalletView(context)
                                  : ListView(
                                  key: const ValueKey('carousel'),
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                                  children: [
                                    // Card Carousel PageView
                                    SizedBox(
                                      height: 200,
                                      child: _pageController == null || cards.isEmpty
                                          ? const SizedBox.shrink()
                                          : cards.length == 1
                                              ? Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                                  child: _buildCardItem(
                                                    index: 0,
                                                    actualIndex: 0,
                                                    card: cards[0],
                                                    isFrozen: cards[0].isFrozen,
                                                    height: 200.0,
                                                    heroTag: 'wallet_hero_0',
                                                  ),
                                                )
                                              : PageView.builder(
                                                  controller: _pageController,
                                                  onPageChanged: notifier.onCardPageChanged,
                                                  itemBuilder: (context, index) {
                                                    final actualIndex = index % cards.length;
                                                    final card = cards[actualIndex];

                                                    return AnimatedBuilder(
                                                      animation: _pageController!,
                                                      builder: (context, child) {
                                                        double height = 200.0;
                                                        if (_pageController!.position.haveDimensions) {
                                                          double distance = (_pageController!.page! - index).abs();
                                                          // Center = 200, Side = 175
                                                          height = 200.0 - (distance * 25.0).clamp(0.0, 25.0);
                                                        } else {
                                                          height = index == _pageController!.initialPage ? 200.0 : 175.0;
                                                        }
                                                        return Align(
                                                          alignment: Alignment.center,
                                                          child: SizedBox(
                                                            height: height,
                                                            width: double.infinity,
                                                            child: child,
                                                          ),
                                                        );
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                                        child: _buildCardItem(
                                                          index: index,
                                                          actualIndex: actualIndex,
                                                          card: card,
                                                          isFrozen: card.isFrozen,
                                                          height: 200.0, // Height is handled by AnimatedBuilder above
                                                          heroTag: 'wallet_hero_$index',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                    ),
                                    const SizedBox(height: 15),

                                    // Page Indicator Dots
                                    if (cards.length > 1)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(cards.length, (index) {
                                          final actualActiveIndex = cards.isEmpty ? 0 : activeIndex % cards.length;
                                          final isSelected = index == actualActiveIndex;
                                          return AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 2.5,
                                            ),
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFE3E3E3),
                                            ),
                                          );
                                        }),
                                      ),
                                    if (cards.length > 1) const SizedBox(height: 55),
                                    if (cards.length <= 1) const SizedBox(height: 65),

                                    // Quick Action Buttons (Top up, Freeze, Details, Settings)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10, // Exactly 10px padding from the screen edges
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildActionButton(
                                            label: 'Top up',
                                            backgroundColor:
                                                const Color(0xFF10B981),
                                            iconWidget: Assets.icons.add.svg(
                                              width: 24,
                                              height: 24,
                                              colorFilter: const ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                              onTap: () {
                                                if (cards.isEmpty) return;
                                                final actualIndex = _getActiveCardIndex(cards.length);
                                                EditWalletBalanceBottomSheet.show(context, actualIndex);
                                              },
                                          ),
                                          const SizedBox(width: 10), // Exactly 10px gap
                                          _buildActionButton(
                                            label: 'Freeze',
                                            backgroundColor: isActiveCardFrozen
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEAEAEA),
                                            iconWidget: Assets.icons.freeze.svg(
                                              width: 24,
                                              height: 24,
                                              colorFilter: isActiveCardFrozen
                                                  ? const ColorFilter.mode(
                                                      Colors.white,
                                                      BlendMode.srcIn,
                                                    )
                                                  : null,
                                            ),
                                              onTap: () {
                                                if (cards.isEmpty) return;
                                                notifier.toggleFreezeCard();
                                              },
                                          ),
                                          const SizedBox(width: 10), // Exactly 10px gap
                                          _buildActionButton(
                                            label: 'Details',
                                            backgroundColor:
                                                const Color(0xFFEAEAEA),
                                            iconWidget: Assets.icons.card.svg(
                                              width: 24,
                                              height: 24,
                                            ),
                                              onTap: () {
                                                if (cards.isEmpty) return;
                                                final pageIndex = (_pageController?.hasClients == true) ? _pageController!.page!.round() : 0;
                                                final actualIndex = pageIndex % cards.length;
                                                setState(() {
                                                  _lastKnownPage = pageIndex;
                                                  _tappedCardIndex = actualIndex;
                                                  _isCardDetailExpanded = true;
                                                });
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    transitionDuration: const Duration(milliseconds: 380),
                                                    reverseTransitionDuration: const Duration(milliseconds: 380),
                                                    pageBuilder: (context, animation, secondaryAnimation) {
                                                      return WalletCardDetailRoute(
                                                        card: cards[actualIndex],
                                                        isFrozen: cards[actualIndex].isFrozen,
                                                        heroTag: 'wallet_hero_$pageIndex',
                                                        onPop: () {
                                                          if (mounted) {
                                                            setState(() {
                                                              _isCardDetailExpanded = false;
                                                            });
                                                          }
                                                        },
                                                      );
                                                    },
                                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                      return FadeTransition(opacity: animation, child: child);
                                                    },
                                                  ),
                                                );
                                              },
                                          ),
                                          const SizedBox(width: 10), // Exactly 10px gap
                                          _buildActionButton(
                                            label: 'Settings',
                                            backgroundColor:
                                                const Color(0xFFEAEAEA),
                                            iconWidget: Assets.icons.settings.svg(
                                              width: 24,
                                              height: 24,
                                            ),
                                            onTap: () {
                                              if (cards.isEmpty) return;
                                              final actualIndex = _getActiveCardIndex(cards.length);
                                              WalletSettingsBottomSheet.show(context, cards[actualIndex], actualIndex);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ),
                        ),
                      ),
                    );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Floating Navigation Bar (Always visible at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavigationBar(
              selectedIndex: 1,
              onTabSelected: (index) {
                widget.onTabSelected?.call(index);
              },
              onAddTap: () {
                AddTransactionBottomSheet.show(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem({
    required int index,
    required int actualIndex,
    required WalletCardModel card,
    required bool isFrozen,
    required double height,
    required String heroTag,
  }) {
    final state = ref.watch(walletNotifierProvider);
    final activeIndex = state.activeCardIndex;
    return Hero(
      tag: heroTag,
      flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return toHeroContext.widget;
          }
        );
      },
      child: WalletCardWidget(
        card: card,
        isFrozen: isFrozen && actualIndex == (activeIndex % state.cards.length),
        onTap: () {
          setState(() {
            _lastKnownPage = (_pageController?.hasClients == true) ? _pageController!.page!.round() : index;
            _tappedCardIndex = actualIndex;
            _isCardDetailExpanded = true;
          });
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              transitionDuration: const Duration(milliseconds: 380),
              reverseTransitionDuration: const Duration(milliseconds: 380),
              pageBuilder: (context, animation, secondaryAnimation) {
                return WalletCardDetailRoute(
                  card: card,
                  isFrozen: isFrozen && actualIndex == (activeIndex % state.cards.length),
                  heroTag: heroTag,
                  onPop: () {
                    if (mounted) {
                      setState(() {
                        _isCardDetailExpanded = false;
                      });
                    }
                  },
                );
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Widget iconWidget,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
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
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWalletView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tactile Empty Card Slot Illustration
            GestureDetector(
              onTap: () => AddWalletBottomSheet.show(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 240,
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top card elements: chip on left, overlapping circles on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 30,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(0xFFE5E5EA),
                              width: 1,
                            ),
                          ),
                        ),
                        // Translucent card circles
                        SizedBox(
                          width: 36,
                          height: 22,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 14,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Center + Add Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 24,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),

                    // Bottom card dots resembling card numbers
                    const Text(
                      '••••  ••••  ••••  ••••',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD1D1D6),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'No Cards in Wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111111),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Add a debit card, credit card, or bank account to manage your balance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8E8E93),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletCardDetailRoute extends StatelessWidget {
  const WalletCardDetailRoute({
    required this.card,
    required this.isFrozen,
    required this.heroTag,
    required this.onPop,
    super.key,
  });

  final WalletCardModel card;
  final bool isFrozen;
  final String heroTag;
  final VoidCallback onPop;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) onPop();
      },
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Spacer matching the exact size of the header in the main screen
              Opacity(
                opacity: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(text: '₹ ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                TextSpan(text: '0', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48), // matching profile icon height
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 365,
                    margin: const EdgeInsets.only(top: 40, left: 24, right: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Material(
                        type: MaterialType.transparency,
                        child: WalletCardDetailWidget(
                          card: card,
                          isFrozen: isFrozen,
                          heroTag: heroTag,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
