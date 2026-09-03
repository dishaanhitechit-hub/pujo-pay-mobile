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

  // Feature tile accents — one per functional area, reused across home and menus
  static const blue   = Color(0xFF3B82F6);
  static const teal   = Color(0xFF14B8A6);
  static const purple = Color(0xFF8B5CF6);
  static const green  = Color(0xFF10B981);
  static const indigo = Color(0xFF6366F1);
  static const pink   = Color(0xFFEC4899);
  static const amber  = Color(0xFFF59E0B);
  static const cyan   = Color(0xFF06B6D4);
  static const rose   = Color(0xFFF43F5E);
}

/// Layout constants shared across screens, so cards and grids line up
/// instead of each screen inventing its own spacing.
class AppSpacing {
  static const page    = 16.0;
  static const gutter  = 12.0;
  static const section = 24.0;
}

class AppRadii {
  static const card = 18.0;
  static const tile = 16.0;
  static const pill = 999.0;
}

/// Soft elevation instead of hard borders — the cards read as raised surfaces.
class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2,  offset: Offset(0, 1)),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 22, offset: Offset(0, 8)),
  ];
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
