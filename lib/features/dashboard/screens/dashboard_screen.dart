import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/guide/guide.dart';
import '../../../core/intelligence/providers/financial_intelligence_provider.dart';
import '../../../core/intelligence/widgets/what_if_sheet.dart';
import '../../../core/intelligence/widgets/calculation_breakdown_sheet.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_bottom_sheets.dart';
import '../../../providers/finance_providers.dart';
import '../widgets/dashboard_hero_card.dart';
import '../widgets/metric_summary_cards.dart';
import '../widgets/categories_horizontal_list.dart';
import '../widgets/recent_expenses_list.dart';
import '../widgets/fintech_quick_banners.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final guide = ref.read(guideControllerProvider.notifier);
        if (!guide.isTourCompleted(AppTours.firstLaunchTourId)) {
          guide.startTour(AppTours.firstLaunchTour);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardSummaryProvider);
    final userProfile = ref.watch(userProfileProvider);
    final transactions = ref.watch(transactionsProvider);
    final budget = ref.watch(budgetProvider);
    final debtsSummary = ref.watch(debtsSummaryProvider);
    final colors = context.appColors;

    final healthState = ref.watch(financialIntelligenceProvider);
    final displayName = userProfile.fullName.isNotEmpty && userProfile.fullName != 'Foydalanuvchi'
        ? userProfile.fullName
        : ref.watch(financeRepositoryProvider).currentUserName ?? 'Foydalanuvchi';

    // Single Source of Truth ledger balance
    final balance = ref.watch(balanceProvider);
    final totalExpenses = dashboard.monthExpense != 0 ? dashboard.monthExpense : dashboard.totalExpense;
    final remainingBudget = dashboard.totalMonthlyLimit > 0
        ? dashboard.remainingBudget
        : (budget.totalMonthlyBudget - totalExpenses);
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
            await ref.read(dashboardSummaryProvider.notifier).refresh();
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

                // Hero Card (Server Balance, Safe-to-Spend & Simulator)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                  child: GuideTarget(
                    id: 'dashboard_balance',
                    child: DashboardHeroCard(
                      balance: balance,
                      initialBalance: ref.watch(initialBalanceProvider),
                      totalExpenses: totalExpenses,
                      safeToSpendToday: healthState.safeToSpendToday,
                      riskLevel: healthState.riskLevel,
                      onTap: () {
                        HapticUtil.light();
                        context.push('/statistics');
                      },
                      onSimulatorTap: () {
                        HapticUtil.medium();
                        showWhatIfSimulatorSheet(context);
                      },
                      onBreakdownTap: () {
                        HapticUtil.selection();
                        showCalculationBreakdownSheet(context, healthState);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space16),

                // Categories Horizontal List (directly below Umumiy balans)
                CategoriesHorizontalList(
                  categoryExpenses: categoryExpenses,
                  onViewAll: () => context.push('/transactions'),
                  onCategoryTap: (cat) => context.push('/transactions'),
                ),

                const SizedBox(height: AppDimensions.space16),

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

                // Fintech Quick Banners (Debt & Budget status)
                FintechQuickBanners(
                  debtsSummary: debtsSummary,
                  budgetSpent: totalExpenses,
                  budgetTotal: dashboard.totalMonthlyLimit > 0
                      ? dashboard.totalMonthlyLimit
                      : budget.totalMonthlyBudget,
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
