import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Échelle typographique resserrée (ratio ~1,2) : Outfit pour les titres, Inter pour le
/// texte, Amiri pour l'arabe. Les titres sont légèrement resserrés (letterSpacing négatif).
abstract final class AppTypography {
  static TextStyle get display => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.6,
    color: AppColors.white,
  );

  static TextStyle get h1 => GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
    color: AppColors.white,
  );

  static TextStyle get h2 => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColors.white,
  );

  static TextStyle get h3 => GoogleFonts.outfit(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.white,
  );

  static TextStyle get h4 => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.white,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textTertiary,
  );

  /// Libellé de section en capitales (« MON COMPTE »).
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.1,
    color: AppColors.textTertiary,
  );

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.white,
  );

  static TextStyle get link => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.brightGreen,
  );

  /// Texte coranique arabe.
  static TextStyle quranArabic({double size = 28}) => GoogleFonts.amiri(
    fontSize: size,
    fontWeight: FontWeight.w400,
    height: 2.1,
    color: AppColors.white,
  );

  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    displayMedium: h1,
    displaySmall: h2,
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    titleLarge: h2,
    titleMedium: h3,
    titleSmall: h4,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: bodySmall,
    labelLarge: button,
    labelMedium: h4,
    labelSmall: caption,
  );
}
