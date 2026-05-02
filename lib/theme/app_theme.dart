import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF12182E);
  static const Color surfaceAlt = Color(0xFF0D1525);
  static const Color card = Color(0xFF12182E);
  static const Color cardHighlight = Color(0xFF0F1635);
  static const Color border = Color(0xFF1E2540);
  static const Color borderAlt = Color(0xFF2A3060);

  static const Color primary = Color(0xFF3B5BF5);
  static const Color primaryDark = Color(0xFF2A44D4);

  static const Color textPrimary = Color(0xFFE8EAF2);
  static const Color textSecondary = Color(0xFF7B82A8);
  static const Color textMuted = Color(0xFF4A5070);

  static const Color green = Color(0xFF4ADE80);
  static const Color greenBg = Color(0xFF0F2D1A);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberBg = Color(0xFF2D2000);
  static const Color blue = Color(0xFF60A5FA);
  static const Color blueBg = Color(0xFF001A2D);
  static const Color red = Color(0xFFF87171);
  static const Color redBg = Color(0xFF2D0F0F);

  static const Color pttColor = Color(0xFF4ADE80);
  static const Color pttBg = Color(0xFF1A3A1A);
  static const Color shellColor = Color(0xFFF59E0B);
  static const Color shellBg = Color(0xFF2D2000);
  static const Color bcpColor = Color(0xFF60A5FA);
  static const Color bcpBg = Color(0xFF001A2D);
  static const Color ptColor = Color(0xFFF87171);
  static const Color ptBg = Color(0xFF2D0A0A);

  static ThemeData get darkTheme {
    // ใช้ Sarabun — รองรับภาษาไทยครบถ้วน
    final textTheme = GoogleFonts.sarabunTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      // กำหนด font family ผ่าน GoogleFonts ด้วย เพื่อ fallback ครบ
      fontFamily: GoogleFonts.sarabun().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sarabun(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceAlt,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            GoogleFonts.sarabun(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.sarabun(fontSize: 11),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle:
            GoogleFonts.sarabun(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.sarabun(fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.sarabun(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.sarabun(color: textSecondary),
      ),
    );
  }
}
