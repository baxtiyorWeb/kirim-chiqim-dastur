import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../providers/finance_providers.dart';
import '../widgets/dashboard_hero_card.dart';
import '../widgets/metric_summary_cards.dart';
import '../widgets/categories_horizontal_list.dart';
import '../widgets/recent_expenses_list.dart';
import '../widgets/fintech_quick_banners.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final totalExpenses = ref.watch(totalExpensesProvider);
    final categoryExpenses = ref.watch(categoryExpensesProvider);
    final balance = ref.watch(balanceProvider);
    final budget = ref.watch(budgetProvider);
    final debtsSummary = ref.watch(debtsSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.space12),

              // Top User Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: '${AppStrings.greeting} ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            children: [
                              TextSpan(
                                text: AppStrings.userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          AppStrings.dashboardSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // User Avatar
                    GestureDetector(
                      onTap: () {
                        HapticUtil.selection();
                        context.push('/profile');
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/user_avatar.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.primaryLight,
                              child: const Icon(
                                Icons.person,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Hero Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                child: DashboardHeroCard(
                  totalExpenses: totalExpenses,
                  onTap: () {
                    HapticUtil.light();
                    context.push('/statistics');
                  },
                ),
              ),

              const SizedBox(height: AppDimensions.space12),

              // 2 Metric Summary Cards: "Bu oy" & "Qolgan mablag'"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                child: MetricSummaryCards(
                  thisMonthExpense: totalExpenses,
                  remainingBudget: balance,
                  onMonthTap: () => context.push('/transactions'),
                  onRemainingTap: () => context.push('/budget'),
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Categories Horizontal List
              CategoriesHorizontalList(
                categoryExpenses: categoryExpenses,
                onViewAll: () => context.push('/transactions'),
                onCategoryTap: (cat) => context.push('/transactions'),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Fintech Quick Banners (Debt & Budget status)
              FintechQuickBanners(
                debtsSummary: debtsSummary,
                budgetSpent: totalExpenses,
                budgetTotal: budget.totalMonthlyBudget,
                onDebtsTap: () => context.push('/debts'),
                onBudgetTap: () => context.push('/budget'),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Recent Expenses List
              RecentExpensesList(
                transactions: transactions,
                onViewAll: () => context.push('/transactions'),
                onItemTap: (item) {},
              ),

              const SizedBox(height: 100), // padding for bottom navigation
            ],
          ),
        ),
      ),
    );
  }
}
