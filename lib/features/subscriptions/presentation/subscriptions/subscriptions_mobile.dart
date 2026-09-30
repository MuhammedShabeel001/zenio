import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/presentation/widgets/add_subscription_bottom_sheet.dart';
import 'package:zenio/features/subscriptions/presentation/widgets/edit_subscription_dialog.dart';
import 'package:zenio/features/subscriptions/presentation/widgets/subscription_card.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class SubscriptionsScreenMobile extends ConsumerStatefulWidget {
  const SubscriptionsScreenMobile({this.initialExpandedId, super.key});

  /// A subscription to show expanded when the screen opens, for example the
  /// one a reminder was about.
  final String? initialExpandedId;

  @override
  ConsumerState<SubscriptionsScreenMobile> createState() =>
      _SubscriptionsScreenMobileState();
}

class _SubscriptionsScreenMobileState
    extends ConsumerState<SubscriptionsScreenMobile> {
  String? _openSubscriptionId;
  late String? _expandedTileId = widget.initialExpandedId;

  /// Set until the subscription a reminder opened this screen for has been
  /// scrolled into view.
  late bool _revealPending = widget.initialExpandedId != null;
  final _remindedKey = GlobalKey();
  final _listController = ScrollController();

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final remindedId = widget.initialExpandedId;
    if (remindedId == null) return;
    // The filter chosen on an earlier visit may hide the subscription the
    // reminder was about.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(subscriptionsNotifierProvider);
      if (state.selectedFilter.toLowerCase() != 'all' &&
          !state.subscriptions.any((s) => s.id == remindedId)) {
        ref.read(subscriptionsNotifierProvider.notifier).updateFilter('All');
      }
    });
  }

  /// Scrolls to the reminded subscription once it is in the list.
  void _revealRemindedWhenListed(List<SubscriptionModel> subscriptions) {
    if (!_revealPending ||
        !subscriptions.any((s) => s.id == widget.initialExpandedId)) {
      return;
    }
    _revealPending = false;
    _scrollToReminded();
  }

  /// The list builds cards as they scroll in, so it moves down a screen at a
  /// time until the reminded card exists, then brings it fully into view.
  void _scrollToReminded({int screensLeft = 20}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final card = _remindedKey.currentContext;
      if (card != null) {
        Scrollable.ensureVisible(
          card,
          duration: ZenioMotion.standard,
          curve: ZenioMotion.standardCurve,
        );
        return;
      }
      if (screensLeft == 0 || !_listController.hasClients) return;
      final position = _listController.position;
      if (position.pixels >= position.maxScrollExtent) return;
      _listController.jumpTo(
        math.min(
          position.pixels + position.viewportDimension,
          position.maxScrollExtent,
        ),
      );
      _scrollToReminded(screensLeft: screensLeft - 1);
    });
  }
  String _formatWholePart(double amount) =>
      AppNumberFormat.formatWholePart(amount);

  String _formatDecimalPart(double amount) =>
      AppNumberFormat.formatDecimalPart(amount);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionsNotifierProvider);
    final subscriptions = state.subscriptions;
    _revealRemindedWhenListed(subscriptions);
    final totalBalance = state.totalBalance;

    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenTitleBar(title: 'Subscriptions'),
            // Dark Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Balance Display & + Add Button Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Balance
                      Flexible(
                        // Large amounts and text sizes shrink to fit instead of overflowing.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$currencySymbol ',
                                  style: AppFonts.numeric(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatWholePart(totalBalance),
                                  style: AppFonts.numeric(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatDecimalPart(totalBalance),
                                  style: AppFonts.numeric(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF808080),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // + Add Button Pill
                      GestureDetector(
                        onTap: () {
                          AddSubscriptionBottomSheet.show(context);
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
                  const SizedBox(height: 16),

                  // Bottom Row: Filter Dropdown Pill
                  Row(
                    children: [
                      _buildFilterPicker(state.selectedFilter),
                    ],
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
                    top: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: ListView(
                    controller: _listController,
                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
                    children: [
                      if (subscriptions.isEmpty) ...[
                        if (state.isLoading)
                          const ListStateMessage.loading()
                        else if (state.errorMessage != null)
                          ListStateMessage.error(
                            onRetry: ref
                                .read(subscriptionsNotifierProvider.notifier)
                                .loadData,
                          )
                        else if (state.selectedFilter.toLowerCase() == 'all')
                          ListStateMessage(
                            title: 'No subscriptions yet',
                            message:
                                'Add the services you pay for regularly to see your total and get a reminder before each renewal.',
                            icon: Icons.autorenew_rounded,
                            actionLabel: 'Add subscription',
                            onAction: () =>
                                AddSubscriptionBottomSheet.show(context),
                          )
                        else
                          ListStateMessage(
                            title: 'Nothing here',
                            message:
                                'No ${state.selectedFilter.toLowerCase()} subscriptions.',
                            icon: Icons.filter_alt_off_outlined,
                          ),
                      ] else
                        ...subscriptions.map(
                          (item) => KeyedSubtree(
                            key: ValueKey(item.id),
                            child: SubscriptionCard(
                              key: item.id == widget.initialExpandedId
                                  ? _remindedKey
                                  : null,
                              subscription: item,
                              isOpen: _openSubscriptionId == item.id,
                              isTileExpanded: _expandedTileId == item.id,
                              onTileTap: () {
                                setState(() {
                                  if (_expandedTileId == item.id) {
                                    _expandedTileId = null;
                                  } else {
                                    _expandedTileId = item.id;
                                  }
                                });
                              },
                              onOpen: () {
                                if (_openSubscriptionId != item.id) {
                                  setState(() {
                                    _openSubscriptionId = item.id;
                                  });
                                }
                              },
                              onClose: () {
                                if (_openSubscriptionId == item.id) {
                                  setState(() {
                                    _openSubscriptionId = null;
                                  });
                                }
                              },
                              onDelete: () async {
                                try {
                                  await ref
                                      .read(subscriptionsNotifierProvider.notifier)
                                      .deleteSubscription(item.id);
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ZenioSnackBar.show(
                                    context,
                                    message:
                                        "Couldn't delete the subscription. Please try again.",
                                    type: ZenioSnackBarType.error,
                                  );
                                  return;
                                }
                                if (!context.mounted) return;
                                ZenioSnackBar.show(
                                  context,
                                  message: 'Subscription deleted',
                                  type: ZenioSnackBarType.success,
                                );
                              },
                              onEdit: () {
                                EditSubscriptionDialog.show(
                                  context,
                                  subscription: item,
                                );
                              },
                            ),
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

  Widget _buildFilterPill({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
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
    );
  }

  Widget _buildFilterPicker(String currentFilter) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      elevation: 8,
      onSelected: (value) {
        ref.read(subscriptionsNotifierProvider.notifier).updateFilter(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'All',
          child: Text('All', style: TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Weekly',
          child: Text('Weekly', style: TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Monthly',
          child: Text('Monthly', style: TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Yearly',
          child: Text('Yearly', style: TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF313131)),
      ),
      child: _buildFilterPill(label: currentFilter),
    );
  }
}
