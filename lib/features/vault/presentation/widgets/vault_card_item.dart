import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/swipe_delete_button.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

class VaultCardItem extends StatefulWidget {
  const VaultCardItem({
    required this.card,
    this.onDelete,
    this.onEdit,
    this.isOpen = false,
    this.onOpen,
    this.onClose,
    super.key,
  });

  final VaultCardModel card;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isOpen;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  State<VaultCardItem> createState() => _VaultCardItemState();
}

class _VaultCardItemState extends State<VaultCardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragOffset = 0;
  bool _isConfirmingDelete = false;
  static const double _maxDragDistance = 146;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _dragOffset = widget.isOpen ? -_maxDragDistance : 0;

    _animation =
        Tween<double>(begin: _dragOffset, end: _dragOffset).animate(
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
  void didUpdateWidget(VaultCardItem oldWidget) {
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
      _dragOffset = (_dragOffset + details.delta.dx)
          .clamp(-_maxDragDistance, 0);
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

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ZenioSnackBar.show(
      context,
      message: '$label copied to clipboard',
      type: ZenioSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 200,
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF031A0F),
                      Color(0xFF073820),
                      Color(0xFF0C5634),
                      Color(0xFF10B981),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Row: Card Title & Mastercard Logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.card.cardType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),

                        // Translucent Mastercard Logo Circles
                        SizedBox(
                          width: 44,
                          height: 28,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 14,
                                top: 2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Middle Row: Card Number & Copy Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.card.cardNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _copyToClipboard(
                            context,
                            widget.card.cardNumber,
                            'Card number',
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Row: Expiry & CVV
                    Row(
                      children: [
                        // Expiry Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  widget.card.expiry,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(
                                    context,
                                    widget.card.expiry,
                                    'Expiry',
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 60),

                        // CVV Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CVV',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  widget.card.cvv,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _copyToClipboard(
                                    context,
                                    widget.card.cvv,
                                    'CVV',
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
