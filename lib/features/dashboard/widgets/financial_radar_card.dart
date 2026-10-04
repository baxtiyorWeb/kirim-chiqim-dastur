import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/intelligence/models/financial_health.dart';
import '../../../core/intelligence/providers/financial_intelligence_provider.dart';
import '../../../core/intelligence/widgets/what_if_sheet.dart';
import '../../../core/utils/haptic_feedback_util.dart';

class FinancialRadarCard extends ConsumerWidget {
  const FinancialRadarCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthState = ref.watch(financialIntelligenceProvider);

    if (healthState.radarAlerts.isEmpty) return const SizedBox.shrink();

    final primaryAlert = healthState.radarAlerts.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16191F) : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: _getRadarBorderColor(primaryAlert.type, isDark),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Radar Title & Streak Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusDotColor(primaryAlert.type),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusDotColor(primaryAlert.type).withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Moliyaviy holat',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Product-native decision metric
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${healthState.evaluatedDecisionsCount} ta qaror hisoblandi',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space12),

          // Alert Title
          Text(
            primaryAlert.title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          // Alert Description
          Text(
            primaryAlert.description,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),

          const SizedBox(height: AppDimensions.space12),

          // Actions Row: Primary Action & Calculate
          Row(
            children: [
              if (primaryAlert.actionLabel != null && primaryAlert.actionRoute != null)
                GestureDetector(
                  onTap: () {
                    HapticUtil.selection();
                    context.push(primaryAlert.actionRoute!);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        primaryAlert.actionLabel!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Quick calculate trigger
              GestureDetector(
                onTap: () => showWhatIfSimulatorSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2229) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calculate_outlined,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Xaridni hisoblash',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRadarBorderColor(RadarAlertType type, bool isDark) {
    switch (type) {
      case RadarAlertType.stable:
        return isDark ? const Color(0xFF1F382B) : const Color(0xFFC8E6C9);
      case RadarAlertType.warning:
        return isDark ? const Color(0xFF3E3316) : const Color(0xFFFFECB3);
      case RadarAlertType.danger:
        return isDark ? const Color(0xFF3E1C1C) : const Color(0xFFFFCDD2);
      case RadarAlertType.goal:
        return isDark ? const Color(0xFF1B2D3C) : const Color(0xFFBBDEFB);
    }
  }

  Color _getStatusDotColor(RadarAlertType type) {
    switch (type) {
      case RadarAlertType.stable:
        return const Color(0xFF00A86B);
      case RadarAlertType.warning:
        return const Color(0xFFFFB300);
      case RadarAlertType.danger:
        return const Color(0xFFE53935);
      case RadarAlertType.goal:
        return const Color(0xFF2196F3);
    }
  }
}
