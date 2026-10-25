import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'aeemg_motion.dart';

class AeemgPrimaryButton extends StatelessWidget {
  const AeemgPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    // v3 : dégradé émeraude et halo quand le bouton est actif. FilledButton est conservé
    // (focus, sémantique, état désactivé) avec un fond transparent.
    final enabled = onPressed != null && !isLoading;
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppGradients.primary : null,
        color: enabled ? null : AppColors.cardSurfaceLight,
        borderRadius: AppRadius.inputBorder,
        boxShadow: enabled ? AppShadows.glow : null,
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.transparent,
          disabledBackgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
        ),
        child: child,
      ),
    );

    if (expand) {
      return SizedBox(
        width: double.infinity,
        child: AeemgPressable(child: button),
      );
    }
    return AeemgPressable(child: button);
  }
}

class AeemgSecondaryButton extends StatelessWidget {
  const AeemgSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(label),
        ],
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

class AeemgSuccessBadge extends StatelessWidget {
  const AeemgSuccessBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.brightGreen,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.deepNavy,
        ),
      ),
    );
  }
}
