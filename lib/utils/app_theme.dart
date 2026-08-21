import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Core palette for RealityGlitch's dark, cyberpunk/hacker visual identity.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color nearBlack = Color(0xFF0A0A0A);
  static const Color neonRed = Color(0xFFFF003C);
  static const Color toxicGreen = Color(0xFF39FF14);
  static const Color dimGreen = Color(0xFF163D16);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.shareTechMonoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.toxicGreen,
      displayColor: AppColors.toxicGreen,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.toxicGreen,
        secondary: AppColors.neonRed,
        surface: AppColors.black,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        elevation: 0,
        titleTextStyle: GoogleFonts.shareTechMono(
          color: AppColors.toxicGreen,
          fontSize: 20,
          letterSpacing: 2,
        ),
      ),
      dividerColor: AppColors.dimGreen,
    );
  }
}
