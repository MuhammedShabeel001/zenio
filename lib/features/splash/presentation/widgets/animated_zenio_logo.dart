import 'package:flutter/material.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

/// A cinema-grade logo reveal animation for Zenio:
/// 1. Smooth scale-up and clip-wipe reveal.
/// 2. Diagonal specular light beam sweep (shine) across the Z and O glyphs.
/// 3. A subtle luxury specular diamond glint as the light crosses the emerald O.
class AnimatedZenioLogo extends StatefulWidget {
  const AnimatedZenioLogo({
    required this.animation,
    this.width = 140,
    this.height = 148,
    super.key,
  });

  final Animation<double> animation;
  final double width;
  final double height;

  @override
  State<AnimatedZenioLogo> createState() => _AnimatedZenioLogoState();
}

class _AnimatedZenioLogoState extends State<AnimatedZenioLogo> {
  late final Animation<double> _revealProgress;
  late final Animation<double> _scaleProgress;
  late final Animation<double> _shineProgress;
  late final Animation<double> _glintProgress;

  @override
  void initState() {
    super.initState();

    // 1. Initial fade and clip reveal (0.0 -> 0.45)
    _revealProgress = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0, 0.45, curve: Curves.easeOutCubic),
    );

    // 2. Subtle luxury scale settle (0.0 -> 0.6)
    _scaleProgress = Tween<double>(begin: 0.90, end: 1).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Diagonal light sweep (shine) across the logo (0.35 -> 0.85)
    _shineProgress = Tween<double>(begin: -0.6, end: 1.6).animate(
      CurvedAnimation(
        parent: widget.animation,
        curve: const Interval(0.35, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Subtle specular diamond glint on the emerald O shoulder (0.6 -> 0.85)
    _glintProgress = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final revealVal = _revealProgress.value;
        final scaleVal = _scaleProgress.value;
        final shineVal = _shineProgress.value;
        final glintVal = _glintProgress.value;

        // Glint scale and opacity: fades in fast, then fades out
        final double glintOpacity;
        final double glintScale;
        if (glintVal <= 0.4) {
          glintOpacity = (glintVal / 0.4).clamp(0, 1);
          glintScale = (glintVal / 0.4) * 1.1;
        } else {
          glintOpacity = (1.0 - (glintVal - 0.4) / 0.6).clamp(0, 1);
          glintScale = 1.1 - (glintVal - 0.4) * 0.3;
        }

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Transform.scale(
            scale: scaleVal,
            child: Opacity(
              opacity: revealVal.clamp(0, 1),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Base SVG Logo
                  Assets.images.appLogo.svg(
                    width: widget.width,
                    height: widget.height,
                  ),

                  // Cinema Specular Light Sweep (Shine)
                  if (widget.animation.value >= 0.35 &&
                      widget.animation.value <= 0.90)
                    Positioned.fill(
                      child: ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(shineVal - 1.2, -1),
                            end: Alignment(shineVal + 0.3, 1),
                            colors: const [
                              Colors.transparent,
                              Color(0x33FFFFFF),
                              Color(0xD9FFFFFF),
                              Color(0x33FFFFFF),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.38, 0.5, 0.62, 1],
                          ).createShader(bounds);
                        },
                        child: Assets.images.appLogo.svg(
                          width: widget.width,
                          height: widget.height,
                        ),
                      ),
                    ),

                  // Specular Diamond Glint on the emerald ring
                  if (glintOpacity > 0.01)
                    Positioned(
                      // Position corresponding to top right highlight curve of the 'O'
                      right: widget.width * 0.16,
                      top: widget.height * 0.26,
                      child: Opacity(
                        opacity: glintOpacity,
                        child: Transform.scale(
                          scale: glintScale,
                          child: const _DiamondGlint(size: 24),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A precision 4-point specular diamond star glint
class _DiamondGlint extends StatelessWidget {
  const _DiamondGlint({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlintPainter(),
      ),
    );
  }
}

class _GlintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final primaryPaint = Paint()
      ..color = const Color(0xFFE6FFFA)
      ..style = PaintingStyle.fill;

    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 4-point star path
    const beamRatio = 0.16; // width ratio of beam waist
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + radius * beamRatio,
        center.dy - radius * beamRatio,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + radius * beamRatio,
        center.dy + radius * beamRatio,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - radius * beamRatio,
        center.dy + radius * beamRatio,
        center.dx - radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - radius * beamRatio,
        center.dy - radius * beamRatio,
        center.dx,
        center.dy - radius,
      )
      ..close();

    canvas
      ..drawPath(path, primaryPaint)
      // Core bright point
      ..drawCircle(center, radius * 0.22, corePaint);

    // Subtle 45-deg smaller cross
    final crossPaint = Paint()
      ..color = const Color(0x99A7F3D0)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final diag = radius * 0.45;
    canvas
      ..drawLine(
        Offset(center.dx - diag, center.dy - diag),
        Offset(center.dx + diag, center.dy + diag),
        crossPaint,
      )
      ..drawLine(
        Offset(center.dx - diag, center.dy + diag),
        Offset(center.dx + diag, center.dy - diag),
        crossPaint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
