import 'package:flutter/material.dart';

class AppTheme {
  // Spiritual Color Palette - Updated to match design mockups
  static const Color primary = Color(0xFFF97316); // Orange-500
  static const Color saffron = Color(0xFFF97316); // Orange-500
  static const Color lightSaffron = Color(0xFFFB923C); // Orange-400
  static const Color beige = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF); // Pure white background
  static const Color gold = Color(0xFFF97316); // Orange-500
  static const Color darkBrown = Color(0xFF000000); // Black for text
  static const Color softGray = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: saffron,
      scaffoldBackgroundColor: white,
      
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: white,
        onPrimary: Colors.white,
        onSecondary: white,
        onSurface: textPrimary,
      ),
      
      fontFamily: '.AppleSystemUIFont',
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: white,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
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
      softGray.withValues(alpha: 0.3),
    ],
  );
  
  static LinearGradient get saffronGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      Color(0xFFFF8A6B),
      Color(0xFFFFA891),
    ],
  );
  
  static BoxShadow get softShadow => BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  
  static BoxShadow get glowShadow => BoxShadow(
    color: primary.withOpacity(0.2),
    blurRadius: 20,
    spreadRadius: 2,
  );
}
