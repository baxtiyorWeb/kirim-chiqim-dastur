import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/guide/guide.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_bottom_sheets.dart';
import '../../../data/models/category_item.dart';
import '../../../providers/finance_providers.dart';
import '../../../core/intelligence/models/financial_health.dart';
import '../../../core/intelligence/providers/financial_intelligence_provider.dart';
import '../../../core/intelligence/widgets/what_if_sheet.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final guide = ref.read(guideControllerProvider.notifier);
        final state = ref.read(guideControllerProvider);
        if (!state.isActive && !guide.isTourCompleted(AppTours.budgetTourId)) {
          guide.startTour(AppTours.budgetContextualTour);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetProvider);
    final categoryExpenses = ref.watch(categoryExpensesProvider);
    final currentMonthExpenses = ref.watch(currentMonthExpensesProvider);
    final healthState = ref.watch(financialIntelligenceProvider);
    final colors = context.appColors;

    final totalSpent = currentMonthExpenses;
    final totalBudget = budget.totalMonthlyBudget;
    final remaining = (totalBudget - totalSpent).clamp(0, totalBudget);
    final overallProgress = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final overallPercent = (overallProgress * 100).toInt();

    // Standard categories list
    final categories = CategoryItem.defaultExpenseCategories;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Oylik smeta (Budjet)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: colors.textPrimary),
            tooltip: 'Smetani tahrirlash',
            onPressed: () => _editMonthlyBudgetDialog(context, ref, totalBudget),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(budgetProvider.notifier).refresh();
          await ref.read(dashboardSummaryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.space12),

            // Hero Budget Card
            GuideTarget(
              id: 'budget_overview_card',
              child: Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Umumiy oylik smeta',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: overallProgress > 0.85 ? colors.expenseBg : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                          ),
                          child: Text(
                            '$overallPercent% sarflandi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: overallProgress > 0.85 ? colors.expense : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            CurrencyFormatter.formatAdaptive(totalSpent, includeSymbol: false),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            ' / ${CurrencyFormatter.formatAdaptive(totalBudget, includeSymbol: true)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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
                            backgroundColor: colors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              value > 0.9 ? colors.expense : AppColors.primary,
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
                        Text(
                          'Smetadan qolgan limit:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              CurrencyFormatter.formatAdaptive(remaining, includeSymbol: true),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Smart Budget Intelligence Card
            _buildSmartBudgetIntelligenceCard(context, colors, healthState, remaining, totalBudget),

            const SizedBox(height: AppDimensions.space20),

            // Categories Budget Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kategoriyalar bo\'yicha limitlar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${categories.length} kategoriya',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space12),

            // List of Category Progress Bars
            GuideTarget(
              id: 'budget_categories_list',
              child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final spent = categoryExpenses[cat.id] ?? 0;
                final limit = budget.categoryLimits[cat.id] ?? 300000;
                final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                final percent = (progress * 100).toInt();

                return InkWell(
                  onTap: () {
                    HapticUtil.selection();
                    _editCategoryLimitDialog(context, ref, cat, limit);
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: cat.backgroundColor,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              ),
                              child: Icon(cat.icon, color: cat.iconColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${CurrencyFormatter.formatCompactUz(spent)} / ${CurrencyFormatter.formatCompactUz(limit, includeSymbol: true)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '$percent%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: progress > 0.85 ? colors.expense : colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.edit_outlined, size: 16, color: colors.textTertiary),
                              ],
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
                                backgroundColor: colors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  val > 0.85 ? colors.expense : cat.iconColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
  );
}

  void _editMonthlyBudgetDialog(BuildContext context, WidgetRef ref, int currentBudget) {
    final controller = TextEditingController(
      text: CurrencyFormatter.format(currentBudget, includeSymbol: false),
    );
    final colors = context.appColors;

    showAppModalBottomSheet(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Oylik smetani o\'zgartirish',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Yangi oylik limit',
                      suffixText: 'so\'m',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final amt = CurrencyFormatter.parse(controller.text);
                              if (amt > 0) {
                                setModalState(() => isSubmitting = true);
                                try {
                                  await ref.read(budgetProvider.notifier).updateMonthlyBudget(amt);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  HapticUtil.success();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Oylik smeta yangilandi'),
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    setModalState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Xatolik: $e'),
                                        backgroundColor: colors.expense,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _editCategoryLimitDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryItem cat,
    int currentLimit,
  ) {
    final controller = TextEditingController(
      text: CurrencyFormatter.format(currentLimit, includeSymbol: false),
    );
    final colors = context.appColors;

    showAppModalBottomSheet(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cat.name} limiti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: '${cat.name} uchun oylik limit',
                      suffixText: 'so\'m',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final amt = CurrencyFormatter.parse(controller.text);
                              if (amt > 0) {
                                setModalState(() => isSubmitting = true);
                                try {
                                  await ref.read(budgetProvider.notifier).updateCategoryLimit(cat.id, amt);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  HapticUtil.success();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${cat.name} limiti yangilandi'),
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    setModalState(() => isSubmitting = false);
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Xatolik: $e'),
                                        backgroundColor: colors.expense,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSmartBudgetIntelligenceCard(
    BuildContext context,
    AppThemeTokens colors,
    FinancialHealthState health,
    int remaining,
    int totalBudget,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverburning = health.safeToSpendToday > 0 && health.dailyBurnRate > health.safeToSpendToday;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16191F) : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isOverburning
              ? Colors.amber.shade700.withValues(alpha: 0.5)
              : const Color(0xFF007A55).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isOverburning
                          ? Colors.amber.withValues(alpha: 0.15)
                          : const Color(0xFF007A55).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOverburning ? Icons.speed_rounded : Icons.auto_graph_rounded,
                      size: 16,
                      color: isOverburning ? Colors.amber.shade800 : const Color(0xFF007A55),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Smeta holati va sur\'ati',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOverburning ? Colors.amber.shade800 : const Color(0xFF007A55),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticUtil.selection();
                  showWhatIfSimulatorSheet(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A55).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calculate_outlined, size: 13, color: Color(0xFF007A55)),
                      SizedBox(width: 4),
                      Text(
                        'Hisoblash',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007A55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Joriy kunlik sur\'at',
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(health.dailyBurnRate)}/kun',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isOverburning ? Colors.amber.shade900 : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: colors.border),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xavfsiz kunlik norma',
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(health.safeToSpendToday)}/kun',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF007A55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverburning
                  ? Colors.amber.withValues(alpha: 0.1)
                  : colors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isOverburning ? Icons.warning_amber_rounded : Icons.tips_and_updates_outlined,
                  size: 16,
                  color: isOverburning ? Colors.amber.shade900 : const Color(0xFF007A55),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOverburning
                        ? 'Xarajat tezligingiz normadan yuqori. Oylik smetangiz muddatidan oldin tugamasligi uchun kunlik sarfni kamaytirish tavsiya etiladi.'
                        : 'Smeta me\'yorida ushlab turilibdi. Agar shunday davom etsa, oy oxirida smetangiz xavfsiz chegarada saqlanadi.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
