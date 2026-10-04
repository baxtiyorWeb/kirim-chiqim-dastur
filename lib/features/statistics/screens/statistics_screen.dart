import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/animated_number.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/models/category_item.dart';
import '../../../providers/finance_providers.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/donut_chart_widget.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _selectedPeriod = 0; // 0: Oylik, 1: Haftalik, 2: Yillik

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final totalExpenses = ref.watch(totalExpensesProvider);
    final categoryExpenses = ref.watch(categoryExpensesProvider);
    final colors = context.appColors;

    // Dynamically calculate period expenses based on selected period
    final now = DateTime.now();
    final List<MonthlyBarData> dynamicMonthlyData = [];
    int currentPeriodSpent = 0;
    int previousPeriodSpent = 0;

    if (_selectedPeriod == 1) {
      // 1: Haftalik (Oxirgi 7 kun)
      final weekDays = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];
      for (int i = 6; i >= 0; i--) {
        final dayDate = now.subtract(Duration(days: i));
        final daySpent = transactions
            .where((t) =>
                t.isExpense &&
                t.dateTime.year == dayDate.year &&
                t.dateTime.month == dayDate.month &&
                t.dateTime.day == dayDate.day)
            .fold<int>(0, (sum, t) => sum + t.amount);
        if (i == 0) currentPeriodSpent = daySpent;
        if (i == 1) previousPeriodSpent = daySpent;
        dynamicMonthlyData.add(
          MonthlyBarData(
            monthLabel: weekDays[(dayDate.weekday - 1) % 7],
            amount: daySpent,
            isSelected: i == 0,
          ),
        );
      }
    } else if (_selectedPeriod == 2) {
      // 2: Yillik (Oxirgi 3 yil)
      for (int i = 2; i >= 0; i--) {
        final year = now.year - i;
        final yearSpent = transactions
            .where((t) => t.isExpense && t.dateTime.year == year)
            .fold<int>(0, (sum, t) => sum + t.amount);
        if (i == 0) currentPeriodSpent = yearSpent;
        if (i == 1) previousPeriodSpent = yearSpent;
        dynamicMonthlyData.add(
          MonthlyBarData(
            monthLabel: year.toString(),
            amount: yearSpent,
            isSelected: i == 0,
          ),
        );
      }
    } else {
      // 0: Oylik (Oxirgi 6 oy)
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthSpent = transactions
            .where((t) =>
                t.isExpense &&
                t.dateTime.year == monthDate.year &&
                t.dateTime.month == monthDate.month)
            .fold<int>(0, (sum, t) => sum + t.amount);

        if (i == 0) currentPeriodSpent = monthSpent;
        if (i == 1) previousPeriodSpent = monthSpent;

        final label = DateFormatter.getMonthShortName(monthDate.month);
        dynamicMonthlyData.add(
          MonthlyBarData(
            monthLabel: label,
            amount: monthSpent,
            isSelected: i == 0,
          ),
        );
      }
    }

    // Dynamic Donut data from real category expenses
    final List<CategoryDonutData> donutData = [];
    final int grandTotal = categoryExpenses.values.fold<int>(0, (a, b) => a + b);
    final int validTotal = grandTotal > 0 ? grandTotal : 1;

    final categories = CategoryItem.defaultExpenseCategories;
    for (final cat in categories) {
      final spent = categoryExpenses[cat.id] ?? 0;
      if (spent > 0) {
        donutData.add(
          CategoryDonutData(
            categoryName: cat.name,
            amount: spent,
            percentage: (spent / validTotal) * 100,
            color: cat.iconColor,
          ),
        );
      }
    }

    // Real comparison calculation
    double? diffPercent;
    if (previousPeriodSpent > 0) {
      diffPercent = ((currentPeriodSpent - previousPeriodSpent) / previousPeriodSpent) * 100;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.statistics,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final periodStr = _selectedPeriod == 1 ? 'weekly' : (_selectedPeriod == 2 ? 'yearly' : 'monthly');
          await ref.read(statisticsProvider.notifier).setPeriod(periodStr);
          await ref.read(transactionsProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.space12),

            // Segmented Period Pills: "Oylik", "Haftalik", "Yillik"
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  _periodPill(0, AppStrings.monthly),
                  _periodPill(1, AppStrings.weekly),
                  _periodPill(2, AppStrings.yearly),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Main Bar Chart Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.totalExpenses,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  AnimatedCurrencyText(
                    amount: currentPeriodSpent > 0 ? currentPeriodSpent : totalExpenses,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  if (diffPercent != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          diffPercent <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                          size: 14,
                          color: diffPercent <= 0 ? colors.income : colors.expense,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${diffPercent.abs().toStringAsFixed(1)}% (${AppStrings.comparedToLastMonth})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: diffPercent <= 0 ? colors.income : colors.expense,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppDimensions.space20),

                  // Animated Bar Chart
                  AnimatedBarChartWidget(data: dynamicMonthlyData),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // Category Breakdown Section: "Kategoriyalar bo'yicha"
            Text(
              AppStrings.byCategory,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),

            const SizedBox(height: AppDimensions.space12),

            Container(
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: donutData.isNotEmpty
                  ? AnimatedDonutChartWidget(data: donutData)
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pie_chart_outline_rounded, size: 48, color: colors.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              'Hozircha xarajatlar mavjud emas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Xarajat qo\'shilgach, bu yerda kategoriyalar diagrammasi ko\'rinadi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
  );
}

  Widget _periodPill(int index, String title) {
    final colors = context.appColors;
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticUtil.selection();
          setState(() {
            _selectedPeriod = index;
          });
          final periodStr = index == 1 ? 'weekly' : (index == 2 ? 'yearly' : 'monthly');
          ref.read(statisticsProvider.notifier).setPeriod(periodStr);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
