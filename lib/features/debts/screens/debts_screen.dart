import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../core/widgets/app_bottom_sheets.dart';
import '../../../data/models/debt_item.dart';
import '../../../providers/finance_providers.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  int _selectedFilter = 0; // 0: Barchasi, 1: Olingan (Qarzim), 2: Berilgan (Haqqim)

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtsProvider);
    final summary = ref.watch(debtsSummaryProvider);
    final colors = context.appColors;

    final filteredDebts = debts.where((d) {
      if (_selectedFilter == 1) return d.isBorrowed;
      if (_selectedFilter == 2) return !d.isBorrowed;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Qarz daftari',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Qarz qo\'shish', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(debtsProvider.notifier).refresh();
          await ref.read(dashboardSummaryProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
          child: Column(
          children: [
            const SizedBox(height: AppDimensions.space12),

            // Summary Dual Cards
            Row(
              children: [
                // Borrowed (Olingan - Red)
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
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.borrowed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Olingan qarz',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.formatAdaptive(summary.remainingBorrowed, includeSymbol: true),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.borrowed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: AppDimensions.space12),

                // Lent (Berilgan - Green)
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
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors.lent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Berilgan qarz',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.formatAdaptive(summary.remainingLent, includeSymbol: true),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.lent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space16),

            // Filter Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  _filterTab(0, 'Barchasi'),
                  _filterTab(1, 'Olingan (Qarzim)'),
                  _filterTab(2, 'Berilgan (Haqqim)'),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Debts List
            if (filteredDebts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Qarzlar ro\'yxati bo\'sh',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDebts.length,
                itemBuilder: (context, index) {
                  final debt = filteredDebts[index];
                  final isBorrowed = debt.isBorrowed;
                  final indicatorColor = isBorrowed ? colors.borrowed : colors.lent;
                  final indicatorBg = isBorrowed ? colors.borrowedBg : colors.lentBg;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Initial Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: indicatorBg,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  debt.personName.isNotEmpty ? debt.personName[0] : '?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: indicatorColor,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: AppDimensions.space12),

                            // Person info & amounts
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          debt.personName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            CurrencyFormatter.formatAdaptive(debt.remainingAmount, includeSymbol: true),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: indicatorColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isBorrowed ? 'Men olgan qarz' : 'Men bergan qarz',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: indicatorColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (debt.phoneNumber != null)
                                        Text(
                                          debt.phoneNumber!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (debt.note != null && debt.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            debt.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],

                        // Repayment history pill/expansion if repayments exist
                        if (debt.repayments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _showRepaymentsHistorySheet(context, debt),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 14, color: colors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${debt.repayments.length} ta to\'lov tarixi ko\'rish',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        Divider(color: colors.border, height: 1),
                        const SizedBox(height: 8),

                        // Bottom Actions: Status Pill & Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: debt.status == DebtStatus.returned
                                    ? colors.lentBg
                                    : colors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              ),
                              child: Text(
                                debt.status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: debt.status == DebtStatus.returned
                                      ? colors.lent
                                      : colors.textSecondary,
                                ),
                              ),
                            ),

                            Row(
                              children: [
                                if (debt.status != DebtStatus.returned) ...[
                                  // Record partial payment
                                  TextButton(
                                    onPressed: () => showDebtPaymentSheet(context, ref, debt),
                                    child: const Text('To\'lov kiritish', style: TextStyle(fontSize: 12)),
                                  ),
                                  // Mark fully returned
                                  ElevatedButton(
                                    onPressed: () async {
                                      final confirm = await showConfirmSheet(
                                        context: context,
                                        title: 'Qarzni yopish',
                                        message: '${debt.personName} bilan bo\'lgan qarz to\'liq qaytarildi deb belgilansinmi?',
                                        confirmLabel: 'Ha, yopilsin',
                                      );
                                      if (confirm == true) {
                                        HapticUtil.success();
                                        await ref.read(debtsProvider.notifier).markAsReturned(debt.id);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                      ),
                                    ),
                                    child: const Text(
                                      'Yopish',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: colors.textTertiary),
                                  tooltip: 'Qarzni o\'chirish',
                                  onPressed: () async {
                                    final confirm = await showConfirmSheet(
                                      context: context,
                                      title: 'Qarzni o\'chirish',
                                      message: '${debt.personName} bilan bo\'lgan qarz ma\'lumoti butunlay o\'chiriladi. Rozimisiz?',
                                      confirmLabel: 'O\'chirish',
                                      isDestructive: true,
                                      icon: Icons.delete_outline_rounded,
                                    );
                                    if (confirm == true) {
                                      HapticUtil.medium();
                                      await ref.read(debtsProvider.notifier).deleteDebt(debt.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Qarz o\'chirildi'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
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
    ),
  );
}

  Widget _filterTab(int index, String title) {
    final colors = context.appColors;
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticUtil.selection();
          setState(() {
            _selectedFilter = index;
          });
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
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _showRepaymentsHistorySheet(BuildContext context, DebtItem debt) {
    final colors = context.appColors;
    showAppModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${debt.personName} — To\'lovlar tarixi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ...debt.repayments.map((rep) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyFormatter.format(rep.amount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (rep.note != null && rep.note!.isNotEmpty)
                            Text(
                              rep.note!,
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                        ],
                      ),
                      Text(
                        DateFormatter.formatDateWithPrefix(rep.date),
                        style: TextStyle(fontSize: 11, color: colors.textTertiary),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAddDebtSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DebtType selectedType = DebtType.lent;
    final colors = context.appColors;

    showAppModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yangi qarz kiritish',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle: Lent vs Borrowed
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Berilgan (Haqqim)')),
                            selected: selectedType == DebtType.lent,
                            selectedColor: colors.lent,
                            labelStyle: TextStyle(
                              color: selectedType == DebtType.lent ? Colors.white : colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setModalState(() => selectedType = DebtType.lent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Olingan (Qarzim)')),
                            selected: selectedType == DebtType.borrowed,
                            selectedColor: colors.borrowed,
                            labelStyle: TextStyle(
                              color: selectedType == DebtType.borrowed ? Colors.white : colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setModalState(() => selectedType = DebtType.borrowed),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Shaxs ismi (Masalan: Akmal)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telefon raqam (ixtiyoriy)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: const InputDecoration(labelText: 'Summa (so\'m)', suffixText: 'so\'m'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Izoh'),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final amt = CurrencyFormatter.parse(amountController.text);
                          if (name.isNotEmpty && amt > 0) {
                            final newDebt = DebtItem(
                              id: const Uuid().v4(),
                              personName: name,
                              phoneNumber: phoneController.text.trim().isNotEmpty
                                  ? phoneController.text.trim()
                                  : null,
                              amount: amt,
                              date: DateTime.now(),
                              type: selectedType,
                              note: noteController.text.trim().isNotEmpty
                                  ? noteController.text.trim()
                                  : null,
                            );
                            try {
                              await ref.read(debtsProvider.notifier).addDebt(newDebt);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              HapticUtil.success();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Qarz muvaffaqiyatli saqlandi'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
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
                        child: const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.w700)),
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
}
