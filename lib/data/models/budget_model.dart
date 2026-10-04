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
    Map<String, int> parsedLimits = {};
    if (json['categoryLimits'] is List) {
      final list = json['categoryLimits'] as List;
      for (final item in list) {
        if (item is Map) {
          final catId = item['categoryId']?.toString();
          final limit = item['limitAmount'];
          if (catId != null && limit is num) {
            parsedLimits[catId] = limit.round();
          }
        }
      }
    } else if (json['categoryLimits'] is Map) {
      final rawLimits = json['categoryLimits'] as Map<String, dynamic>;
      parsedLimits = rawLimits.map((k, v) => MapEntry(k, (v as num).round()));
    }

    final rawBudget = json['totalMonthlyBudget'] ?? json['totalMonthlyLimit'];
    final int parsedTotal = rawBudget is num ? rawBudget.round() : 3000000;

    return BudgetModel(
      totalMonthlyBudget: parsedTotal,
      categoryLimits: parsedLimits,
      isEnabled: json['isEnabled'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }
}

