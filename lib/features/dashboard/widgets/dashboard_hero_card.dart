import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/intelligence/models/financial_health.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/animated_number.dart';

class DashboardHeroCard extends StatelessWidget {
  final int balance;
  final int initialBalance;
  final int totalExpenses;
  final int safeToSpendToday;
  final FinancialRiskLevel riskLevel;
  final VoidCallback? onTap;
  final VoidCallback? onSimulatorTap;
  final VoidCallback? onBreakdownTap;

  const DashboardHeroCard({
    super.key,
    required this.balance,
    this.initialBalance = 0,
    this.totalExpenses = 0,
    this.safeToSpendToday = 0,
    this.riskLevel = FinancialRiskLevel.safe,
    this.onTap,
    this.onSimulatorTap,
    this.onBreakdownTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.space20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusExtraLarge),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGradientStart,
              AppColors.primaryGradientEnd,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Label & Financial Health Status Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.totalBalance,
                  style: TextStyle(
                    color: AppColors.textWhite70,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBreakdownTap,
                  child: _buildHealthStatus(),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space8),

            // Large Amount Text (Umumiy balans)
            AnimatedCurrencyText(
              amount: balance,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: AppDimensions.space12),

            // Daily spending norm & Calculate action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBreakdownTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Bugungi xarajat me\'yori',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.help_outline_rounded,
                                size: 12.5,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyFormatter.format(safeToSpendToday)} / kun',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onSimulatorTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4.5),
                          Text(
                            'Tekshirish',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatus() {
    Color dotColor;
    String statusText;

    switch (riskLevel) {
      case FinancialRiskLevel.safe:
        dotColor = const Color(0xFF34D399);
        statusText = 'Holat barqaror';
        break;
      case FinancialRiskLevel.caution:
        dotColor = const Color(0xFFFBBF24);
        statusText = 'E\'tibor talab';
        break;
      case FinancialRiskLevel.danger:
        dotColor = const Color(0xFFF87171);
        statusText = 'Xavfli xarajat';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
