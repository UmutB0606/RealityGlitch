import 'dart:math';

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Digital crosshair overlay: corner brackets, a center cross and a slow
/// rotating scan arc, drawn over the live camera preview.
class ScannerReticle extends StatefulWidget {
  const ScannerReticle({super.key, this.size = 260});

  final double size;

  @override
  State<ScannerReticle> createState() => _ScannerReticleState();
}

class _ScannerReticleState extends State<ScannerReticle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(painter: _ReticlePainter(progress: _controller.value)),
        ),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  _ReticlePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final cornerLen = size.width * 0.14;

    final bracketPaint = Paint()
      ..color = AppColors.toxicGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    _drawCorner(canvas, Offset.zero, cornerLen, bracketPaint, right: true, down: true);
    _drawCorner(canvas, Offset(size.width, 0), cornerLen, bracketPaint, right: false, down: true);
    _drawCorner(canvas, Offset(0, size.height), cornerLen, bracketPaint, right: true, down: false);
    _drawCorner(canvas, Offset(size.width, size.height), cornerLen, bracketPaint, right: false, down: false);

    final crossPaint = Paint()
      ..color = AppColors.neonRed
      ..strokeWidth = 1.4;
    canvas.drawLine(center - const Offset(14, 0), center + const Offset(14, 0), crossPaint);
    canvas.drawLine(center - const Offset(0, 14), center + const Offset(0, 14), crossPaint);

    final arcPaint = Paint()
      ..color = AppColors.toxicGreen.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      progress * 2 * pi,
      pi / 3,
      false,
      arcPaint,
    );

    final circlePaint = Paint()
      ..color = AppColors.toxicGreen.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 4, circlePaint);
  }

  void _drawCorner(Canvas canvas, Offset corner, double len, Paint paint, {required bool right, required bool down}) {
    final dx = right ? len : -len;
    final dy = down ? len : -len;
    canvas.drawLine(corner, corner + Offset(dx, 0), paint);
    canvas.drawLine(corner, corner + Offset(0, dy), paint);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) => oldDelegate.progress != progress;
}
