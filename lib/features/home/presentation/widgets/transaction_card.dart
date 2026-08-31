import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/datetime.dart';

class TransactionCard extends StatefulWidget {
  const TransactionCard({
    required this.transaction,
    this.onDelete,
    this.onEdit,
    this.isOpen = false,
    this.onOpen,
    this.onClose,
    super.key,
  });

  final TransactionModel transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isOpen;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragOffset = 0;
  static const double _maxDragDistance = 146;

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
  void didUpdateWidget(TransactionCard oldWidget) {
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

  void _close() {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Slide Action Buttons (Delete & Edit)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete Button (White Circle + Red Trash Icon)
                  GestureDetector(
                    onTap: () {
                      _close();
                      widget.onDelete?.call();
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Assets.icons.delete.svg(
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
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
                      decoration: BoxDecoration(
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
          ),

          // Foreground Slidable Card Layer
          AnimatedPositioned(
            duration: Duration.zero,
            left: _dragOffset,
            right: -_dragOffset,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onTap: () {
                if (_dragOffset < 0) {
                  _close();
                }
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 5, 20, 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    // Circle Badge Icon
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

                    // Amount + Currency Unit
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
                          widget.transaction.currency,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
