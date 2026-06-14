import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../data/finance_repository.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(supabaseClientProvider));
});

final publishedReportsProvider = FutureProvider((ref) async {
  return ref.read(financeRepositoryProvider).fetchPublishedReports();
});

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(publishedReportsProvider);
    final currency = NumberFormat.currency(locale: 'fr_GN', symbol: 'GNF ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Finances', style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: AsyncValueWidget(
          value: reportsAsync,
          empty: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text('Aucun bilan publié pour le moment.', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          data: (reports) => ListView.builder(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.xl,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final balance = report.totalIncome - report.totalExpense;
              final isPositive = balance >= 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AeemgCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_long, color: AppColors.gold),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bilan ${report.month}/${report.year}',
                                  style: AppTypography.h3.copyWith(color: AppColors.gold),
                                ),
                                Text(
                                  'Rapport mensuel',
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(color: AppColors.textTertiary, thickness: 0.3),
                      const SizedBox(height: AppSpacing.md),
                      _FinanceRow(
                        label: 'Entrées',
                        value: currency.format(report.totalIncome),
                        icon: Icons.trending_up,
                        color: AppColors.emerald,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _FinanceRow(
                        label: 'Dépenses',
                        value: currency.format(report.totalExpense),
                        icon: Icons.trending_down,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: AppColors.textTertiary, thickness: 0.3),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Solde net', style: AppTypography.h3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: (isPositive ? AppColors.emerald : AppColors.error).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: (isPositive ? AppColors.emerald : AppColors.error).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              currency.format(report.balance),
                              style: AppTypography.h3.copyWith(
                                color: isPositive ? AppColors.emerald : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 100 * index)).fade().slideY(begin: 0.1),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.body.copyWith(color: AppColors.textSecondary))),
        Text(value, style: AppTypography.body.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
