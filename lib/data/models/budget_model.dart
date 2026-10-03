class BudgetModel {
  final int totalMonthlyBudget;
  final Map<String, int> categoryLimits; // categoryId -> limit amount
  final bool isEnabled;

  const BudgetModel({
    required this.totalMonthlyBudget,
    required this.categoryLimits,
    this.isEnabled = true,
  });

  static BudgetModel defaultBudget() {
    return const BudgetModel(
      totalMonthlyBudget: 3000000,
      categoryLimits: {
        'food': 700000,
        'transport': 300000,
        'home': 700000,
        'education': 300000,
        'health': 200000,
        'clothes': 300000,
        'entertainment': 200000,
        'other': 300000,
      },
      isEnabled: true,
    );
  }

  BudgetModel copyWith({
    int? totalMonthlyBudget,
    Map<String, int>? categoryLimits,
    bool? isEnabled,
  }) {
    return BudgetModel(
      totalMonthlyBudget: totalMonthlyBudget ?? this.totalMonthlyBudget,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMonthlyBudget': totalMonthlyBudget,
      'categoryLimits': categoryLimits,
      'isEnabled': isEnabled,
    };
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final rawLimits = json['categoryLimits'] as Map<String, dynamic>? ?? {};
    final parsedLimits = rawLimits.map((k, v) => MapEntry(k, (v as num).round()));

    final rawBudget = json['totalMonthlyBudget'];
    final int parsedTotal = rawBudget is num ? rawBudget.round() : 3000000;

    return BudgetModel(
      totalMonthlyBudget: parsedTotal,
      categoryLimits: parsedLimits,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }
}
