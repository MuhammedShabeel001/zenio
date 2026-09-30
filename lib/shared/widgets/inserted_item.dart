import 'package:flutter/widgets.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';

/// A list item that grows and fades in when it is added while the list is
/// on screen, so the eye catches where it went. Give it a key per item: only
/// a new item animates, and only when [animate] is set, so a list shown for
/// the first time appears as it is.
class InsertedItem extends StatefulWidget {
  const InsertedItem({
    required this.child,
    required this.animate,
    super.key,
  });

  final Widget child;

  /// Whether this item, if new, is being added to a list already on screen.
  final bool animate;

  @override
  State<InsertedItem> createState() => _InsertedItemState();
}

class _InsertedItemState extends State<InsertedItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: ZenioMotion.standardCurve,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value < 1 && !_controller.isAnimating) {
      _controller
        ..duration = ZenioMotion.of(context, ZenioMotion.standard)
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1,
      child: FadeTransition(opacity: _curve, child: widget.child),
    );
  }
}
