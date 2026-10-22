import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_hero.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_page.dart';
import '../../../shared/widgets/ds/aeemg_section.dart';
import '../data/finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(supabaseClientProvider));
});

final publishedReportsProvider = FutureProvider((ref) async {
  return ref.read(financeRepositoryProvider).fetchPublishedReports();
});

final _currency = NumberFormat.currency(
  locale: 'fr_GN',
  symbol: 'GNF ',
  decimalDigits: 0,
);

/// « septembre 2026 » → « Septembre 2026 ».
String _monthLabel(MonthlyReport report) {
  final label = DateFormat(
    'MMMM yyyy',
    'fr',
  ).format(DateTime(report.year, report.month));
  return label[0].toUpperCase() + label.substring(1);
}

Color _balanceTint(double balance) =>
    balance >= 0 ? AppColors.brightGreen : AppColors.error;

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> content = ref
        .watch(publishedReportsProvider)
        .when(
          loading: () => const [
            AeemgSkeleton(height: 180, radius: AppRadius.hero),
            SizedBox(height: AppSpacing.md),
            AeemgSkeletonTile(),
          ],
          error: (error, _) => [
            AeemgEmptyState(
              compact: true,
              icon: Icons.cloud_off_outlined,
              title: 'Bilans indisponibles',
              message: friendlySupabaseError(error),
            ),
          ],
          data: (reports) => reports.isEmpty
              ? const [
                  AeemgEmptyState(
                    compact: true,
                    icon: Icons.account_balance_outlined,
                    title: 'Aucun bilan publié',
                    message: 'Les bilans mensuels apparaîtront ici.',
                  ),
                ]
              : [
                  _LatestReport(report: reports.first),
                  if (reports.length > 1) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const AeemgSectionHeader(title: 'Bilans précédents'),
                    for (final report in reports.skip(1))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ReportTile(report: report),
                      ),
                  ],
                ],
        );

    return AeemgPage(
      title: 'Finances',
      subtitle: 'Bilans mensuels publiés par la trésorerie.',
      onRefresh: () async => ref.invalidate(publishedReportsProvider),
      children: content,
    );
  }
}

/// Dernier bilan en bandeau : solde net en grand, entrées et dépenses, part dépensée.
class _LatestReport extends StatelessWidget {
  const _LatestReport({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final spent = report.totalIncome > 0
        ? (report.totalExpense / report.totalIncome).clamp(0.0, 1.0)
        : (report.totalExpense > 0 ? 1.0 : 0.0);
    return AeemgHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DERNIER BILAN · ${_monthLabel(report).toUpperCase()}',
            style: AppTypography.caption.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Solde net', style: AppTypography.bodySmall),
          Text(
            _currency.format(report.balance),
            style: AppTypography.h1.copyWith(
              color: _balanceTint(report.balance),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'Entrées',
                  value: _currency.format(report.totalIncome),
                  icon: Icons.trending_up_rounded,
                  tint: AppColors.brightGreen,
                ),
              ),
              Expanded(
                child: _Figure(
                  label: 'Dépenses',
                  value: _currency.format(report.totalExpense),
                  icon: Icons.trending_down_rounded,
                  tint: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'Part des entrées dépensée',
            value: '${(spent * 100).round()} %',
            child: ClipRRect(
              borderRadius: AppRadius.pillBorder,
              child: LinearProgressIndicator(
                value: spent,
                minHeight: 6,
                backgroundColor: AppColors.brightGreen.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(spent * 100).round()} % des entrées dépensées',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: tint, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              Text(
                value,
                style: AppTypography.h4.copyWith(color: tint),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bilan précédent : mois, entrées et dépenses, solde en pastille.
class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final tint = _balanceTint(report.balance);
    return AeemgCard(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_monthLabel(report), style: AppTypography.h4),
                const SizedBox(height: 2),
                Text(
                  '+${_currency.format(report.totalIncome)} · '
                  '−${_currency.format(report.totalExpense)}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: AppRadius.pillBorder,
              border: Border.all(color: tint.withValues(alpha: 0.35)),
            ),
            child: Text(
              _currency.format(report.balance),
              style: AppTypography.caption.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
