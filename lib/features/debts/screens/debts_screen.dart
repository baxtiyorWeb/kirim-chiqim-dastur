import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';
import '../../../data/models/debt_item.dart';
import '../../../providers/finance_providers.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  int _selectedFilter = 0; // 0: Barchasi, 1: Olingan (Borrowed), 2: Berilgan (Lent)

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtsProvider);
    final summary = ref.watch(debtsSummaryProvider);

    final filteredDebts = debts.where((d) {
      if (_selectedFilter == 1) return d.isBorrowed;
      if (_selectedFilter == 2) return !d.isBorrowed;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Qarzlar daftari',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Qarz qo\'shish', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.borrowed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Olingan qarz',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(summary.remainingBorrowed),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.borrowed,
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
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.lent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Berilgan qarz',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(summary.remainingLent),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lent,
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
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(color: AppColors.border),
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Qarzlar ro\'yxati bo\'sh',
                    style: TextStyle(color: AppColors.textSecondary),
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
                  final indicatorColor = isBorrowed ? AppColors.borrowed : AppColors.lent;
                  final indicatorBg = isBorrowed ? AppColors.borrowedLight : AppColors.lentLight;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Initial Avatar with indicator color
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

                            // Person info & date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        debt.personName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(debt.remainingAmount),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: indicatorColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isBorrowed ? 'Olingan qarz' : 'Berilgan qarz',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: indicatorColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (debt.phoneNumber != null)
                                        Text(
                                          debt.phoneNumber!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        const Divider(color: AppColors.borderLight, height: 1),
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
                                    ? AppColors.lentLight
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              ),
                              child: Text(
                                debt.status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: debt.status == DebtStatus.returned
                                      ? AppColors.lent
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),

                            if (debt.status != DebtStatus.returned)
                              Row(
                                children: [
                                  // Record partial payment
                                  TextButton(
                                    onPressed: () => _recordPaymentDialog(context, debt),
                                    child: const Text('To\'lov kiritish', style: TextStyle(fontSize: 12)),
                                  ),
                                  // Mark fully returned
                                  ElevatedButton(
                                    onPressed: () {
                                      HapticUtil.success();
                                      ref.read(debtsProvider.notifier).markAsReturned(debt.id);
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
    );
  }

  Widget _filterTab(int index, String title) {
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
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _recordPaymentDialog(BuildContext context, DebtItem debt) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          title: Text('${debt.personName} dan to\'lov'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'To\'langan summa',
              suffixText: 'so\'m',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(controller.text.replaceAll(' ', '')) ?? 0.0;
                if (amt > 0) {
                  ref.read(debtsProvider.notifier).recordPayment(debt.id, amt);
                  Navigator.pop(context);
                }
              },
              child: const Text('Saqlash'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isBorrowed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yangi qarz yozish',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),

                    // Toggle: Lent vs Borrowed
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Berilgan (Menga qaytaradi)')),
                            selected: !isBorrowed,
                            selectedColor: AppColors.lent,
                            labelStyle: TextStyle(
                              color: !isBorrowed ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (val) => setModalState(() => isBorrowed = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Olingan (Men qaytaraman)')),
                            selected: isBorrowed,
                            selectedColor: AppColors.borrowed,
                            labelStyle: TextStyle(
                              color: isBorrowed ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (val) => setModalState(() => isBorrowed = true),
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
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final amt = double.tryParse(amountController.text.replaceAll(' ', '')) ?? 0;
                          if (name.isNotEmpty && amt > 0) {
                            final newDebt = DebtItem(
                              id: const Uuid().v4(),
                              personName: name,
                              phoneNumber: phoneController.text.trim().isNotEmpty
                                  ? phoneController.text.trim()
                                  : null,
                              amount: amt,
                              date: DateTime.now(),
                              isBorrowed: isBorrowed,
                              note: noteController.text.trim().isNotEmpty
                                  ? noteController.text.trim()
                                  : null,
                            );
                            ref.read(debtsProvider.notifier).addDebt(newDebt);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Qo\'shish'),
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
