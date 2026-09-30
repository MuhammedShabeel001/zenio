import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/item_actions.dart';

class SubscriptionCard extends ConsumerStatefulWidget {
  const SubscriptionCard({
    required this.subscription,
    this.onDelete,
    this.onEdit,
    this.isOpen = false,
    this.onOpen,
    this.onClose,
    this.isTileExpanded,
    this.onTileTap,
    super.key,
  });

  final SubscriptionModel subscription;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isOpen;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final bool? isTileExpanded;
  final VoidCallback? onTileTap;

  @override
  ConsumerState<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<SubscriptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragOffset = 0;
  bool _isConfirmingDelete = false;
  static const double _maxDragDistance = 146;
  bool _internalTileExpanded = false;

  bool get _effectiveIsTileExpanded =>
      widget.isTileExpanded ?? _internalTileExpanded;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: ZenioMotion.standard,
    );

    _dragOffset = widget.isOpen ? -_maxDragDistance : 0;

    _animation = Tween<double>(begin: _dragOffset, end: _dragOffset).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
  }

  @override
  void didUpdateWidget(SubscriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (!widget.isOpen && _dragOffset != 0) {
        _isConfirmingDelete = false;
        _animateTo(0);
      } else if (widget.isOpen && _dragOffset != -_maxDragDistance) {
        _animateTo(-_maxDragDistance);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animateTo(double targetOffset) {
    if (targetOffset == 0 && _isConfirmingDelete) {
      _isConfirmingDelete = false;
    }
    _animation = Tween<double>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward(from: 0);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx < 0 && !widget.isOpen) {
      widget.onOpen?.call();
    }
    setState(() {
      _dragOffset =
          (_dragOffset + details.delta.dx).clamp(-_maxDragDistance, 0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset < -_maxDragDistance / 2.5 ||
        details.velocity.pixelsPerSecond.dx < -300) {
      _animateTo(-_maxDragDistance);
      widget.onOpen?.call();
    } else {
      _animateTo(0);
      widget.onClose?.call();
    }
  }

  /// The Edit button revealed by a swipe.
  void _editFromSwipe() {
    _close();
    widget.onEdit?.call();
  }

  void _close() {
    if (_isConfirmingDelete) {
      setState(() {
        _isConfirmingDelete = false;
      });
    }
    if (_dragOffset != 0) {
      _animateTo(0);
      widget.onClose?.call();
    }
  }

  /// "/ month" for a monthly price, and so on.
  static String _perCycle(String cycle) {
    return switch (cycle.trim().toLowerCase()) {
      'daily' => '/ day',
      'weekly' => '/ week',
      'yearly' => '/ year',
      _ => '/ month',
    };
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(subscriptionCategoriesNotifierProvider);
    final matchedCat = categories.where(
      (c) =>
          c.name.trim().toLowerCase() ==
          widget.subscription.category.trim().toLowerCase(),
    );
    final categoryEmoji = matchedCat.isNotEmpty
        ? matchedCat.first.emoji
        : (widget.subscription.iconName.isNotEmpty &&
                widget.subscription.iconName != 'music'
            ? widget.subscription.iconName
            : '🏷️');

    // Compare calendar days, not times: due tomorrow is 'Tomorrow' at any
    // time of day.
    final difference = DateUtils.dateOnly(widget.subscription.nextBillingDate)
        .difference(DateUtils.dateOnly(DateTime.now()))
        .inDays;

    String computedDueInText;
    if (difference == 0) {
      computedDueInText = 'Today';
    } else if (difference == 1) {
      computedDueInText = 'Tomorrow';
    } else if (difference < 0) {
      final days = difference.abs();
      computedDueInText = 'Overdue by $days day${days == 1 ? '' : 's'}';
    } else {
      computedDueInText = 'In $difference days';
    }

    final formattedNextBillingDate =
        DateTimeUtils.displayDate(widget.subscription.nextBillingDate);

    return ItemActions(
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      child: Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Slide Action Buttons (Delete & Edit)
          Positioned(
            top: 0,
            right: 0,
            child: ExcludeSemantics(
              // Hidden under the card until it is swiped open; the card's own
              // actions offer Edit and Delete meanwhile.
              excluding: _dragOffset == 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Deletes straight away; the screen offers Undo.
                  SwipeDeleteButton(
                    isConfirming: false,
                    onTap: () {
                      _close();
                      widget.onDelete?.call();
                    },
                  ),
                  const SizedBox(width: 3),
  
                  // Edit Button (White Circle + Pencil Edit Icon)
                  Semantics(
                    button: true,
                    label: 'Edit',
                    onTap: _editFromSwipe,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: _editFromSwipe,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Assets.icons.edit.svg(
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Foreground Slidable Card Layer
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onTap: () {
                if (_dragOffset < 0) {
                  _close();
                } else {
                  if (widget.onTileTap != null) {
                    widget.onTileTap!();
                  } else {
                    setState(() {
                      _internalTileExpanded = !_internalTileExpanded;
                    });
                  }
                }
              },
              child: AnimatedContainer(
                duration: ZenioMotion.standard,
                curve: Curves.fastOutSlowIn,
                padding: const EdgeInsets.fromLTRB(5, 5, 20, 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Music Icon Badge, Title & Category, Amount & Due In Text
                    Row(
                      children: [
                        // Category Emoji Circle Badge
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: ZenioColors.fieldFill,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              categoryEmoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Category Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.subscription.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(height: 3),
                              // One line: a long category ends in "…"
                              // rather than breaking mid-word.
                              Text(
                                widget.subscription.category,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: ZenioColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Amount & Due In Subtitle Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                AmountText(
                                  widget.subscription.amount,
                                  direction: MoneyDirection.neutral,
                                ),
                                const SizedBox(width: 4),
                                // How often, which the total above relies on.
                                Text(
                                  _perCycle(widget.subscription.billingCycle),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: ZenioColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              computedDueInText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: ZenioColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Expandable Detail Section (Next Billing & Billing Cycle)
                    AnimatedCrossFade(
                      duration: ZenioMotion.standard,
                      firstCurve: Curves.fastOutSlowIn,
                      secondCurve: Curves.fastOutSlowIn,
                      sizeCurve: Curves.fastOutSlowIn,
                      crossFadeState: _effectiveIsTileExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(
                        width: double.infinity,
                        height: 0,
                      ),
                      secondChild: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 12, 0, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(
                          children: [
                            // Left Column: Next Billing
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next billing',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: ZenioColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedNextBillingDate,
                                    style: AppFonts.numeric(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: ZenioColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Middle Vertical Divider Line
                            Container(
                              width: 1,
                              height: 32,
                              color: const Color(0xFFECECEC),
                            ),

                            // Right Column: Billing Cycle
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Billing cycle',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: ZenioColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.subscription.billingCycle,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: ZenioColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                            const SizedBox(height: ZenioSpacing.md),
                            // When reminders come (see reminder_schedule).
                            const Text(
                              "You're reminded the day before, at 9 AM.",
                              style: TextStyle(
                                fontSize: 12,
                                color: ZenioColors.textSecondary,
                              ),
                            ),
                          ],
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
}
