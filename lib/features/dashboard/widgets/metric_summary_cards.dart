import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/animated_number.dart';

class MetricSummaryCards extends StatelessWidget {
  final double thisMonthExpense;
  final double remainingBudget;
  final VoidCallback? onMonthTap;
  final VoidCallback? onRemainingTap;

  const MetricSummaryCards({
    super.key,
    required this.thisMonthExpense,
    required this.remainingBudget,
    this.onMonthTap,
    this.onRemainingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Card: "Bu oy"
        Expanded(
          child: _MetricCard(
            label: AppStrings.thisMonth,
            amount: thisMonthExpense,
            icon: Icons.calendar_month_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            onTap: onMonthTap,
          ),
        ),

        const SizedBox(width: AppDimensions.space12),

        // Right Card: "Qolgan mablag'"
        Expanded(
          child: _MetricCard(
            label: AppStrings.remainingBudget,
            amount: remainingBudget,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            onTap: onRemainingTap,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: label and icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: iconColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space12),

            // Amount
            AnimatedCurrencyText(
              amount: amount,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
