import 'package:flutter/material.dart';

/// Bộ đôi bóng tennis + pickleball nảy so le nhau — điểm nhấn vui cho màn chào.
class BouncingBalls extends StatefulWidget {
  const BouncingBalls({super.key, this.ballSize = 82});

  final double ballSize;

  @override
  State<BouncingBalls> createState() => _BouncingBallsState();
}

class _BouncingBallsState extends State<BouncingBalls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.ballSize;
    return SizedBox(
      height: s * 1.65,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Ball(size: s, lift: t, painter: _TennisBallPainter()),
              SizedBox(width: s * 0.3),
              _Ball(size: s * 0.9, lift: 1 - t, painter: _PickleballPainter()),
            ],
          );
        },
      ),
    );
  }
}

class _Ball extends StatelessWidget {
  const _Ball({required this.size, required this.lift, required this.painter});

  final double size;
  final double lift; // 0 = chạm đất, 1 = cao nhất
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.5,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: size * (0.6 - 0.22 * lift),
            height: size * 0.12,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15 - 0.09 * lift),
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Positioned(
            bottom: size * 0.16 + size * 0.32 * lift,
            child: CustomPaint(size: Size.square(size), painter: painter),
          ),
        ],
      ),
    );
  }
}

class _TennisBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final ball = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.45),
          colors: [Color(0xFFF1FF63), Color(0xFFB6E62E), Color(0xFF87BB1F)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(ball),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(ball));
    final seam = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.60, c.dy - r * 0.80)
        ..quadraticBezierTo(
            c.dx - r * 0.02, c.dy - r * 0.30, c.dx - r * 0.60, c.dy + r * 0.80),
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + r * 0.60, c.dy - r * 0.80)
        ..quadraticBezierTo(
            c.dx + r * 0.02, c.dy - r * 0.30, c.dx + r * 0.60, c.dy + r * 0.80),
      seam,
    );
    canvas.restore();

    canvas.drawCircle(Offset(c.dx - r * 0.36, c.dy - r * 0.42), r * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PickleballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final ball = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.45),
          colors: [Color(0xFFFFE45C), Color(0xFFFFC21E), Color(0xFFE79A00)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(ball),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(ball));
    final hole = Paint()..color = const Color(0x3A5A3D00);
    const holes = [
      Offset(0.0, -0.02),
      Offset(-0.48, -0.34),
      Offset(0.46, -0.36),
      Offset(-0.54, 0.3),
      Offset(0.5, 0.32),
      Offset(-0.02, 0.6),
      Offset(0.04, -0.7),
    ];
    for (final h in holes) {
      canvas.drawCircle(Offset(c.dx + h.dx * r, c.dy + h.dy * r), r * 0.15, hole);
    }
    canvas.restore();

    canvas.drawCircle(Offset(c.dx - r * 0.36, c.dy - r * 0.42), r * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.22));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
