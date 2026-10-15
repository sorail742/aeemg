import 'package:aeemg/features/finance/data/finance_repository.dart';
import 'package:aeemg/features/finance/presentation/finance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeFinanceRepository extends FinanceRepository {
  _FakeFinanceRepository(this.reports) : super(null);

  final List<MonthlyReport> reports;

  @override
  Future<List<MonthlyReport>> fetchPublishedReports() async => reports;
}

MonthlyReport _report(int month, double income, double expense) =>
    MonthlyReport(
      id: '$month',
      year: 2026,
      month: month,
      totalIncome: income,
      totalExpense: expense,
      isPublished: true,
    );

Future<void> _pump(WidgetTester tester, List<MonthlyReport> reports) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        financeRepositoryProvider.overrideWithValue(
          _FakeFinanceRepository(reports),
        ),
      ],
      child: const MaterialApp(home: FinanceScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

/// Démonte l'écran : aucune apparition décalée ne reste en attente.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  testWidgets('Dernier bilan en bandeau, bilans précédents en liste', (
    tester,
  ) async {
    await _pump(tester, [
      _report(9, 400000, 300000),
      _report(8, 200000, 250000),
    ]);

    expect(find.text('DERNIER BILAN · SEPTEMBRE 2026'), findsOneWidget);
    expect(find.text('75 % des entrées dépensées'), findsOneWidget);
    expect(find.text('Bilans précédents'), findsOneWidget);
    expect(find.text('Août 2026'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('Aucun bilan publié : état vide', (tester) async {
    await _pump(tester, const []);

    expect(find.text('Aucun bilan publié'), findsOneWidget);
    expect(find.text('Bilans précédents'), findsNothing);

    await _dispose(tester);
  });
}
