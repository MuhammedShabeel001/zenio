import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/shared/widgets/item_actions.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class DebtCard extends ConsumerStatefulWidget {
  const DebtCard({
    required this.debt,
    this.onDelete,
    this.onEdit,
    this.isOpen = false,
    this.onOpen,
    this.onClose,
    this.isTileExpanded,
    this.onTileTap,
    this.description,
    super.key,
  });

  final DebtModel debt;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isOpen;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final bool? isTileExpanded;
  final VoidCallback? onTileTap;
  final String? description;

  @override
  ConsumerState<DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends ConsumerState<DebtCard>
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
  void didUpdateWidget(DebtCard oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    // isOwed means the user owes this person: money going out.
    final youOwe = widget.debt.isOwed;
    final direction =
        youOwe ? MoneyDirection.outgoing : MoneyDirection.incoming;
    final directionLabel = youOwe ? 'You owe' : 'Owes you';
    final when = widget.debt.date.toRelativeDate;
    return ItemActions(
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      // The swipe button asks twice; long press and screen readers confirm.
      confirmDeleteTitle: 'Delete this debt?',
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
                  // Delete Button (First tap: red trash icon; tap again to confirm: red circle with white checkmark)
                  SwipeDeleteButton(
                    isConfirming: _isConfirmingDelete,
                    onTap: () {
                      if (!_isConfirmingDelete) {
                        setState(() {
                          _isConfirmingDelete = true;
                        });
                      } else {
                        _close();
                        widget.onDelete?.call();
                      }
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
                  final hasNote = widget.debt.note != null && widget.debt.note!.trim().isNotEmpty;
                  final hasDesc = widget.description != null && widget.description!.trim().isNotEmpty;
                  if (!hasNote && !hasDesc) return;

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
                    // Top Row: Arrow Badge, Person Name & Date, Amount
                    Semantics(
                      label: '${widget.debt.personName}, $directionLabel, '
                          '${Money.signed(widget.debt.amount, symbol: ref.watch(currencySymbolProvider), direction: direction)}, $when',
                      excludeSemantics: true,
                      child: Row(
                      children: [
                        // Circle Badge with Up Arrow SVG Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: ZenioColors.fieldFill,
                            shape: BoxShape.circle,
                          ),
                          // Money coming to you points down, as income
                          // does elsewhere; money you owe points up.
                          child: Center(
                            child: !youOwe
                                ? Assets.icons.downArrow.svg(
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF000000),
                                      BlendMode.srcIn,
                                    ),
                                  )
                                : Assets.icons.upArrow.svg(
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF000000),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Person Name & Date Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.debt.personName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: directionLabel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: youOwe
                                            ? ZenioColors.textPrimary
                                            : ZenioColors.income,
                                      ),
                                    ),
                                    TextSpan(text: ' · $when'),
                                  ],
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: ZenioColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Signed amount: +₹1,200 owed to you, −₹500 you owe.
                        AmountText(widget.debt.amount, direction: direction),
                      ],
                    ),
                    ),

                    // Expandable Detail Section (Description Header & Note Text)
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
                            const Text(
                              'Description :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: ZenioColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (widget.debt.note?.isNotEmpty ?? false)
                                  ? widget.debt.note!
                                  : (widget.description ?? ''),
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
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
