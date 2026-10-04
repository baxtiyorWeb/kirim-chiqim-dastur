import 'transaction_item.dart';

class DashboardSummary {
  final int balance;
  final int initialBalance;
  final int totalIncome;
  final int totalExpense;
  final int todayIncome;
  final int todayExpense;
  final int monthExpense;
  final int totalMonthlyLimit;
  final int remainingBudget;
  final int totalBorrowed;
  final int remainingBorrowed;
  final int totalLent;
  final int remainingLent;
  final Map<String, int> categoryExpenses;
  final List<TransactionItem> recentTransactions;
  final bool hasLoaded;

  const DashboardSummary({
    required this.balance,
    this.initialBalance = 0,
    required this.totalIncome,
    required this.totalExpense,
    required this.todayIncome,
    required this.todayExpense,
    required this.monthExpense,
    this.totalMonthlyLimit = 0,
    required this.remainingBudget,
    this.totalBorrowed = 0,
    this.remainingBorrowed = 0,
    this.totalLent = 0,
    this.remainingLent = 0,
    required this.categoryExpenses,
    required this.recentTransactions,
    this.hasLoaded = false,
  });

  factory DashboardSummary.empty() {
    return const DashboardSummary(
      balance: 0,
      initialBalance: 0,
      totalIncome: 0,
      totalExpense: 0,
      todayIncome: 0,
      todayExpense: 0,
      monthExpense: 0,
      totalMonthlyLimit: 0,
      remainingBudget: 0,
      totalBorrowed: 0,
      remainingBorrowed: 0,
      totalLent: 0,
      remainingLent: 0,
      categoryExpenses: {},
      recentTransactions: [],
      hasLoaded: false,
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
      initialBalance: parseNum(json['initialBalance']),
      totalIncome: parseNum(json['totalIncome']),
      totalExpense: parseNum(json['totalExpense']),
      todayIncome: parseNum(json['todayIncome']),
      todayExpense: parseNum(json['todayExpense']),
      monthExpense: parseNum(json['monthExpense']),
      totalMonthlyLimit: parseNum(json['totalMonthlyLimit']),
      remainingBudget: parseNum(json['remainingBudget']),
      totalBorrowed: parseNum(json['totalBorrowed']),
      remainingBorrowed: parseNum(json['remainingBorrowed']),
      totalLent: parseNum(json['totalLent']),
      remainingLent: parseNum(json['remainingLent']),
      categoryExpenses: catMap,
      recentTransactions: txList,
      hasLoaded: true,
    );
  }

  DashboardSummary copyWith({
    int? balance,
    int? initialBalance,
    int? totalIncome,
    int? totalExpense,
    int? todayIncome,
    int? todayExpense,
    int? monthExpense,
    int? totalMonthlyLimit,
    int? remainingBudget,
    int? totalBorrowed,
    int? remainingBorrowed,
    int? totalLent,
    int? remainingLent,
    Map<String, int>? categoryExpenses,
    List<TransactionItem>? recentTransactions,
    bool? hasLoaded,
  }) {
    return DashboardSummary(
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      todayIncome: todayIncome ?? this.todayIncome,
      todayExpense: todayExpense ?? this.todayExpense,
      monthExpense: monthExpense ?? this.monthExpense,
      totalMonthlyLimit: totalMonthlyLimit ?? this.totalMonthlyLimit,
      remainingBudget: remainingBudget ?? this.remainingBudget,
      totalBorrowed: totalBorrowed ?? this.totalBorrowed,
      remainingBorrowed: remainingBorrowed ?? this.remainingBorrowed,
      totalLent: totalLent ?? this.totalLent,
      remainingLent: remainingLent ?? this.remainingLent,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}
