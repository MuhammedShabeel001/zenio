import 'package:flutter/material.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

/// A circular action button for swipe-to-delete cards.
///
/// On the first tap, it switches from a white circle with a red trash icon
/// to a red circle with a white checkmark/tick mark to request user confirmation.
/// Tapping it while in the confirmation state executes the deletion.
class SwipeDeleteButton extends StatelessWidget {
  const SwipeDeleteButton({
    required this.isConfirming,
    required this.onTap,
    this.size = 70,
    super.key,
  });

  final bool isConfirming;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isConfirming ? const Color(0xFFDD3D34) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: isConfirming
                ? const Icon(
                    Icons.check_rounded,
                    key: ValueKey('swipe_delete_confirm_tick'),
                    color: Colors.white,
                    size: 28,
                  )
                : Assets.icons.delete.svg(
                    key: const ValueKey('swipe_delete_trash_icon'),
                    width: 24,
                    height: 24,
                  ),
          ),
        ),
      ),
    );
  }
}
