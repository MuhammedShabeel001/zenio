import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenio/shared/widgets/item_actions.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/shared/services/secure_platform.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class VaultCardItem extends StatefulWidget {
  const VaultCardItem({
    required this.card,
    this.isRevealed = false,
    this.onToggleReveal,
    this.onDelete,
    this.onEdit,
    this.isOpen = false,
    this.onOpen,
    this.onClose,
    super.key,
  });

  final VaultCardModel card;

  /// Whether the full card number and CVV are shown instead of masked.
  final bool isRevealed;
  final VoidCallback? onToggleReveal;
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
  static const double _maxDragDistance = 146;

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
  void didUpdateWidget(VaultCardItem oldWidget) {
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

  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String label,
  ) async {
    await SecurePlatform.copySensitive(text);
    await HapticFeedback.selectionClick();
    if (!context.mounted) return;
    ZenioSnackBar.show(
      context,
      message: '$label copied',
      type: ZenioSnackBarType.success,
    );
  }

  /// Shows only the last four digits, e.g. `•••• •••• •••• 4242`.
  static String _maskedNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '•••• $digits';
    return '•••• •••• •••• ${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return ItemActions(
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      // Grows with the text size so larger text is not clipped.
      height: MediaQuery.textScalerOf(context).scale(200),
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
                      // The screen asks for confirmation before deleting.
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
                      ZenioColors.primary,
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
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.isRevealed
                                  ? widget.card.cardNumber
                                  : _maskedNumber(widget.card.cardNumber),
                              maxLines: 1,
                              style: AppFonts.numeric(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        _CardAction(
                          icon: widget.isRevealed
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          label: widget.isRevealed
                              ? 'Hide card details'
                              : 'Show card details',
                          onTap: widget.onToggleReveal,
                        ),
                        _CardAction(
                          icon: Icons.copy_rounded,
                          label: 'Copy card number',
                          onTap: () => _copyToClipboard(
                            context,
                            widget.card.cardNumber,
                            'Card number',
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
                                  style: AppFonts.numeric(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                _CardAction(
                                  icon: Icons.copy_rounded,
                                  label: 'Copy expiry date',
                                  size: 16,
                                  onTap: () => _copyToClipboard(
                                    context,
                                    widget.card.expiry,
                                    'Expiry',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 48),

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
                                  // The length is not revealed either.
                                  widget.isRevealed ? widget.card.cvv : '•••',
                                  style: AppFonts.numeric(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                _CardAction(
                                  icon: Icons.copy_rounded,
                                  label: 'Copy CVV',
                                  size: 16,
                                  onTap: () => _copyToClipboard(
                                    context,
                                    widget.card.cvv,
                                    'CVV',
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
    ),
    );
  }
}

/// A small icon action on the card with a screen-reader label and a 40dp
/// touch target (the card layout has no room for 48dp).
class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 18,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(
            icon,
            size: size,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
