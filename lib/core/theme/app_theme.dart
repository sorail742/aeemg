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
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.darkTeal,
      onPrimaryContainer: AppColors.lightEmerald,
      secondary: AppColors.gold,
      onSecondary: AppColors.deepNavy,
      surface: AppColors.cardSurface,
      onSurface: AppColors.white,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.cardSurfaceLight,
      error: AppColors.error,
      onError: AppColors.deepNavy,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    final interactiveShape = RoundedRectangleBorder(
      borderRadius: AppRadius.inputBorder,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.inputBorder,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffold,
      textTheme: AppTypography.textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.h3,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.emerald.withValues(alpha: 0.16),
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.brightGreen : AppColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.brightGreen : AppColors.textTertiary,
            size: 22,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.white,
        titleTextStyle: AppTypography.h4,
        subtitleTextStyle: AppTypography.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: interactiveShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
        labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.brightGreen,
        ),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.emerald, 1.5),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.cardSurfaceLight,
          disabledForegroundColor: AppColors.textTertiary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTypography.button,
          shape: interactiveShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTypography.button,
          shape: interactiveShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTypography.button,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          shape: interactiveShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brightGreen,
          textStyle: AppTypography.link,
          shape: interactiveShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardSurface,
        selectedColor: AppColors.emerald.withValues(alpha: 0.16),
        labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.white),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBorder),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardSurfaceLight,
        contentTextStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.white,
        ),
        actionTextColor: AppColors.brightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.inputBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTypography.h3,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.cardSurfaceLight,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTypography.body,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.inputBorder,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.emerald,
        linearTrackColor: AppColors.border,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.textTertiary,
        indicatorColor: AppColors.emerald,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
        labelStyle: AppTypography.h4,
        unselectedLabelStyle: AppTypography.h4.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.emerald
              : AppColors.cardSurfaceLight,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }

  /// Alias historique — l'app utilise le thème sombre par défaut.
  static ThemeData get light => dark;
}
