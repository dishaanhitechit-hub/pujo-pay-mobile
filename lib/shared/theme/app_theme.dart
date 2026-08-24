import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Content / backgrounds
  static const bg      = Color(0xFFF4F6F9);   // light gray page bg
  static const surface = Color(0xFFFFFFFF);   // white panels
  static const card    = Color(0xFFFFFFFF);   // white cards
  static const border  = Color(0xFFE2E8F0);   // subtle border

  // Navigation (dark navy — matches web sidebar)
  static const navBg   = Color(0xFF0D1B2A);

  // Accent (orange — matches web active highlight)
  static const accent  = Color(0xFFE8622A);
  static const accentL = Color(0x1AE8622A);   // 10% opacity tint

  // Text
  static const text    = Color(0xFF0F172A);   // near-black
  static const muted   = Color(0xFF64748B);   // slate gray

  // Semantic
  static const success = Color(0xFF10B981);
  static const danger  = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
}

ThemeData appTheme() {
  final base = ThemeData.light(useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary:   AppColors.accent,
      surface:   AppColors.surface,
      onPrimary: Colors.white,
      onSurface: AppColors.text,
    ),

    textTheme: GoogleFonts.jetBrainsMonoTextTheme(base.textTheme).apply(
      bodyColor:    AppColors.text,
      displayColor: AppColors.text,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.navBg,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     AppColors.navBg,
      selectedItemColor:   AppColors.accent,
      unselectedItemColor: Color(0xFF6B8BAA),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor:         AppColors.accent,
      unselectedLabelColor: Color(0xFF6B8BAA),
      indicatorColor:     AppColors.accent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    dividerColor: AppColors.border,
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accentL,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(color: AppColors.text, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
    ),
  );
}
