import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../../utils/haptic_feedback_util.dart';
import '../models/guide_step.dart';

/// Highly polished, responsive tooltip card for guide explanations.
/// Includes progress indicators, navigation buttons (Keyingi/Orqaga/O'tkazib yuborish),
/// and responsive layout constraints.
class GuideTooltipCard extends StatelessWidget {
  final GuideStep step;
  final int stepIndex;
  final int totalSteps;
  final bool isFirstStep;
  final bool isLastStep;
  final bool isDismissible;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const GuideTooltipCard({
    super.key,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.isFirstStep,
    required this.isLastStep,
    required this.isDismissible,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E2220) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3532) : const Color(0xFFE2E6E3);
    final titleColor = isDark ? Colors.white : const Color(0xFF111413);
    final descColor = isDark ? const Color(0xFF9EA6A1) : const Color(0xFF5A625D);

    final nextLabel = step.nextButtonText ?? (isLastStep ? 'Tayyor' : (step.isCenterDialog && isFirstStep ? 'Boshlash' : 'Keyingi'));
    final backLabel = step.backButtonText ?? 'Orqaga';

    return Material(
      color: Colors.transparent,
      child: Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Step Counter / Dots
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (totalSteps > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Text(
                    '${stepIndex + 1} / $totalSteps',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: descColor,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),

          // Action Controls (Skip, Back, Next)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Skip button
              if (isDismissible && !isLastStep)
                TextButton(
                  onPressed: () {
                    HapticUtil.selection();
                    onSkip();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'O‘tkazib yuborish',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: descColor,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Navigation Buttons (Back & Next)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFirstStep) ...[
                    OutlinedButton(
                      onPressed: () {
                        HapticUtil.light();
                        onBack();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        backLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  ElevatedButton(
                    onPressed: () {
                      HapticUtil.medium();
                      onNext();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nextLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
