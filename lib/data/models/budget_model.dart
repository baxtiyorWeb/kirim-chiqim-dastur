class BudgetModel {
  final double totalMonthlyBudget;
  final Map<String, double> categoryLimits; // categoryId -> limit amount

  const BudgetModel({
    required this.totalMonthlyBudget,
    required this.categoryLimits,
  });

  static BudgetModel defaultBudget() {
    return const BudgetModel(
      totalMonthlyBudget: 3000000.0,
      categoryLimits: {
        'food': 700000.0,
        'transport': 300000.0,
        'home': 700000.0,
        'education': 300000.0,
        'health': 200000.0,
        'clothes': 300000.0,
        'entertainment': 200000.0,
        'other': 300000.0,
      },
    );
  }

  BudgetModel copyWith({
    double? totalMonthlyBudget,
    Map<String, double>? categoryLimits,
  }) {
    return BudgetModel(
      totalMonthlyBudget: totalMonthlyBudget ?? this.totalMonthlyBudget,
      categoryLimits: categoryLimits ?? this.categoryLimits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMonthlyBudget': totalMonthlyBudget,
      'categoryLimits': categoryLimits,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final rawLimits = json['categoryLimits'] as Map<String, dynamic>? ?? {};
    final parsedLimits = rawLimits.map((k, v) => MapEntry(k, (v as num).toDouble()));

    return BudgetModel(
      totalMonthlyBudget: (json['totalMonthlyBudget'] as num?)?.toDouble() ?? 3000000.0,
      categoryLimits: parsedLimits,
    );
  }
}
