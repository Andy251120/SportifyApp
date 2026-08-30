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
      scaffoldBackgroundColor: const Color(0xFFFAFAF7),
    );
  }

  /// Màu riêng theo môn, dùng để phân biệt tab Tennis/Pickleball ngay bằng mắt.
  static Color sportColor(String sport) {
    return sport == 'pickleball' ? pickleballBlue : courtGreen;
  }
}