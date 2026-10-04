import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_bottom_sheets.dart';
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
    final dashboard = ref.watch(dashboardSummaryProvider);
    final userProfile = ref.watch(userProfileProvider);
    final transactions = ref.watch(transactionsProvider);
    final budget = ref.watch(budgetProvider);
    final debtsSummary = ref.watch(debtsSummaryProvider);
    final colors = context.appColors;

    final displayName = userProfile.fullName.isNotEmpty && userProfile.fullName != 'Foydalanuvchi'
        ? userProfile.fullName
        : ref.watch(financeRepositoryProvider).currentUserName ?? 'Foydalanuvchi';

    // Prefer aggregated PostgreSQL dashboard metrics
    final balance = dashboard.balance != 0 ? dashboard.balance : ref.watch(balanceProvider);
    final totalExpenses = dashboard.monthExpense != 0 ? dashboard.monthExpense : dashboard.totalExpense;
    final remainingBudget = dashboard.remainingBudget != 0 ? dashboard.remainingBudget : balance;
    final categoryExpenses = dashboard.categoryExpenses.isNotEmpty
        ? dashboard.categoryExpenses
        : ref.watch(categoryExpensesProvider);
    final recentTx = dashboard.recentTransactions.isNotEmpty
        ? dashboard.recentTransactions
        : transactions;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF007A55),
          onRefresh: () async {
            HapticUtil.selection();
            await Future.wait([
              ref.read(dashboardSummaryProvider.notifier).refresh(),
              ref.read(transactionsProvider.notifier).refresh(),
              ref.read(budgetProvider.notifier).refresh(),
              ref.read(debtsProvider.notifier).refresh(),
              ref.read(userProfileProvider.notifier).refresh(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                            text: TextSpan(
                              text: '${AppStrings.greeting} ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                color: colors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              children: [
                                TextSpan(
                                  text: displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.dashboardSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: colors.textSecondary,
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
                            border: Border.all(color: colors.border, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: userProfile.avatarUrl != null && userProfile.avatarUrl!.isNotEmpty
                                ? Image.network(
                                    userProfile.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _defaultAvatar(),
                                  )
                                : Image.asset(
                                    'assets/images/user_avatar.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _defaultAvatar(),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space16),

                // Hero Card (Server Balance & Total Expenses)
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
                    remainingBudget: remainingBudget,
                    onMonthTap: () => context.push('/transactions'),
                    onRemainingTap: () => context.push('/budget'),
                  ),
                ),

                const SizedBox(height: AppDimensions.space16),

                // Categories Horizontal List (from server category aggregates)
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

                // Recent Expenses List (from server transactions)
                RecentExpensesList(
                  transactions: recentTx,
                  onViewAll: () => context.push('/transactions'),
                  onItemTap: (item) {
                    showAddEditTransactionSheet(context, ref, existingItem: item);
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.primaryLight,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}
