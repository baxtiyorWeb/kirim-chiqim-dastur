import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/animated_number.dart';

class DashboardHeroCard extends StatelessWidget {
  final int totalExpenses;
  final VoidCallback? onTap;

  const DashboardHeroCard({
    super.key,
    required this.totalExpenses,
    this.onTap,
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
                  AppStrings.totalExpenses,
                  style: TextStyle(
                    color: AppColors.textWhite70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

            // Large Amount Text
            AnimatedCurrencyText(
              amount: totalExpenses,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: AppDimensions.space12),

            // Percentage Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_down_rounded,
                    color: Color(0xFF6EE7B7),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '12% o\'tgan oyga nisbatan',
                    style: TextStyle(
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
