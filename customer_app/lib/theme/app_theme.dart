import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E40AF);

  // Secondary Colors
  static const Color successGreen = Color(0xFF059669);
  static const Color warningOrange = Color(0xFFEA580C);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color infoBlue = Color(0xFF0284C7);

  // Neutral Scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Semantic Colors
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF3F4F6);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  static const Color borderDefault = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF2563EB);
  static const Color borderError = Color(0xFFDC2626);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundPrimary,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryLight,
        surface: backgroundPrimary,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 48, height: 1.2, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: TextStyle(fontSize: 36, height: 1.3, fontWeight: FontWeight.w600, color: textPrimary),
        displaySmall: TextStyle(fontSize: 30, height: 1.4, fontWeight: FontWeight.w600, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 24, height: 1.4, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, height: 1.5, fontWeight: FontWeight.w500, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w400, color: textSecondary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w400, color: textTertiary),
        labelLarge: TextStyle(fontSize: 16, height: 1.0, fontWeight: FontWeight.w600, color: Colors.white), // Button Large
        labelMedium: TextStyle(fontSize: 14, height: 1.0, fontWeight: FontWeight.w500, color: primaryBlue), // Button Medium
        labelSmall: TextStyle(fontSize: 12, height: 1.0, fontWeight: FontWeight.w500, color: textSecondary), // Button Small
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 1, // Level 1 equivalent
        shadowColor: Color(0x3D000000), // ~0.24 opacity
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary, size: 24),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 1, // Level 1
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            height: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundPrimary,
        hintStyle: const TextStyle(color: gray400, fontSize: 16, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 16, fontWeight: FontWeight.w400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderDefault, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderDefault, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderError, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderError, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundPrimary,
        elevation: 1,
        shadowColor: const Color(0x3D000000), // ~0.24 opacity
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderDefault),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
