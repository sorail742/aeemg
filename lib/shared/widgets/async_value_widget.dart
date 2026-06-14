import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/supabase_errors.dart';
import 'ds/aeemg_card.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.empty,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(error: error),
      data: (d) {
        if (d is List && d.isEmpty && empty != null) return empty!;
        return data(d);
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final missingTable = isMissingTableError(error);
    final message = friendlySupabaseError(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AeemgCard(
          variant: AeemgCardVariant.accent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                missingTable ? Icons.storage_outlined : Icons.error_outline,
                color: missingTable ? AppColors.gold : AppColors.error,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                missingTable ? 'Configuration requise' : 'Une erreur est survenue',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
