import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/currency_formatter.dart';
import '../utils/haptic_feedback_util.dart';
import '../../providers/finance_providers.dart';
import 'app_bottom_sheets.dart';

void showInitialBalanceDialog(BuildContext context, WidgetRef ref) {
  final current = ref.read(initialBalanceProvider);
  final controller = TextEditingController(
    text: current > 0 ? CurrencyFormatter.format(current, includeSymbol: false) : '',
  );
  final colors = context.appColors;
  bool isSubmitting = false;
  bool syncWithBudget = true;

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Boshlang\'ich mablag\' va byudjet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Kiritilgan summa bir vaqtning o\'zida balansingiz va oylik byudjet asosi sifatida o\'rnatiladi. Shunda kunlik me\'yoringiz ham avtomatik hisoblab beriladi.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Mablag\' summasi',
                    hintText: 'Masalan: 5 000 000',
                    suffixText: 'so\'m',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Oylik byudjetga ham tenglashtirish',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tavsiya etiladi (kunlik xarajat me\'yori bir xil asosda hisoblanadi)',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: syncWithBudget,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => syncWithBudget = val);
                        },
                      ),
                    ],
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
                            setState(() => isSubmitting = true);
                            try {
                              await ref
                                  .read(initialBalanceProvider.notifier)
                                  .setInitialBalance(amt, syncWithBudget: syncWithBudget);
                              HapticUtil.success();
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      syncWithBudget
                                          ? 'Boshlang\'ich balans va oylik byudjet muvaffaqiyatli saqlandi (${CurrencyFormatter.format(amt)})'
                                          : 'Boshlang\'ich balans saqlandi (${CurrencyFormatter.format(amt)})',
                                    ),
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
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Saqlash',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
