import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.emerald,
      onPrimary: AppColors.white,
      secondary: AppColors.brightGreen,
      onSecondary: AppColors.deepNavy,
      surface: AppColors.cardSurface,
      onSurface: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      outline: AppColors.warmGray,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffold,
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.h2.copyWith(fontSize: 18),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const Border(
          bottom: BorderSide(color: Color(0x1AFFFFFF)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBar,
        indicatorColor: AppColors.emerald.withValues(alpha: 0.25),
        height: AppSpacing.nav,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.brightGreen,
            );
          }
          return AppTypography.caption.copyWith(color: AppColors.warmGray);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.brightGreen, size: 24);
          }
          return const IconThemeData(color: AppColors.warmGray, size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.warmGray),
        labelStyle: AppTypography.h3,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.smMd,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.emerald, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.mediumGray,
          disabledForegroundColor: AppColors.offWhite,
          minimumSize: const Size(0, AppSpacing.nav),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.mdLg,
          ),
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBorder),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emerald,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.smMd,
          ),
          textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColors.emerald, width: 2),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brightGreen,
          textStyle: AppTypography.link,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkTeal,
        labelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.softMint,
        ),
        side: const BorderSide(color: AppColors.emerald),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepNavy,
        contentTextStyle: AppTypography.bodySmall.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
        titleTextStyle: AppTypography.h2,
        contentTextStyle: AppTypography.body,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brightGreen,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald,
        foregroundColor: AppColors.white,
        elevation: 4,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brightGreen,
        unselectedLabelColor: AppColors.warmGray,
        indicatorColor: AppColors.emerald,
        labelStyle: AppTypography.h3,
        unselectedLabelStyle: AppTypography.h3.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// Alias historique — l'app utilise le thème sombre par défaut.
  static ThemeData get light => dark;
}
