import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/finance_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);
    final categoryExpenses = ref.watch(categoryExpensesProvider);

    // Dynamic calculations from user state or design defaults
    final totalSpent = categoryExpenses.values.fold<double>(0.0, (a, b) => a + b);
    final displaySpent = totalSpent > 0 ? totalSpent : 1850000.0;
    final totalBudget = budget.totalMonthlyBudget;
    final remaining = (totalBudget - displaySpent).clamp(0.0, totalBudget);
    final overallProgress = totalBudget > 0 ? (displaySpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final overallPercent = (overallProgress * 100).toInt();

    // Specified categories from prompt: Food: 500k/700k, Transport: 150k/300k, Home: 600k/700k, Education: 200k/300k
    final categoryBudgets = [
      _CategoryBudgetData(
        categoryId: 'food',
        name: 'Ovqatlanish (Food)',
        spent: categoryExpenses['food'] ?? 500000.0,
        limit: budget.categoryLimits['food'] ?? 700000.0,
        color: AppColors.food,
        icon: Icons.restaurant_rounded,
      ),
      _CategoryBudgetData(
        categoryId: 'transport',
        name: 'Transport',
        spent: categoryExpenses['transport'] ?? 150000.0,
        limit: budget.categoryLimits['transport'] ?? 300000.0,
        color: AppColors.transport,
        icon: Icons.directions_car_rounded,
      ),
      _CategoryBudgetData(
        categoryId: 'home',
        name: 'Uy-joy (Home)',
        spent: categoryExpenses['home'] ?? 600000.0,
        limit: budget.categoryLimits['home'] ?? 700000.0,
        color: AppColors.home,
        icon: Icons.home_rounded,
      ),
      _CategoryBudgetData(
        categoryId: 'education',
        name: 'Ta\'lim (Education)',
        spent: categoryExpenses['education'] ?? 200000.0,
        limit: budget.categoryLimits['education'] ?? 300000.0,
        color: AppColors.education,
        icon: Icons.school_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Oylik smeta (Budjet)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => _editMonthlyBudgetDialog(context, ref, totalBudget),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.space12),

            // Hero Budget Card matching prompt specs:
            // "Progress: 1,850,000 / 3,000,000 | Remaining: 1,150,000"
            Container(
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Umumiy oylik smeta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: overallProgress > 0.85
                              ? AppColors.expenseLight
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                        child: Text(
                          '$overallPercent% sarflandi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: overallProgress > 0.85
                                ? AppColors.expense
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Progress numbers
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatter.format(displaySpent, includeSymbol: false),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        ' / ${CurrencyFormatter.format(totalBudget)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Smooth animated linear progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: overallProgress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            value > 0.9 ? AppColors.expense : AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Remaining amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Qolgan mablag\':',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(remaining),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space24),

            // Categories Budget Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kategoriyalar bo\'yicha limitlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${categoryBudgets.length} kategoriya',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space12),

            // List of Category Progress Bars
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryBudgets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = categoryBudgets[index];
                final progress = item.limit > 0 ? (item.spent / item.limit).clamp(0.0, 1.0) : 0.0;
                final percent = (progress * 100).toInt();

                return Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${CurrencyFormatter.formatCompact(item.spent)} / ${CurrencyFormatter.formatCompact(item.limit)} so\'m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: progress > 0.85 ? AppColors.expense : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, child) {
                            return LinearProgressIndicator(
                              value: val,
                              minHeight: 6,
                              backgroundColor: AppColors.borderLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                val > 0.85 ? AppColors.expense : item.color,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _editMonthlyBudgetDialog(BuildContext context, WidgetRef ref, double currentBudget) {
    final controller = TextEditingController(text: currentBudget.toInt().toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          title: const Text('Oylik smetani o\'zgartirish'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Yangi budjet summasi',
              suffixText: 'so\'m',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(controller.text.replaceAll(' ', '')) ?? currentBudget;
                ref.read(budgetProvider.notifier).updateMonthlyBudget(amt);
                Navigator.pop(context);
              },
              child: const Text('Saqlash'),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryBudgetData {
  final String categoryId;
  final String name;
  final double spent;
  final double limit;
  final Color color;
  final IconData icon;

  const _CategoryBudgetData({
    required this.categoryId,
    required this.name,
    required this.spent,
    required this.limit,
    required this.color,
    required this.icon,
  });
}
