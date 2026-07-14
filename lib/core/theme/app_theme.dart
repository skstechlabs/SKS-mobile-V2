import 'package:flutter/material.dart';

/// SKS App Design System — based on the spiritual UI mockup
///
/// Palette extracted from the design:
///   Warm background:  #FEFAF4  (parchment/cream)
///   Card surface:     #FFFFFF  with soft shadow
///   Primary accent:   #C4622D  (warm terracotta/deep saffron)
///   Gold accent:      #D4A017  (sacred gold — from SKS logo)
///   Text primary:     #2C1810  (deep warm brown)
///   Text secondary:   #8B6B4E  (muted warm brown)
///   Divider/border:   #E8DDD0  (light warm gray)
///   Tag background:   #FFF3E8  (light saffron tint)
class AppTheme {
  // ── Core colors ────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFFC4622D);  // warm terracotta
  static const Color saffron       = Color(0xFFC4622D);  // alias
  static const Color lightSaffron  = Color(0xFFD4784A);  // lighter terracotta
  static const Color gold          = Color(0xFFD4A017);  // sacred gold
  static const Color cream         = Color(0xFFFEFAF4);  // parchment bg
  static const Color cardSurface   = Color(0xFFFFFFFF);
  static const Color beige         = Color(0xFFF5EDE2);  // warm beige tint
  static const Color white         = Color(0xFFFFFFFF);

  // ── Text colors ────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF2C1810);  // deep warm brown
  static const Color textSecondary = Color(0xFF8B6B4E);  // muted warm brown
  static const Color textHint      = Color(0xFFB89A82);  // lightest brown
  static const Color darkBrown     = Color(0xFF2C1810);

  // ── UI surface colors ──────────────────────────────────────────────────────
  static const Color softGray      = Color(0xFFE8DDD0);  // warm divider
  static const Color tagBg         = Color(0xFFFFF3E8);  // light saffron tint
  static const Color tagBorder     = Color(0xFFEDD5BC);
  static const Color inputBg       = Color(0xFFFDF6EE);  // input field bg

  // ── Gradients ──────────────────────────────────────────────────────────────
  static LinearGradient get bgGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFEFAF4), Color(0xFFF8F0E6)],
  );

  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4622D), Color(0xFFE07840)],
  );

  static LinearGradient get goldGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A017), Color(0xFFEDBB35)],
  );

  static LinearGradient get saffronGradient => primaryGradient;

  static LinearGradient get spiritualGradient => bgGradient;

  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF8F2)],
  );

  // ── Shadows ────────────────────────────────────────────────────────────────
  static BoxShadow get softShadow => BoxShadow(
    color: const Color(0xFF8B6B4E).withValues(alpha: 0.10),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static BoxShadow get cardShadow => BoxShadow(
    color: const Color(0xFF8B6B4E).withValues(alpha: 0.08),
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  );

  static BoxShadow get glowShadow => BoxShadow(
    color: primary.withValues(alpha: 0.25),
    blurRadius: 20,
    spreadRadius: 2,
  );

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: cream,

      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: gold,
        surface: cardSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),

      // Use a warm system font — Noto Serif or system default
      fontFamily: 'sans-serif',

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, color: textPrimary, height: 1.55,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, color: textSecondary, height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12, color: textHint,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primary,
          letterSpacing: 0.2,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: cardSurface,
        margin: const EdgeInsets.only(bottom: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardSurface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      dividerTheme: const DividerThemeData(
        color: softGray,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: tagBg,
        labelStyle: const TextStyle(
            color: primary, fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: tagBorder),
        ),
      ),
    );
  }
}
