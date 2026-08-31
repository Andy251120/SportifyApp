import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Nền "sân chơi": gradient xanh sân + vợt, bóng tennis/pickleball mờ và
/// đường line sân cong. Dùng chung cho login, onboarding, splash...
class PlayfulBackground extends StatelessWidget {
  const PlayfulBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF5FAF46)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _DecorPainter(),
          child: child,
        ),
      ),
    );
  }
}

class _DecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Khối tròn mềm làm nền
    canvas.drawCircle(Offset(w * 0.9, h * 0.05), w * 0.42,
        Paint()..color = Colors.white.withValues(alpha: 0.05));
    canvas.drawCircle(Offset(w * 0.0, h * 0.24), w * 0.26,
        Paint()..color = Colors.white.withValues(alpha: 0.045));

    // Vợt mờ ở hai góc
    _racket(canvas, Offset(w * 0.14, h * 0.9), w * 0.0042, -28,
        Colors.white.withValues(alpha: 0.07));
    _racket(canvas, Offset(w * 0.92, h * 0.14), w * 0.0034, 34,
        Colors.white.withValues(alpha: 0.055));

    // Bóng nhỏ rải rác
    _dot(canvas, Offset(w * 0.82, h * 0.44), w * 0.05, const Color(0xFFF1FF63), 0.14);
    _dot(canvas, Offset(w * 0.1, h * 0.6), w * 0.035, const Color(0xFFFFC21E), 0.14);
    _dot(canvas, Offset(w * 0.7, h * 0.86), w * 0.028, const Color(0xFFF1FF63), 0.12);

    // Line sân cong
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final rad in [w * 0.95, w * 0.62]) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 1.2), radius: rad),
        math.pi,
        math.pi,
        false,
        line,
      );
    }
  }

  void _dot(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: opacity));
  }

  void _racket(Canvas canvas, Offset center, double s, double angleDeg, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDeg * math.pi / 180);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * s
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s;

    final head = Rect.fromCenter(
        center: Offset(0, -70 * s), width: 95 * s, height: 130 * s);
    canvas.drawOval(head, stroke);

    canvas.save();
    canvas.clipPath(Path()..addOval(head));
    for (var i = -3; i <= 3; i++) {
      canvas.drawLine(
          Offset(i * 14.0 * s, -140 * s), Offset(i * 14.0 * s, 0), thin);
      canvas.drawLine(
          Offset(-60 * s, -70 * s + i * 18.0 * s),
          Offset(60 * s, -70 * s + i * 18.0 * s),
          thin);
    }
    canvas.restore();

    canvas.drawLine(const Offset(0, 0), Offset(0, 80 * s), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
