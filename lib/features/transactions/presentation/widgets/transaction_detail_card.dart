import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/datetime.dart';
import 'package:zenio/shared/widgets/swipe_delete_button.dart';

class TransactionDetailCard extends ConsumerStatefulWidget {
  const TransactionDetailCard({
    required this.transaction,
    this.onDelete,
    this.onEdit,
    this.isOpen = false,
    this.onOpen,
    this.onClose,
    this.isTileExpanded,
    this.onTileTap,
    this.onExpansionChanged,
    this.note,
    this.bankName,
    this.timestamp,
    super.key,
  });

  final TransactionDetailModel transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isOpen;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final bool? isTileExpanded;
  final VoidCallback? onTileTap;
  final ValueChanged<bool>? onExpansionChanged;
  final String? note;
  final String? bankName;
  final String? timestamp;

  @override
  ConsumerState<TransactionDetailCard> createState() => _TransactionDetailCardState();
}

class _TransactionDetailCardState extends ConsumerState<TransactionDetailCard>
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
      duration: const Duration(milliseconds: 250),
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

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(currencyCodeProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Slide Action Buttons (Delete & Edit)
          Positioned(
            top: 0,
            right: 0,
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
                GestureDetector(
                  onTap: () {
                    _close();
                    widget.onEdit?.call();
                  },
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
              ],
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
                duration: const Duration(milliseconds: 300),
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
                    Row(
                      children: [
                        // Direction Arrow Circle Badge (↓ for income, ↑ for expense)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF2F2F2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: widget.transaction.title.startsWith('Transfer to')
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
                                  color: Color(0xFFB2B2B2),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Amount & Currency
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatAmount(widget.transaction.amount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000000),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currencyCode,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Expandable Detail Section (Note, Divider, Bank Name & Timestamp)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
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
                            if (widget.note != null && widget.note!.isNotEmpty) ...[
                              const Text(
                                'Note :',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.note!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF000000),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                color: Color(0xFFE5E5E5),
                                height: 1,
                                thickness: 1,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Assets.icons.walletOpen.svg(
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      widget.bankName ?? 'SBI Bank',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        // fontWeight: FontWeight.bold,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  widget.timestamp ?? '12-05-26   12 : 39',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFB2B2B2),
                                  ),
                                ),
                              ],
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
    );
  }
}
