import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: KorraColors.text,
      displayColor: KorraColors.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: KorraColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: KorraColors.brand,
        secondary: KorraColors.brand,
        surface: KorraColors.bg,
      ),

      // Typography
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: KorraColors.bg,
        foregroundColor: KorraColors.text,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KorraColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: KorraColors.textMuted, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: KorraColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius),
          borderSide: BorderSide(color: KorraColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius),
          borderSide: BorderSide(color: KorraColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius),
          borderSide: const BorderSide(color: KorraColors.brand, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius),
          borderSide: const BorderSide(color: KorraColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KorraSizes.fieldRadius),
          borderSide: const BorderSide(color: KorraColors.danger),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KorraColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(KorraSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KorraSizes.fieldRadius),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KorraColors.brand,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KorraSizes.cardRadius),
          side: BorderSide(color: KorraColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // Dividers & chip accents
      dividerColor: KorraColors.border,
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: KorraColors.inputFill,
        labelStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: KorraColors.border),
        ),
      ),
    );
  }
}
