import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/animated_number.dart';

class DashboardHeroCard extends StatelessWidget {
  final int balance;
  final int initialBalance;
  final int totalExpenses;
  final int safeToSpendToday;
  final VoidCallback? onTap;
  final VoidCallback? onSimulatorTap;

  const DashboardHeroCard({
    super.key,
    required this.balance,
    this.initialBalance = 0,
    required this.totalExpenses,
    this.safeToSpendToday = 0,
    this.onTap,
    this.onSimulatorTap,
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
            // Top Row: Label & Sparkline Chart Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.totalBalance,
                  style: TextStyle(
                    color: AppColors.textWhite70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                // Sparkline / Bar mini indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _miniBar(8, Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 3),
                      _miniBar(14, Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 3),
                      _miniBar(18, Colors.white),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space12),

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF34D399),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bugungi xarajat me\'yori',
                          style: TextStyle(
                            color: AppColors.textWhite70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${CurrencyFormatter.format(safeToSpendToday)} / kun',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onSimulatorTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Hisoblash',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11.5,
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

            const SizedBox(height: AppDimensions.space12),

            // Sub-info Row: Boshlang'ich & Bu oy xarajat
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (initialBalance > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    ),
                    child: Text(
                      'Boshlang\'ich: ${CurrencyFormatter.format(initialBalance)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_down_rounded,
                        color: Color(0xFF6EE7B7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bu oy xarajat: -${CurrencyFormatter.format(totalExpenses)}',
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBar(double height, Color color) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
