class CategoryStat {
  final String categoryId;
  final int total;
  final double percentage;

  const CategoryStat({
    required this.categoryId,
    required this.total,
    required this.percentage,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryId: json['categoryId']?.toString() ?? 'other',
      total: (json['total'] as num?)?.round() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StatisticsResponse {
  final String period; // "weekly", "monthly", "yearly"
  final int totalIncome;
  final int totalExpense;
  final int netSavings;
  final List<CategoryStat> categoryExpenses;
  final List<CategoryStat> categoryIncomes;

  const StatisticsResponse({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.categoryExpenses,
    required this.categoryIncomes,
  });

  factory StatisticsResponse.empty([String period = 'monthly']) {
    return StatisticsResponse(
      period: period,
      totalIncome: 0,
      totalExpense: 0,
      netSavings: 0,
      categoryExpenses: [],
      categoryIncomes: [],
    );
  }

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) {
    final expList = <CategoryStat>[];
    if (json['categoryExpenses'] is List) {
      for (final e in json['categoryExpenses'] as List) {
        if (e is Map<String, dynamic>) {
          expList.add(CategoryStat.fromJson(e));
        }
      }
    }

    final incList = <CategoryStat>[];
    if (json['categoryIncomes'] is List) {
      for (final e in json['categoryIncomes'] as List) {
        if (e is Map<String, dynamic>) {
          incList.add(CategoryStat.fromJson(e));
        }
      }
    }

    int parseNum(dynamic val) {
      if (val is num) return val.round();
      return 0;
    }

    return StatisticsResponse(
      period: json['period']?.toString() ?? 'monthly',
      totalIncome: parseNum(json['totalIncome']),
      totalExpense: parseNum(json['totalExpense']),
      netSavings: parseNum(json['netSavings']),
      categoryExpenses: expList,
      categoryIncomes: incList,
    );
  }
}
