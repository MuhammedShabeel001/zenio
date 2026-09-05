import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';

class DonutChartWidget extends ConsumerStatefulWidget {
  const DonutChartWidget({
    required this.categories,
    super.key,
  });

  final List<CategorySpendModel> categories;

  @override
  ConsumerState<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends ConsumerState<DonutChartWidget> {
  int? _selectedIndex;
  DateTime? _pointerDownTime;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      var clean = hex.replaceAll('#', '').trim();
      if (clean.startsWith('0x') || clean.startsWith('0X')) {
        return Color(int.parse(clean));
      }
      if (clean.length == 6) {
        clean = 'FF$clean';
      }
      return Color(int.parse('0x$clean'));
    } catch (_) {
      return const Color(0xFFFF771C);
    }
  }

  int? _getCategoryIndexAt(Offset localPosition, Size size, double total) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Responsive ring touch zone (radius roughly 45 to 110)
    if (distance < 40 || distance > 115) {
      return null;
    }

    final touchAngle = atan2(dy, dx);
    const initialAngle = -pi / 2 + 0.08;

    var diff = touchAngle - initialAngle;
    while (diff < 0) {
      diff += 2 * pi;
    }
    while (diff >= 2 * pi) {
      diff -= 2 * pi;
    }

    var accumulated = 0.0;
    for (var i = 0; i < widget.categories.length; i++) {
      final sweep = (widget.categories[i].amount / total) * (2 * pi);
      if (diff >= accumulated && diff < accumulated + sweep) {
        return i;
      }
      accumulated += sweep;
    }
    return null;
  }

  void _onPointerDown(PointerDownEvent event, Size size, double total) {
    _hideTimer?.cancel();
    _pointerDownTime = DateTime.now();

    final index = _getCategoryIndexAt(event.localPosition, size, total);
    if (index != null && index != _selectedIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event, Size size, double total) {
    final index = _getCategoryIndexAt(event.localPosition, size, total);
    if (index != null && index != _selectedIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final downTime = _pointerDownTime;
    _pointerDownTime = null;

    if (downTime != null) {
      final elapsed = DateTime.now().difference(downTime).inMilliseconds;
      // If held for more than 350ms, release immediately when finger lifts
      if (elapsed > 350) {
        setState(() {
          _selectedIndex = null;
        });
      } else {
        // Quick tap: keep visible for 2.5 seconds so the user can read it comfortably
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() {
              _selectedIndex = null;
            });
          }
        });
      }
    } else {
      setState(() {
        _selectedIndex = null;
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDownTime = null;
    setState(() {
      _selectedIndex = null;
    });
  }

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return NumberFormat('#,##0').format(amount.toInt());
    }
    return NumberFormat('#,##0.00').format(amount);
  }

  Widget _buildCenterInfo(CategorySpendModel category, double total) {
    final percent = total > 0 ? (category.amount / total * 100) : 0.0;
    final color = _parseColor(category.colorHex);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Column(
      key: ValueKey(category.id),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Category Name
        Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        // Amount
        Text(
          '$currencySymbol${_formatAmount(category.amount)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        // Percentage Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.categories.fold<double>(0, (sum, c) => sum + c.amount);

    if (widget.categories.isEmpty || total == 0) {
      return SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _EmptyDonutPainter(),
        ),
      );
    }

    final categoryColors = widget.categories
        .map((c) => _parseColor(c.colorHex))
        .toList();
    final values = widget.categories.map((c) => c.amount).toList();

    const chartSize = Size(220, 220);

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Donut Chart with raw touch listener
          Listener(
            onPointerDown: (e) => _onPointerDown(e, chartSize, total),
            onPointerMove: (e) => _onPointerMove(e, chartSize, total),
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: CustomPaint(
              size: chartSize,
              painter: _ExactCustomDonutPainter(
                colors: categoryColors,
                values: values,
                selectedIndex: _selectedIndex,
              ),
            ),
          ),

          // Center Display for Amount and Percentage
          IgnorePointer(
            child: SizedBox(
              width: 104,
              height: 104,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.88, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _selectedIndex != null &&
                          _selectedIndex! < widget.categories.length
                      ? _buildCenterInfo(
                          widget.categories[_selectedIndex!],
                          total,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExactCustomDonutPainter extends CustomPainter {
  _ExactCustomDonutPainter({
    required this.colors,
    required this.values,
    this.selectedIndex,
  });

  final List<Color> colors;
  final List<double> values;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, val) => sum + val);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    const outerRadius = 92.0;
    const thickness = 34.0;
    const innerRadius = outerRadius - thickness; // 58.0

    // Effective arc radii for raw path (accounting for 4.0px stroke offset)
    const drawOuterR = outerRadius - 2.0; // 90.0
    const drawInnerR = innerRadius + 2.0; // 60.0

    // Desired visible gap between sectors = 4.0px.
    const gapOuterAngle = 8.0 / drawOuterR; // Angle gap at outer radius
    const gapInnerAngle = 8.0 / drawInnerR; // Angle gap at inner radius

    // Start angle for Orange segment (top-right orientation)
    var startAngle = -pi / 2 + 0.08;

    for (var i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * (2 * pi);
      if (sweepAngle <= 0) continue;

      final baseColor = colors[i % colors.length];
      final isSelected = selectedIndex == i;
      final isAnySelected = selectedIndex != null;

      // Dim non-selected segments to focus on the selected segment
      final color = isAnySelected
          ? (isSelected ? baseColor : baseColor.withValues(alpha: 0.32))
          : baseColor;

      final aEnd = startAngle + sweepAngle;

      final a1Outer = startAngle + gapOuterAngle / 2;
      final a2Outer = aEnd - gapOuterAngle / 2;
      final sweepOuter = a2Outer - a1Outer;

      final a1Inner = startAngle + gapInnerAngle / 2;
      final a2Inner = aEnd - gapInnerAngle / 2;

      final effectiveOuterR = isSelected ? (drawOuterR + 3.0) : drawOuterR;
      final effectiveInnerR = isSelected ? (drawInnerR - 1.0) : drawInnerR;

      if (sweepOuter > 0 && (a2Inner > a1Inner)) {
        final path = Path()
          // 1. Outer Arc from a1Outer to a2Outer
          ..arcTo(
            Rect.fromCircle(center: center, radius: effectiveOuterR),
            a1Outer,
            sweepOuter,
            false,
          );

        // 2. Line to inner end point
        final innerX2 = center.dx + effectiveInnerR * cos(a2Inner);
        final innerY2 = center.dy + effectiveInnerR * sin(a2Inner);
        path
          ..lineTo(innerX2, innerY2)
          // 3. Inner Arc from a2Inner back to a1Inner (counter-clockwise)
          ..arcTo(
            Rect.fromCircle(center: center, radius: effectiveInnerR),
            a2Inner,
            a1Inner - a2Inner,
            false,
          )
          // 4. Close path
          ..close();

        // Fill paint
        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = color;
        canvas.drawPath(path, fillPaint);

        // Stroke paint with 4.0px width and StrokeJoin.round for smooth 2px rounded corners
        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..strokeJoin = StrokeJoin.round
          ..color = color;
        canvas.drawPath(path, strokePaint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ExactCustomDonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _EmptyDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const outerRadius = 92.0;
    const thickness = 34.0;
    const innerRadius = outerRadius - thickness; // 58.0

    // Average radius for the stroke to be centered
    const drawRadius = (outerRadius + innerRadius) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = const Color(0xFFF0F0F0); // Light grey for empty state

    canvas.drawCircle(center, drawRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
