import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyReport {
  const MonthlyReport({
    required this.id,
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.isPublished,
  });

  final String id;
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final bool isPublished;

  double get balance => totalIncome - totalExpense;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
        id: json['id'] as String,
        year: json['year'] as int,
        month: json['month'] as int,
        totalIncome: (json['total_income'] as num).toDouble(),
        totalExpense: (json['total_expense'] as num).toDouble(),
        isPublished: json['is_published'] as bool? ?? false,
      );
}

class FinanceRepository {
  FinanceRepository(this._client);

  final SupabaseClient? _client;

  Future<List<MonthlyReport>> fetchPublishedReports() async {
    final rows = await _client
        ?.from('monthly_reports')
        .select()
        .eq('is_published', true)
        .order('year', ascending: false)
        .order('month', ascending: false);
    return (rows as List? ?? [])
        .map((e) => MonthlyReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
