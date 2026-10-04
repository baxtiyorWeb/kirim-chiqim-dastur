import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/guide/guide.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_bottom_sheets.dart';
import '../../../data/models/category_item.dart';
import '../../../providers/finance_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedCategoryFilter = 'all';
  String _selectedTypeFilter = 'all'; // 'all', 'expense', 'income'
  String _searchQuery = '';
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _nextMonth() {
    HapticUtil.selection();
    ref.read(selectedDateFilterProvider.notifier).nextMonth();
  }

  void _prevMonth() {
    HapticUtil.selection();
    ref.read(selectedDateFilterProvider.notifier).prevMonth();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final selectedDate = ref.watch(selectedDateFilterProvider);
    final colors = context.appColors;

    // Filter transactions by month, category, type, and query
    final filtered = transactions.where((t) {
      final matchesMonth = t.dateTime.month == selectedDate.month &&
          t.dateTime.year == selectedDate.year;
      final matchesCategory =
          _selectedCategoryFilter == 'all' || t.categoryId == _selectedCategoryFilter;
      final matchesType = _selectedTypeFilter == 'all' ||
          (_selectedTypeFilter == 'expense' && t.isExpense) ||
          (_selectedTypeFilter == 'income' && t.isIncome);
      final matchesQuery = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesMonth && matchesCategory && matchesType && matchesQuery;
    }).toList();

    // Summary calculations
    final totalSpent = filtered.where((t) => t.isExpense).fold<int>(
          0,
          (sum, t) => sum + t.amount,
        );
    final totalEarned = filtered.where((t) => t.isIncome).fold<int>(
          0,
          (sum, t) => sum + t.amount,
        );
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final dailyAvg = totalSpent > 0 ? (totalSpent / daysInMonth).round() : 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: _isSearchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(color: colors.textTertiary),
                ),
              )
            : Text(
                AppStrings.navExpenses,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: colors.textPrimary,
            ),
            onPressed: () {
              HapticUtil.selection();
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: colors.textPrimary),
            onPressed: () {
              HapticUtil.selection();
              _showFilterModal(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(transactionsProvider.notifier).refresh();
          await ref.read(dashboardSummaryProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Month Selector: "<   Sentabr 2026 v   >"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space20,
                vertical: AppDimensions.space8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: colors.textPrimary,
                    onPressed: _prevMonth,
                  ),
                  InkWell(
                    onTap: () => _pickMonth(context, selectedDate),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            DateFormatter.formatMonthYear(selectedDate),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: colors.textPrimary,
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),

          // Two Metric Cards: "Jami xarajatlar" & "O'rtacha kunlik" (or Kirim)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
              child: GuideTarget(
                id: 'transactions_list',
                child: Row(
                  children: [
                  // Total Expenses Card
                  Expanded(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.totalExpenses,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(totalSpent),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 12,
                                color: colors.income,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                totalEarned > 0 ? '+${CurrencyFormatter.formatCompact(totalEarned)} kirim' : '12% past',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.income,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimensions.space12),

                  // Daily Average Card
                  Expanded(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.dailyAverage,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(width: 3, height: 8, color: colors.income),
                                  const SizedBox(width: 2),
                                  Container(width: 3, height: 12, color: colors.income),
                                  const SizedBox(width: 2),
                                  Container(width: 3, height: 16, color: colors.income),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.format(dailyAvg),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space16)),

          // Filter Chips Horizontal Scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _filterChip('all', 'Barchasi'),
                  ...CategoryItem.defaultExpenseCategories.map(
                    (cat) => _filterChip(cat.id, cat.name),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space16)),

          // Transaction Items List
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hozircha xarajat yo\'q',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bugungi xarajatlaringizni yozib boring — oy oxirida pulingiz qayerga ketganini aniq ko\'rasiz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          showAddEditTransactionSheet(context, ref);
                        },
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        label: const Text('Xarajat qo\'shish'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filtered[index];
                    final cat = CategoryItem.getById(item.categoryId);

                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: colors.expense,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showConfirmSheet(
                          context: context,
                          title: 'Tranzaksiyani o\'chirish',
                          message: '"${item.title}" xarajati butunlay o\'chiriladi. Rozimisiz?',
                          confirmLabel: 'O\'chirish',
                          isDestructive: true,
                          icon: Icons.delete_outline_rounded,
                          onConfirm: () async {
                            await ref.read(transactionsProvider.notifier).deleteTransaction(item.id);
                          },
                        );
                      },
                      onDismissed: (_) {
                        HapticUtil.medium();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Xarajat o\'chirildi'),
                            backgroundColor: colors.expense,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () {
                          HapticUtil.light();
                          // Instant edit bottom sheet
                          showAddEditTransactionSheet(context, ref, existingItem: item);
                        },
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: cat.backgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cat.icon,
                                  color: cat.iconColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${cat.name} • ${DateFormatter.formatRelativeTime(item.dateTime)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.isExpense ? '-' : '+ '}${CurrencyFormatter.format(item.amount)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: item.isExpense ? colors.textPrimary : colors.income,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    ),
  );
}

  Widget _filterChip(String id, String label) {
    final colors = context.appColors;
    final isSelected = _selectedCategoryFilter == id;
    return GestureDetector(
      onTap: () {
        HapticUtil.selection();
        setState(() {
          _selectedCategoryFilter = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : colors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.primary : colors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _pickMonth(BuildContext context, DateTime current) {
    final colors = context.appColors;
    showAppModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oyni tanlang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(12, (index) {
                  final monthIndex = index + 1;
                  final isCurrent = current.month == monthIndex;
                  return ChoiceChip(
                    label: Text(DateFormatter.uzbekMonths[index]),
                    selected: isCurrent,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isCurrent ? Colors.white : colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      ref.read(selectedDateFilterProvider.notifier).setDate(
                            DateTime(current.year, monthIndex, 1),
                          );
                      Navigator.pop(context);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showFilterModal(BuildContext context) {
    final colors = context.appColors;
    showAppModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtr va tartiblash',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.all_inclusive_rounded, color: colors.textSecondary),
                title: Text('Barcha tranzaksiyalar', style: TextStyle(color: colors.textPrimary)),
                trailing: _selectedTypeFilter == 'all' ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _selectedTypeFilter = 'all');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_downward_rounded, color: colors.expense),
                title: Text('Faqat chiqimlar', style: TextStyle(color: colors.textPrimary)),
                trailing: _selectedTypeFilter == 'expense' ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _selectedTypeFilter = 'expense');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_upward_rounded, color: colors.income),
                title: Text('Faqat kirimlar', style: TextStyle(color: colors.textPrimary)),
                trailing: _selectedTypeFilter == 'income' ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _selectedTypeFilter = 'income');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
