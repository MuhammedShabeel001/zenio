import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_detail_widget.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController?.dispose();
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

    // Dynamically initialize controller to start at a clean multiple of cards.length
    if (_pageController == null && cards.isNotEmpty) {
      final initialPage = 1000 * cards.length;
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
                                  text: _formatWholePart(cardBalance),
                                  style: const TextStyle(
                                    fontSize: 32,
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
                          AddTransactionBottomSheet.show(context);
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

                // Light Curved Content Sheet with Smooth Dissolve Transition
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOut,
                    opacity: _isCardDetailExpanded ? 0.0 : 1.0,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        child: Stack(
                          children: [
                            ListView(
                              padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                              children: [
                                // Card Carousel PageView
                                SizedBox(
                                  height: 200,
                                  child: _pageController == null
                                      ? const SizedBox.shrink()
                                      : PageView.builder(
                                          controller: _pageController,
                                          onPageChanged:
                                              notifier.onCardPageChanged,
                                          itemBuilder: (context, index) {
                                            if (cards.isEmpty)
                                              return const SizedBox.shrink();
                                            final actualIndex =
                                                index % cards.length;
                                            final card = cards[actualIndex];

                                            return AnimatedBuilder(
                                              animation: _pageController!,
                                              builder: (context, child) {
                                                double height = 200.0;
                                                if (_pageController!
                                                    .position.haveDimensions) {
                                                  double distance =
                                                      (_pageController!.page! -
                                                              index)
                                                          .abs();
                                                  // Center = 200, Side = 175
                                                  height = 200.0 -
                                                      (distance * 25.0)
                                                          .clamp(0.0, 25.0);
                                                } else {
                                                  height = index ==
                                                          _pageController!
                                                              .initialPage
                                                      ? 200.0
                                                      : 175.0;
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
                                              child: WalletCardWidget(
                                                card: card,
                                                isFrozen: isFrozen &&
                                                    actualIndex ==
                                                        (activeIndex %
                                                            cards.length),
                                                onTap: () {
                                                  setState(() {
                                                    _isCardDetailExpanded =
                                                        true;
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 15),

                                // Page Indicator Dots
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      List.generate(cards.length, (index) {
                                    final actualActiveIndex = cards.isEmpty
                                        ? 0
                                        : activeIndex % cards.length;
                                    final isSelected =
                                        index == actualActiveIndex;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
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
                                const SizedBox(height: 55),

                                // Quick Action Buttons (Top up, Freeze, Details, Settings)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        10, // Exactly 10px padding from the screen edges
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          notifier.topUpBalance(1000);
                                        },
                                      ),
                                      const SizedBox(
                                          width: 10), // Exactly 10px gap
                                      _buildActionButton(
                                        label: 'Freeze',
                                        backgroundColor:
                                            const Color(0xFFEAEAEA),
                                        iconWidget: Assets.icons.freeze.svg(
                                          width: 24,
                                          height: 24,
                                        ),
                                        onTap: notifier.toggleFreezeCard,
                                      ),
                                      const SizedBox(
                                          width: 10), // Exactly 10px gap
                                      _buildActionButton(
                                        label: 'Details',
                                        backgroundColor:
                                            const Color(0xFFEAEAEA),
                                        iconWidget: Assets.icons.card.svg(
                                          width: 24,
                                          height: 24,
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _isCardDetailExpanded = true;
                                          });
                                        },
                                      ),
                                      const SizedBox(
                                          width: 10), // Exactly 10px gap
                                      _buildActionButton(
                                        label: 'Settings',
                                        backgroundColor:
                                            const Color(0xFFEAEAEA),
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
                                onAddTap: () {
                                  AddTransactionBottomSheet.show(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card Detail Expanded Overlay View with Fluid Scale & Fade Animation
          IgnorePointer(
            ignoring: !_isCardDetailExpanded,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              opacity: _isCardDetailExpanded ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isCardDetailExpanded = false;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(
                  color: Colors.black,
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        // Top Header (Balance & + Add Pill Button)
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
                              GestureDetector(
                                onTap: () {
                                  AddTransactionBottomSheet.show(context);
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

                        // Centered Card Detail Widget with Fluid Scale & Slide Transition
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GestureDetector(
                              onTap:
                                  () {}, // Prevent taps inside from dismissing
                              child: AnimatedSlide(
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.fastOutSlowIn,
                                offset: _isCardDetailExpanded
                                    ? Offset.zero
                                    : const Offset(0, 0.06),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 380),
                                  curve: Curves.fastOutSlowIn,
                                  scale: _isCardDetailExpanded ? 1.0 : 0.88,
                                  child: cards.isNotEmpty
                                      ? WalletCardDetailWidget(
                                          card:
                                              cards[activeIndex % cards.length],
                                          isFrozen: isFrozen,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Floating Navigation Bar
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
                  ),
                ),
              ),
            ),
          ),
        ],
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
}
