import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../data/admin_repository.dart';

class AdminFinanceDialog extends ConsumerStatefulWidget {
  const AdminFinanceDialog({super.key, required this.repository, required this.onSuccess});
  
  final AdminRepository repository;
  final VoidCallback onSuccess;

  @override
  ConsumerState<AdminFinanceDialog> createState() => _AdminFinanceDialogState();
}

class _AdminFinanceDialogState extends ConsumerState<AdminFinanceDialog> {
  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final income = double.tryParse(_incomeController.text);
    final expense = double.tryParse(_expenseController.text);

    if (income == null || expense == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer des montants valides'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.repository.createFinanceReport(
        year: _selectedYear,
        month: _selectedMonth,
        totalIncome: income,
        totalExpense: expense,
      );
      if (mounted) {
        context.pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilan publié avec succès'), backgroundColor: AppColors.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance, color: AppColors.emerald),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Nouveau bilan financier', style: AppTypography.h2)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    dropdownColor: AppColors.cardSurfaceLight,
                    decoration: InputDecoration(
                      labelText: 'Mois',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardSurfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(_months[index], style: const TextStyle(color: AppColors.white)))),
                    onChanged: (val) => setState(() => _selectedMonth = val!),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    dropdownColor: AppColors.cardSurfaceLight,
                    decoration: InputDecoration(
                      labelText: 'Année',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.cardSurfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: List.generate(5, (index) {
                      final y = DateTime.now().year - index;
                      return DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(color: AppColors.white)));
                    }),
                    onChanged: (val) => setState(() => _selectedYear = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Total des recettes (GNF)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.arrow_downward, color: AppColors.emerald),
                filled: true,
                fillColor: AppColors.cardSurfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _expenseController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Total des dépenses (GNF)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.arrow_upward, color: AppColors.error),
                filled: true,
                fillColor: AppColors.cardSurfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: AppSpacing.md),
                AeemgPrimaryButton(
                  label: 'Publier',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
