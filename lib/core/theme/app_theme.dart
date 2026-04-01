import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens (from Pencil design variables) ───────────────────────────
abstract class AppColors {
  // Primary
  static const primary = Color(0xFFE53935);
  static const primaryDark = Color(0xFFB71C1C);
  static const primarySoft = Color(0xFFFFEBEE);
  static const primarySurface = Color(0xFFFFF5F5);

  // Backgrounds
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const surface2 = Color(0xFFFFF5F5);

  // Text
  static const text1 = Color(0xFF1A1A1A);
  static const text2 = Color(0xFF757575);
  static const text3 = Color(0xFFBDBDBD);

  // Borders
  static const border = Color(0xFFEEEEEE);

  // Green (success)
  static const green = Color(0xFF2E7D32);
  static const greenSoft = Color(0xFFE8F5E9);

  // Category Colors
  static const catBlue = Color(0xFFE3F2FD);
  static const catBlueDark = Color(0xFF1565C0);
  static const catOrange = Color(0xFFFFF3E0);
  static const catOrangeDark = Color(0xFFE65100);
  static const catPink = Color(0xFFFCE4EC);
  static const catPinkDark = Color(0xFF880E4F);
  static const catPurple = Color(0xFFF3E5F5);
  static const catPurpleDark = Color(0xFF6A1B9A);
  static const catGreen = Color(0xFFE8F5E9);
  static const catGreenDark = Color(0xFF2E7D32);

  // Semantic
  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFF57F17);
  static const info = Color(0xFF1565C0);

  // Shadow
  static const shadow = Color(0x1A000000);
  static const shadowLight = Color(0x0F000000);
}

abstract class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double card = 16;
  static const double btn = 12;
  static const double pill = 100;
}

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double screenH = 20.0; // horizontal screen padding
}

abstract class AppTextStyles {
  static TextStyle display({Color color = AppColors.text1}) => GoogleFonts.plusJakartaSans(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: color,
    height: 1.1,
  );

  static TextStyle h1({Color color = AppColors.text1}) => GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: color,
    height: 1.2,
  );

  static TextStyle h2({Color color = AppColors.text1}) => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: color,
    height: 1.2,
  );

  static TextStyle h3({Color color = AppColors.text1}) => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle h4({Color color = AppColors.text1}) => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle title({Color color = AppColors.text1}) => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle bodyLarge({Color color = AppColors.text1}) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle body({Color color = AppColors.text2}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodyBold({Color color = AppColors.text1}) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle caption({Color color = AppColors.text2}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle captionBold({Color color = AppColors.text1}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle label({Color color = AppColors.text3}) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.5,
  );

  static TextStyle price({Color color = AppColors.primary}) => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle priceLarge({Color color = AppColors.primary}) => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: color,
  );

  static TextStyle navLabel({Color color = AppColors.text3}) => GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.5,
  );
}

// ─── Theme ───────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primarySoft,
      secondary: AppColors.green,
      error: AppColors.error,
      surface: AppColors.bg,
      onPrimary: Colors.white,
      onSurface: AppColors.text1,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.text1,
      ),
      iconTheme: const IconThemeData(color: AppColors.text1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppTextStyles.body(color: AppColors.text3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        minimumSize: const Size(double.infinity, 54),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.text3,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static SystemUiOverlayStyle get systemUiOverlay => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}

// ─── Box Shadows ─────────────────────────────────────────────────────────────
abstract class AppShadows {
  static List<BoxShadow> get card => [
    const BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevated => [
    const BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get soft => [
    const BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get nav => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];
}
