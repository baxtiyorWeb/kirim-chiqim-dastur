import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/haptic_feedback_util.dart';
import '../models/financial_health.dart';
import 'what_if_sheet.dart';

/// Shows the transparent mathematical breakdown for "Bugungi xarajat me'yori"
Future<void> showCalculationBreakdownSheet(
  BuildContext context,
  FinancialHealthState healthState,
) {
  HapticUtil.selection();
  final colors = context.appColors;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusExtraLarge),
          ),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          top: AppDimensions.space16,
          left: AppDimensions.space20,
          right: AppDimensions.space20,
          bottom: MediaQuery.paddingOf(ctx).bottom + AppDimensions.space20,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qanday hisoblandi?',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Bugungi xarajat me\'yori asoslari',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
                    splashRadius: 20,
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space16),

              // Highlight Card: Today's Limit
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF132F23), const Color(0xFF0D2118)]
                        : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bugungi xarajat me\'yori',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.format(healthState.safeToSpendToday)} / kun',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF065F46),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // Step-by-step arithmetic breakdown
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191C22) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hisoblash asoslari',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Balance
                    _buildRow(
                      label: 'Qolgan jami mablag\'',
                      value: CurrencyFormatter.format(healthState.balance),
                      color: colors.textPrimary,
                      prefix: '+ ',
                      isBold: true,
                    ),
                    const SizedBox(height: 8),

                    // 2. Debts
                    _buildRow(
                      label: 'Kelajakdagi to\'lovlar (qarzlar)',
                      value: CurrencyFormatter.format(healthState.upcomingDebts),
                      color: healthState.upcomingDebts > 0 ? Colors.amber.shade700 : colors.textSecondary,
                      prefix: '- ',
                    ),
                    const SizedBox(height: 8),

                    // 3. Goals
                    _buildRow(
                      label: 'Maqsadlar uchun zaxira',
                      value: CurrencyFormatter.format(healthState.goalsAllocation),
                      color: healthState.goalsAllocation > 0 ? AppColors.primary : colors.textSecondary,
                      prefix: '- ',
                    ),
                    const SizedBox(height: 8),

                    // 4. Safety buffer
                    _buildRow(
                      label: 'Xavfsizlik zaxirasi',
                      value: CurrencyFormatter.format(healthState.safetyBuffer),
                      color: colors.textSecondary,
                      prefix: '- ',
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),

                    // 5. Spendable cash
                    _buildRow(
                      label: 'Erkin sarflash mumkin',
                      value: CurrencyFormatter.format(healthState.spendableAmount),
                      color: const Color(0xFF10B981),
                      prefix: '= ',
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space12),

              // Formula card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oydan qolgan ${healthState.daysRemainingInMonth} kunlik me\'yor formulasi:',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.format(healthState.spendableAmount)} ÷ ${healthState.daysRemainingInMonth} kun ≈ ${CurrencyFormatter.format(healthState.safeToSpendToday)} / kun',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space12),

              // Trust explanation note
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ushbu raqam sizning barcha majburiyatlaringiz va zaxirangiz saqlangan holda bugun xotirjam sarflashingiz mumkin bo\'lgan xavfsiz chegarani bildiradi.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.space16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showWhatIfSimulatorSheet(context);
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text('Xaridni tekshirish', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticUtil.selection();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                      ),
                      child: const Text('Tushunarli', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildRow({
  required String label,
  required String value,
  required Color color,
  String prefix = '',
  bool isBold = false,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        '$prefix$value',
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    ],
  );
}
