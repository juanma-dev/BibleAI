import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        onPrimary: Colors.white,
        secondary: AppColors.goldLight,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        error: AppColors.error,
        outline: AppColors.lightBorder,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: _buildTextTheme(AppColors.lightText, AppColors.lightTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.lightBorder,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.cinzelDecorative(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.gold.withOpacity(0.15),
        labelStyle: GoogleFonts.lato(color: AppColors.lightText, fontSize: 13),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        hintStyle: GoogleFonts.lato(color: AppColors.lightTextTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldLight,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.gold,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        error: Color(0xFFCF6679),
        outline: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme(AppColors.darkText, AppColors.darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.darkBorder,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.cinzelDecorative(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedColor: AppColors.goldLight.withOpacity(0.15),
        labelStyle: GoogleFonts.lato(color: AppColors.darkText, fontSize: 13),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.goldLight, width: 2),
        ),
        hintStyle: GoogleFonts.lato(color: AppColors.darkTextTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldLight,
          foregroundColor: AppColors.darkBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.cinzelDecorative(
        color: primary, fontSize: 32, fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.cinzelDecorative(
        color: primary, fontSize: 26, fontWeight: FontWeight.w600,
      ),
      displaySmall: GoogleFonts.cinzelDecorative(
        color: primary, fontSize: 22, fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.lora(
        color: primary, fontSize: 20, fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.lora(
        color: primary, fontSize: 18, fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.lora(
        color: primary, fontSize: 16, fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.lato(
        color: primary, fontSize: 17, fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.lato(
        color: primary, fontSize: 15, fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.lato(
        color: secondary, fontSize: 13, fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.lora(
        color: primary, fontSize: 18, height: 1.8,
      ),
      bodyMedium: GoogleFonts.lora(
        color: primary, fontSize: 16, height: 1.75,
      ),
      bodySmall: GoogleFonts.lato(
        color: secondary, fontSize: 13, height: 1.5,
      ),
      labelLarge: GoogleFonts.lato(
        color: primary, fontSize: 14, fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.lato(
        color: secondary, fontSize: 12, fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.lato(
        color: secondary, fontSize: 11, letterSpacing: 0.5,
      ),
    );
  }
}
