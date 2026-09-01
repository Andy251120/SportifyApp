import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bouncing_ball.dart';
import 'playful_background.dart';

/// Màn chờ có thương hiệu — dùng khi đang tải hồ sơ / khởi động.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlayfulBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BouncingBalls(ballSize: 76),
              const SizedBox(height: 8),
              Text(
                'Rally',
                style: GoogleFonts.fredoka(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
