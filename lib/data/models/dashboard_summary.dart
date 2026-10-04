import 'transaction_item.dart';

class DashboardSummary {
  final int balance;
  final int totalIncome;
  final int totalExpense;
  final int todayIncome;
  final int todayExpense;
  final int monthExpense;
  final int remainingBudget;
  final Map<String, int> categoryExpenses;
  final List<TransactionItem> recentTransactions;

  const DashboardSummary({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.todayIncome,
    required this.todayExpense,
    required this.monthExpense,
    required this.remainingBudget,
    required this.categoryExpenses,
    required this.recentTransactions,
  });

  factory DashboardSummary.empty() {
    return const DashboardSummary(
      balance: 0,
      totalIncome: 0,
      totalExpense: 0,
      todayIncome: 0,
      todayExpense: 0,
      monthExpense: 0,
      remainingBudget: 0,
      categoryExpenses: {},
      recentTransactions: [],
    );
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final catMap = <String, int>{};
    if (json['categoryExpenses'] is Map) {
      final rawCat = json['categoryExpenses'] as Map<String, dynamic>;
      rawCat.forEach((key, value) {
        if (value is num) {
          catMap[key] = value.round();
        }
      });
    }

    final txList = <TransactionItem>[];
    if (json['recentTransactions'] is List) {
      final rawList = json['recentTransactions'] as List;
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          txList.add(TransactionItem.fromJson(item));
        }
      }
    }

    int parseNum(dynamic val, [int fallback = 0]) {
      if (val is num) return val.round();
      return fallback;
    }

    return DashboardSummary(
      balance: parseNum(json['balance']),
      totalIncome: parseNum(json['totalIncome']),
      totalExpense: parseNum(json['totalExpense']),
      todayIncome: parseNum(json['todayIncome']),
      todayExpense: parseNum(json['todayExpense']),
      monthExpense: parseNum(json['monthExpense']),
      remainingBudget: parseNum(json['remainingBudget']),
      categoryExpenses: catMap,
      recentTransactions: txList,
    );
  }
}
