import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/animated_number.dart';
import '../../../core/utils/haptic_feedback_util.dart';
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

  final List<MonthlyBarData> _mockMonthlyData = const [
    MonthlyBarData(monthLabel: 'Apr', amount: 850000),
    MonthlyBarData(monthLabel: 'May', amount: 920000),
    MonthlyBarData(monthLabel: 'Iyn', amount: 1100000),
    MonthlyBarData(monthLabel: 'Iyl', amount: 780000),
    MonthlyBarData(monthLabel: 'Avg', amount: 1420000),
    MonthlyBarData(monthLabel: 'Sep', amount: 1250000, isSelected: true),
  ];

  @override
  Widget build(BuildContext context) {
    final totalExpenses = ref.watch(totalExpensesProvider);
    final categoryExpenses = ref.watch(categoryExpensesProvider);

    // Prepare Donut data matching image
    final foodAmt = categoryExpenses['food'] ?? 520000.0;
    final transportAmt = categoryExpenses['transport'] ?? 230000.0;
    final homeAmt = categoryExpenses['home'] ?? 400000.0;
    final otherAmt = categoryExpenses['other'] ?? 100000.0;

    final grandTotal = (foodAmt + transportAmt + homeAmt + otherAmt);
    final validTotal = grandTotal > 0 ? grandTotal : 1250000.0;

    final donutData = [
      CategoryDonutData(
        categoryName: 'Ovqatlanish',
        amount: foodAmt,
        percentage: (foodAmt / validTotal) * 100,
        color: const Color(0xFF10B981),
      ),
      CategoryDonutData(
        categoryName: 'Transport',
        amount: transportAmt,
        percentage: (transportAmt / validTotal) * 100,
        color: const Color(0xFF0284C7),
      ),
      CategoryDonutData(
        categoryName: 'Uy-joy',
        amount: homeAmt,
        percentage: (homeAmt / validTotal) * 100,
        color: AppColors.primary,
      ),
      CategoryDonutData(
        categoryName: 'Boshqa',
        amount: otherAmt,
        percentage: (otherAmt / validTotal) * 100,
        color: const Color(0xFFA78BFA),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.statistics,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.space12),

            // Segmented Period Pills: "Oylik", "Haftalik", "Yillik"
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(color: AppColors.border),
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
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.totalExpenses,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  AnimatedCurrencyText(
                    amount: totalExpenses,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppColors.income,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '12% (${AppStrings.comparedToLastMonth})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // Animated Bar Chart
                  AnimatedBarChartWidget(data: _mockMonthlyData),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // Category Breakdown Section: "Kategoriyalar bo'yicha"
            const Text(
              AppStrings.byCategory,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: AppDimensions.space12),

            Container(
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                border: Border.all(color: AppColors.border),
              ),
              child: AnimatedDonutChartWidget(data: donutData),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _periodPill(int index, String title) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticUtil.selection();
          setState(() {
            _selectedPeriod = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F3E37) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
