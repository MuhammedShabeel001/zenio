import 'package:flutter/material.dart';

/// Puts the keyboard away when the user taps outside the text field being
/// edited, as iOS users expect: the iOS number pad has no key for it.
///
/// Buttons, fields and other controls still get their own taps; only a tap
/// that nothing else takes reaches this.
class DismissKeyboardOnTap extends StatelessWidget {
  const DismissKeyboardOnTap({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissKeyboard,
      // Not an action for screen readers: it would make the whole app one
      // tappable item.
      excludeFromSemantics: true,
      child: child,
    );
  }

  static void _dismissKeyboard() {
    final focus = FocusManager.instance.primaryFocus;
    // Only a text field lets go; focus anywhere else stays where it is.
    if (focus?.context?.findAncestorStateOfType<EditableTextState>() != null) {
      focus!.unfocus();
    }
  }
}
