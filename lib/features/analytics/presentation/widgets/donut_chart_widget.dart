import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';

class DonutChartWidget extends StatelessWidget {
  const DonutChartWidget({
    required this.categories,
    super.key,
  });

  final List<CategorySpendModel> categories;

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(0, (sum, c) => sum + c.amount);
    
    if (categories.isEmpty || total == 0) {
      return SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _EmptyDonutPainter(),
        ),
      );
    }

    final categoryColors = categories
        .map((c) => _parseColor(c.colorHex))
        .toList();
    final values = categories.map((c) => c.amount).toList();

    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _ExactCustomDonutPainter(
          colors: categoryColors,
          values: values,
        ),
      ),
    );
  }
}

class _ExactCustomDonutPainter extends CustomPainter {
  _ExactCustomDonutPainter({
    required this.colors,
    required this.values,
  });

  final List<Color> colors;
  final List<double> values;

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
    // 4.0px stroke with StrokeJoin.round expands path by 2.0px on all sides.
    // So raw path gap required = 4.0 + 4.0 = 8.0px.
    const gapOuterAngle = 8.0 / drawOuterR; // Angle gap at outer radius
    const gapInnerAngle = 8.0 / drawInnerR; // Angle gap at inner radius

    // Start angle for Orange segment (top-right orientation)
    var startAngle = -pi / 2 + 0.08;

    for (var i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * (2 * pi);
      if (sweepAngle <= 0) continue;

      final color = colors[i % colors.length];

      final aEnd = startAngle + sweepAngle;

      final a1Outer = startAngle + gapOuterAngle / 2;
      final a2Outer = aEnd - gapOuterAngle / 2;
      final sweepOuter = a2Outer - a1Outer;

      final a1Inner = startAngle + gapInnerAngle / 2;
      final a2Inner = aEnd - gapInnerAngle / 2;

      if (sweepOuter > 0 && (a2Inner > a1Inner)) {
        final path = Path()
          // 1. Outer Arc from a1Outer to a2Outer
          ..arcTo(
            Rect.fromCircle(center: center, radius: drawOuterR),
            a1Outer,
            sweepOuter,
            false,
          );

        // 2. Line to inner end point
        final innerX2 = center.dx + drawInnerR * cos(a2Inner);
        final innerY2 = center.dy + drawInnerR * sin(a2Inner);
        path
          ..lineTo(innerX2, innerY2)
          // 3. Inner Arc from a2Inner back to a1Inner (counter-clockwise)
          ..arcTo(
            Rect.fromCircle(center: center, radius: drawInnerR),
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
    return oldDelegate.values != values || oldDelegate.colors != colors;
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

