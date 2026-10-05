import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/haptic_feedback_util.dart';
import '../../data/models/category_item.dart';
import '../../data/models/debt_item.dart';
import '../../data/models/transaction_item.dart';
import '../../providers/finance_providers.dart';
import 'paywall_sheet.dart';

/// Standard modal bottom sheet wrapper adhering to Material 3 design and fully responsive to keyboard
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool enableDrag = true,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    showDragHandle: false, // We render our own premium animated handle
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colors = sheetContext.appColors;
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: bottomInset),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusExtraLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDragHandle) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  builder(sheetContext),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Confirmation Sheet (e.g. Logout, Delete Transaction, Account Deletion)
Future<bool?> showConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Tasdiqlash',
  String cancelLabel = 'Bekor qilish',
  bool isDestructive = false,
  IconData icon = Icons.info_outline_rounded,
  Future<void> Function()? onConfirm,
}) {
  return showAppModalBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final colors = ctx.appColors;
      bool isConfirming = false;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDestructive ? colors.expenseBg : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? colors.expense : AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isConfirming ? null : () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isConfirming
                            ? null
                            : () async {
                                HapticUtil.medium();
                                if (onConfirm != null) {
                                  setSheetState(() => isConfirming = true);
                                  try {
                                    await onConfirm();
                                    if (ctx.mounted) Navigator.pop(ctx, true);
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      setSheetState(() => isConfirming = false);
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text('Xatolik: $e'),
                                          backgroundColor: colors.expense,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  Navigator.pop(ctx, true);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive ? colors.expense : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                          ),
                        ),
                        child: isConfirming
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(
                                confirmLabel,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Help & Support Bottom Sheet
void showSupportBottomSheet(BuildContext context) {
  showAppModalBottomSheet(
    context: context,
    builder: (ctx) {
      final colors = ctx.appColors;
      final faqItems = [
        {'q': 'Tranzaksiyani qanday tahrirlayman?', 'a': 'Xarajatlar sahifasida kerakli yozuv ustiga bosing.'},
        {'q': 'Qarz yopilganda balansga ta\'sir qiladimi?', 'a': 'Qarz to\'langanda istasangiz buni xarajat yoki daromad sifatida ham kiritishingiz mumkin.'},
        {'q': 'Byudjet limiti oshsa nima bo\'ladi?', 'a': 'Ilova ogohlantiruvchi qizil indikator bilan xabar beradi.'},
        {'q': 'Ma\'lumotlarim qayerda saqlanadi?', 'a': 'Hozirda qurilmangizning xavfsiz xotirasida saqlanadi va oflayn rejimda ishlaydi.'},
      ];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qanday yordam kerak?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ko\'p so\'raladigan savollar (FAQ)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...faqItems.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      item['q']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                        child: Text(
                          item['a']!,
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Qo\'llab-quvvatlash xizmati: @moliya_support_bot'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 18),
                  label: const Text('Qo\'llab-quvvatlashga yozish', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}

/// Export Bottom Sheet
void showExportBottomSheet(BuildContext context, WidgetRef ref) {
  showAppModalBottomSheet(
    context: context,
    builder: (ctx) {
      final colors = ctx.appColors;
      bool includeExpenses = true;
      bool includeIncome = true;
      bool includeDebts = true;

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hisobotni yuklab olish',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Moliyaviy ma\'lumotlaringizni Excel/CSV formatida saqlab oling.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Xarajatlar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: includeExpenses,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => includeExpenses = v ?? true),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Daromadlar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: includeIncome,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => includeIncome = v ?? true),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Qarz daftari', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  value: includeDebts,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => includeDebts = v ?? true),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final sub = ref.read(subscriptionProvider);
                      if (!sub.canUse('export_reports')) {
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          await showPaywallSheet(context, featureKey: 'export_reports');
                        }
                        return;
                      }

                      final repo = ref.read(financeRepositoryProvider);
                      try {
                        await repo.authorizeExport();
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          await showPaywallSheet(context, featureKey: 'export_reports');
                        }
                        return;
                      }

                      final csvContent = repo.generateCsvReport(
                        includeExpenses: includeExpenses,
                        includeIncome: includeIncome,
                        includeDebts: includeDebts,
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        HapticUtil.success();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'CSV hisobot muvaffaqiyatli shakllantirildi (${csvContent.split('\n').length} qator)',
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                    label: const Text('CSV formatda yuklash', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Quick Action: Choice between Kirim and Chiqim before opening transaction sheet
Future<void> showTransactionTypePickerSheet(
  BuildContext context,
  WidgetRef ref,
) {
  HapticUtil.selection();
  final colors = context.appColors;

  return showAppModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amal turini tanlang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(sheetContext),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // 1. Chiqim Card
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticUtil.medium();
                        Navigator.pop(sheetContext);
                        showAddEditTransactionSheet(context, ref, initialIsExpense: true);
                      },
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.expenseBg.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(
                            color: colors.expense.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.expenseBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                color: colors.expense,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chiqim',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Xarajat va to\'lovlar',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 2. Kirim Card
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticUtil.medium();
                        Navigator.pop(sheetContext);
                        showAddEditTransactionSheet(context, ref, initialIsExpense: false);
                      },
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.incomeBg.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(
                            color: colors.income.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.incomeBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                color: colors.income,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Kirim',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Maosh va tushumlar',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

/// Interactive Add/Edit Transaction Bottom Sheet
void showAddEditTransactionSheet(
  BuildContext context,
  WidgetRef ref, {
  TransactionItem? existingItem,
  bool initialIsExpense = true,
}) {
  final isEditing = existingItem != null;
  final colors = context.appColors;
  bool isSubmitting = false;

  bool isExpense = isEditing ? existingItem.isExpense : initialIsExpense;
  int amount = isEditing ? existingItem.amount : 0;
  String selectedCategoryId = isEditing
      ? existingItem.categoryId
      : (initialIsExpense ? 'food' : 'salary');
  DateTime selectedDate = isEditing ? existingItem.dateTime : DateTime.now();
  String paymentMethod = isEditing ? existingItem.paymentMethod : 'cash';

  final titleController = TextEditingController(text: isEditing ? existingItem.title : '');
  final noteController = TextEditingController(text: isEditing ? (existingItem.note ?? '') : '');
  final amountController = TextEditingController(
    text: isEditing ? CurrencyFormatter.format(existingItem.amount, includeSymbol: false) : '',
  );

  final List<int> quickChips = [10000, 20000, 50000, 100000, 500000];

  showAppModalBottomSheet(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final categories = isExpense
              ? CategoryItem.defaultExpenseCategories
              : CategoryItem.defaultIncomeCategories;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Type Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? (isExpense ? 'Xarajatni tahrirlash' : 'Daromadni tahrirlash')
                            : (isExpense ? 'Chiqim qo\'shish' : 'Kirim qo\'shish'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      // Toggle pills (allows user to switch type freely in modal)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticUtil.selection();
                                setSheetState(() {
                                  isExpense = true;
                                  selectedCategoryId = 'food';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isExpense ? colors.expense : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                ),
                                child: Text(
                                  'Chiqim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isExpense ? Colors.white : colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticUtil.selection();
                                setSheetState(() {
                                  isExpense = false;
                                  selectedCategoryId = 'salary';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: !isExpense ? colors.income : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                ),
                                child: Text(
                                  'Kirim',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: !isExpense ? Colors.white : colors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Amount Input Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: isExpense
                            ? colors.expense.withValues(alpha: 0.3)
                            : colors.income.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isExpense ? colors.expenseBg : colors.incomeBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: isExpense ? colors.expense : colors.income,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                autofocus: !isEditing,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                                onChanged: (val) {
                                  amount = CurrencyFormatter.parse(val);
                                },
                                decoration: InputDecoration(
                                  hintText: '0',
                                  suffixText: ' so\'m',
                                  suffixStyle: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Quick amounts
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: quickChips.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final chipVal = quickChips[idx];
                              return GestureDetector(
                                onTap: () {
                                  HapticUtil.selection();
                                  setSheetState(() {
                                    amount += chipVal;
                                    amountController.text = CurrencyFormatter.format(amount, includeSymbol: false);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${CurrencyFormatter.formatCompact(chipVal)}',
                                      style: TextStyle(
                                        fontSize: 11,
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

                  const SizedBox(height: 16),

                  // Categories Horizontal Grid
                  Text(
                    'Kategoriya',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final isSelected = cat.id == selectedCategoryId;
                        return GestureDetector(
                          onTap: () {
                            HapticUtil.selection();
                            setSheetState(() => selectedCategoryId = cat.id);
                          },
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryLight : colors.card,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : colors.border,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: cat.backgroundColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(cat.icon, color: cat.iconColor, size: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
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
                  ),

                  const SizedBox(height: 14),

                  // Title / Note
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Nomi (ixtiyoriy)',
                      hintText: CategoryItem.getById(selectedCategoryId).name,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Izoh (ixtiyoriy)',
                      hintText: 'Qo\'shimcha ma\'lumot...',
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Date Picker Row
                  InkWell(
                    onTap: () async {
                      HapticUtil.selection();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: colors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                DateFormatter.formatDateWithPrefix(selectedDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.edit_calendar_rounded, size: 18, color: colors.textTertiary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save Action Button
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Iltimos, to\'g\'ri summani kiriting'),
                                    backgroundColor: colors.expense,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isSubmitting = true);
                              HapticUtil.success();
                              final catName = CategoryItem.getById(selectedCategoryId).name;
                              final customTitle = titleController.text.trim();
                              final finalTitle = customTitle.isNotEmpty ? customTitle : catName;
                              final note = noteController.text.trim();

                              try {
                                if (isEditing) {
                                  final updated = existingItem.copyWith(
                                    title: finalTitle,
                                    amount: amount,
                                    categoryId: selectedCategoryId,
                                    type: isExpense ? TransactionType.expense : TransactionType.income,
                                    dateTime: selectedDate,
                                    note: note.isNotEmpty ? note : null,
                                    paymentMethod: paymentMethod,
                                  );
                                  await ref.read(transactionsProvider.notifier).updateTransaction(updated);
                                } else {
                                  final newItem = TransactionItem(
                                    id: const Uuid().v4(),
                                    title: finalTitle,
                                    amount: amount,
                                    categoryId: selectedCategoryId,
                                    type: isExpense ? TransactionType.expense : TransactionType.income,
                                    dateTime: selectedDate,
                                    note: note.isNotEmpty ? note : null,
                                    paymentMethod: paymentMethod,
                                  );
                                  await ref.read(transactionsProvider.notifier).addTransaction(newItem);
                                }

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Tranzaksiya yangilandi'
                                            : (isExpense ? 'Xarajat saqlandi' : 'Daromad saqlandi'),
                                      ),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  setSheetState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Xatolik: $e'),
                                      backgroundColor: colors.expense,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
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
                          : Text(
                              isEditing ? 'Saqlash' : AppStrings.save,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Debt Payment Dialog
void showDebtPaymentSheet(BuildContext context, WidgetRef ref, DebtItem debt) {
  final amountController = TextEditingController(
    text: CurrencyFormatter.format(debt.remainingAmount, includeSymbol: false),
  );
  final noteController = TextEditingController();
  bool linkToTransactions = true;
  bool isSubmitting = false;
  final colors = context.appColors;

  showAppModalBottomSheet(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                  '${debt.personName} — Qarz to\'lovi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qolgan qarz summasi: ${CurrencyFormatter.format(debt.remainingAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'To\'lanadigan summa',
                    suffixText: 'so\'m',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Izoh (ixtiyoriy)',
                    hintText: 'Qarz to\'lovi haqida eslatma',
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    debt.isBorrowed
                        ? 'Balansdan xarajat sifatida ayirish'
                        : 'Balansga daromad sifatida qo\'shish',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  value: linkToTransactions,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => linkToTransactions = val ?? true),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final amt = CurrencyFormatter.parse(amountController.text);
                            if (amt > 0) {
                              setState(() => isSubmitting = true);
                              try {
                                await ref.read(debtsProvider.notifier).recordPayment(
                                      debtId: debt.id,
                                      amount: amt,
                                      note: noteController.text.trim().isNotEmpty
                                          ? noteController.text.trim()
                                          : null,
                                      linkTransaction: linkToTransactions,
                                    );
                                HapticUtil.success();
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Qarz to\'lovi muvaffaqiyatli qayd etildi'),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  setState(() => isSubmitting = false);
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
                        : const Text('To\'lovni kiritish', style: TextStyle(fontWeight: FontWeight.w700)),
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
