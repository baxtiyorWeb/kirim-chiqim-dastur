import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/models/category_item.dart';
import '../../../data/models/transaction_item.dart';
import '../../../providers/finance_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionItem? existingItem;

  const AddTransactionScreen({
    super.key,
    this.existingItem,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late bool _isExpense;
  late int _amount;
  late String _selectedCategoryId;
  late DateTime _selectedDate;
  late String _paymentMethod;
  bool _isLoading = false;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<int> _quickChips = [10000, 20000, 50000, 100000, 500000];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _isExpense = item.isExpense;
      _amount = item.amount;
      _selectedCategoryId = item.categoryId;
      _selectedDate = item.dateTime;
      _paymentMethod = item.paymentMethod;
      _noteController.text = item.note ?? item.title;
      _amountController.text = CurrencyFormatter.format(item.amount, includeSymbol: false);
    } else {
      _isExpense = true;
      _amount = 0;
      _selectedCategoryId = 'food';
      _selectedDate = DateTime.now();
      _paymentMethod = 'cash';
      _amountController.text = '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    setState(() {
      _amount = CurrencyFormatter.parse(val);
    });
  }

  void _addQuickAmount(int chipAmount) {
    HapticUtil.selection();
    setState(() {
      _amount += chipAmount;
      _amountController.text = CurrencyFormatter.format(_amount, includeSymbol: false);
    });
  }

  Future<void> _selectDate() async {
    HapticUtil.selection();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final colors = context.appColors;
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Iltimos, summani kiriting'),
          backgroundColor: colors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticUtil.success();
    final selectedCategory = CategoryItem.getById(_selectedCategoryId);
    final note = _noteController.text.trim();
    final title = note.isNotEmpty ? note : selectedCategory.name;

    try {
      if (widget.existingItem != null) {
        final updated = widget.existingItem!.copyWith(
          title: title,
          amount: _amount,
          categoryId: _selectedCategoryId,
          type: _isExpense ? TransactionType.expense : TransactionType.income,
          dateTime: _selectedDate,
          note: note.isNotEmpty ? note : null,
          paymentMethod: _paymentMethod,
        );
        await ref.read(transactionsProvider.notifier).updateTransaction(updated);
      } else {
        final newTransaction = TransactionItem(
          id: const Uuid().v4(),
          title: title,
          amount: _amount,
          categoryId: _selectedCategoryId,
          type: _isExpense ? TransactionType.expense : TransactionType.income,
          dateTime: _selectedDate,
          note: note.isNotEmpty ? note : null,
          paymentMethod: _paymentMethod,
        );
        await ref.read(transactionsProvider.notifier).addTransaction(newTransaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingItem != null
                  ? 'Tranzaksiya muvaffaqiyatli yangilandi'
                  : (_isExpense ? 'Xarajat muvaffaqiyatli saqlandi' : 'Daromad saqlandi'),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: colors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final categories = _isExpense
        ? CategoryItem.defaultExpenseCategories
        : CategoryItem.defaultIncomeCategories;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          widget.existingItem != null
              ? (_isExpense ? 'Xarajatni tahrirlash' : 'Daromadni tahrirlash')
              : (_isExpense ? AppStrings.addExpense : AppStrings.addIncome),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Toggle Expense / Income
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticUtil.selection();
                    setState(() {
                      _isExpense = true;
                      _selectedCategoryId = 'food';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isExpense ? colors.expense : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    ),
                    child: Text(
                      'Xarajat',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isExpense ? Colors.white : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticUtil.selection();
                    setState(() {
                      _isExpense = false;
                      _selectedCategoryId = 'salary';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !_isExpense ? colors.income : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    ),
                    child: Text(
                      'Daromad',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_isExpense ? Colors.white : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
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
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monetization_on_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),

                      // Amount Input TextField
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          onChanged: _onAmountChanged,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            suffixText: ' so\'m',
                            suffixStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                            hintText: '0',
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.space16),

                  // Quick Chips: "10 000", "20 000", "50 000", "100 000", "500 000"
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickChips.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final chipVal = _quickChips[idx];
                        return GestureDetector(
                          onTap: () => _addQuickAmount(chipVal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              border: Border.all(color: colors.border),
                            ),
                            child: Center(
                              child: Text(
                                '+${CurrencyFormatter.formatCompact(chipVal)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // Note Field: "Izoh (ixtiyoriy)"
            Text(
              AppStrings.noteOptional,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Container(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _noteController,
                style: TextStyle(color: colors.textPrimary),
                decoration: const InputDecoration(
                  hintText: AppStrings.notePlaceholder,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space20),

            // Category Selection Header: "Kategoriya"
            Text(
              AppStrings.category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Category Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat.id == _selectedCategoryId;

                return GestureDetector(
                  onTap: () {
                    HapticUtil.selection();
                    setState(() {
                      _selectedCategoryId = cat.id;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryLight : colors.card,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : colors.border,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: cat.backgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat.icon,
                            color: cat.iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppDimensions.space20),

            // Date Picker Card: "Sana"
            Text(
              AppStrings.date,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatDateWithPrefix(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.existingItem != null ? 'Saqlash' : AppStrings.save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: AppDimensions.space24),
          ],
        ),
      ),
    );
  }
}
