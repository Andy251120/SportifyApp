import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme theo đúng "Design direction" trong CLAUDE.md:
/// thân thiện, bo tròn, tương phản cao để đọc được ngoài trời.
class AppTheme {
  AppTheme._();

  // Màu chủ đạo: xanh sân (tennis court green) + cam bóng tennis làm accent.
  static const Color courtGreen = Color(0xFF2E7D32);
  static const Color tennisBallOrange = Color(0xFFFF7A00);
  static const Color pickleballBlue = Color(0xFF0288D1);

  // Token trung tính (theo UI_SPEC.md).
  static const Color scaffoldBg = Color(0xFFFAFAF7);
  static const Color textPrimary = Color(0xFF1C1C1A);
  static const Color textSecondary = Color(0xFF6B6A63);
  static const Color textMuted = Color(0xFF9C9A8F);
  static const Color surfaceMuted = Color(0xFFEFEDE4); // nền tab switcher
  static const Color borderSubtle = Color(0xFFE3E1D6); // lưới, viền nhạt

  static const double cardRadius = 20;
  static const double buttonRadius = 16;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: courtGreen,
        primary: courtGreen,
        secondary: tennisBallOrange,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.baloo2TextTheme(base.textTheme).copyWith(
        // Cỡ chữ lớn hơn mặc định một chút để dễ đọc ngoài trời.
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 17),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52), // nút to, dễ chạm 1 tay
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide.none,
        ),
      ),
      scaffoldBackgroundColor: scaffoldBg,
    );
  }

  /// Màu riêng theo môn cho tab switcher (tennis = xanh sân, pickleball = xanh dương).
  static Color sportColor(String sport) {
    return sport == 'pickleball' ? pickleballBlue : courtGreen;
  }

  /// Màu radar chart Show-off (tennis = cam bóng, pickleball = xanh dương) — theo UI_SPEC.
  static Color radarColor(String sport) {
    return sport == 'pickleball' ? pickleballBlue : tennisBallOrange;
  }
}