import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/shared/widgets/item_actions.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/presentation/widgets/transaction_amount.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class TransactionDetailCard extends ConsumerStatefulWidget {
  const TransactionDetailCard({
    required this.transaction,
    this.onDelete,
    this.onEdit,
    this.onTap,
    this.isOpen = false,
    this.onOpen,
    this.onClose,
    super.key,
  });

  final TransactionDetailModel transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  /// What a tap does when the transaction cannot be edited, for example
  /// showing an adjustment's details. A tap otherwise opens [onEdit].
  final VoidCallback? onTap;
  final bool isOpen;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  ConsumerState<TransactionDetailCard> createState() => _TransactionDetailCardState();
}

class _TransactionDetailCardState extends ConsumerState<TransactionDetailCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragOffset = 0;
  /// How far the card slides open: Delete and Edit, or Delete alone for
  /// items that cannot be edited.
  double get _maxDragDistance => widget.onEdit == null ? 76 : 146;

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
  void didUpdateWidget(TransactionDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) {
      if (!widget.isOpen && _dragOffset != 0) {
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
    if (_dragOffset != 0) {
      _animateTo(0);
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final kind = tx.resolvedKind;
    final direction = moneyDirectionOf(kind, isIncome: tx.isIncome);
    final amountText = Money.signed(
      tx.amount,
      symbol: ref.watch(currencySymbolProvider),
      direction: direction,
    );
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
                  // Delete Button (First tap: red trash icon; tap again to confirm: red circle with white checkmark)
                  SwipeDeleteButton(
                    isConfirming: false,
                    onTap: () {
                      // Deletes straight away; the screen offers Undo.
                      _close();
                      widget.onDelete?.call();
                    },
                  ),
                  if (widget.onEdit != null) ...[
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
              // A tap opens the transaction for editing (or closes the
              // swiped-open buttons). One that can't be edited, such as a
              // balance adjustment, shows its details instead.
              onTap: () {
                if (_dragOffset < 0) {
                  _close();
                } else {
                  (widget.onEdit ?? widget.onTap)?.call();
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
                    // Top Row: Arrow badge, Title & Date, Amount & Currency
                    Semantics(
                      label: transactionSemanticsLabel(
                        kind: kind,
                        title: tx.title,
                        amount: amountText,
                        when: tx.date.toRelativeDate,
                      ),
                      onTapHint: transactionTapHint(
                        canEdit: widget.onEdit != null,
                        hasDetails: widget.onTap != null,
                      ),
                      excludeSemantics: true,
                      child: Row(
                      children: [
                        // Direction Arrow Circle Badge (↓ for income, ↑ for expense)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: ZenioColors.fieldFill,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: kind == TransactionKind.adjustment
                                ? const Icon(
                                    transactionAdjustmentIcon,
                                    size: 24,
                                    color: Color(0xFF000000),
                                  )
                                : kind == TransactionKind.transfer
                                ? Assets.icons.swap.svg(
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF000000),
                                      BlendMode.srcIn,
                                    ),
                                  )
                                : widget.transaction.isIncome
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

                        // Title & Date Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.transaction.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.transaction.date.toRelativeDate,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: ZenioColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Signed amount: +₹85,000 in, −₹420 out.
                        AmountText(
                          tx.amount,
                          direction: direction,
                          color: amountColorOf(kind),
                        ),
                      ],
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
