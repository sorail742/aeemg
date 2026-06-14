import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'ds/aeemg_buttons.dart';

class PlaceholderSection extends StatelessWidget {
  const PlaceholderSection({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.phase,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? phase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.brightGreen),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.h1.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (phase != null) ...[
            const SizedBox(height: AppSpacing.md),
            AeemgSuccessBadge(label: phase!),
          ],
        ],
      ),
    );
  }
}
