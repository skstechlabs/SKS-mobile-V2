import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Spiritual Color Palette
  static const Color saffron = Color(0xFFFF9933);
  static const Color lightSaffron = Color(0xFFFFB366);
  static const Color beige = Color(0xFFF5E6D3);
  static const Color white = Color(0xFFFFFBF5);
  static const Color gold = Color(0xFFD4AF37);
  static const Color darkBrown = Color(0xFF4A3728);
  static const Color softGray = Color(0xFFE8E0D5);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: saffron,
      scaffoldBackgroundColor: white,
      
      colorScheme: ColorScheme.light(
        primary: saffron,
        secondary: gold,
        surface: white,
        background: beige,
        onPrimary: Colors.white,
        onSecondary: darkBrown,
        onSurface: darkBrown,
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkBrown,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: darkBrown,
        ),
        headlineMedium: GoogleFonts.lora(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkBrown,
        ),
        titleLarge: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkBrown,
        ),
        bodyLarge: GoogleFonts.openSans(
          fontSize: 16,
          color: darkBrown,
        ),
        bodyMedium: GoogleFonts.openSans(
          fontSize: 14,
          color: darkBrown,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: darkBrown),
        titleTextStyle: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkBrown,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: white,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  static LinearGradient get spiritualGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      beige,
      white,
      softGray.withOpacity(0.3),
    ],
  );
  
  static LinearGradient get saffronGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      saffron,
      lightSaffron,
    ],
  );
  
  static BoxShadow get softShadow => BoxShadow(
    color: darkBrown.withOpacity(0.08),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  
  static BoxShadow get glowShadow => BoxShadow(
    color: gold.withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );
}
