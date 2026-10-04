import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../models/guide_state.dart';
import '../models/guide_step.dart';
import '../services/guide_service.dart';
import 'guide_spotlight_painter.dart';
import 'guide_tooltip_card.dart';

/// Top-level full screen overlay that renders the animated spotlight cutout,
/// dimmed backdrop, and responsive contextual tooltip.
class GuideOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const GuideOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<GuideOverlay> createState() => _GuideOverlayState();
}

class _GuideOverlayState extends ConsumerState<GuideOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guideState = ref.watch(guideControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (guideState.isActive && !_animController.isAnimating && _animController.value == 0.0) {
      _animController.forward();
    } else if (!guideState.isActive && _animController.value > 0.0) {
      _animController.reverse();
    }

    return Stack(
      children: [
        // Underlying Application Screen
        widget.child,

        // Guided Tour Layer
        if (guideState.isActive)
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (guideState.isFirstStep) {
                ref.read(guideControllerProvider.notifier).skipTour();
              } else {
                ref.read(guideControllerProvider.notifier).previousStep();
              }
            },
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTourContent(context, guideState, isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildTourContent(
    BuildContext context,
    GuideState state,
    bool isDark,
  ) {
    final step = state.currentStep;
    if (step == null) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final spotlight = state.spotlightRRect ?? RRect.zero;

    final backdropColor = isDark
        ? Colors.black.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.65);

    return TweenAnimationBuilder<RRect>(
      tween: _RRectTween(begin: spotlight, end: spotlight),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      builder: (context, animatedRRect, _) {
        return Stack(
          children: [
            // 1. Dimmed Background with Cutout (absorbs background taps)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Absorb taps on backdrop so user doesn't accidentally trigger background buttons
                },
                child: CustomPaint(
                  painter: GuideSpotlightPainter(
                    spotlightRRect: animatedRRect.isEmpty ? null : animatedRRect,
                    backdropColor: backdropColor,
                    borderColor: AppColors.primary.withValues(alpha: 0.9),
                    borderWidth: 2.0,
                  ),
                ),
              ),
            ),

            // 2. Interactive Passthrough (if enabled on step)
            if (step.isInteractive && !animatedRRect.isEmpty)
              Positioned.fromRect(
                rect: animatedRRect.outerRect,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    ref.read(guideControllerProvider.notifier).nextStep();
                  },
                ),
              ),

            // 3. Contextual Tooltip Positioning
            if (step.isCenterDialog || state.spotlightRRect == null)
              _buildCenterDialog(context, step, state)
            else
              _buildAnchoredTooltip(
                context: context,
                step: step,
                state: state,
                spotlight: state.spotlightRRect!,
                size: size,
                padding: padding,
              ),
          ],
        );
      },
    );
  }

  Widget _buildCenterDialog(
    BuildContext context,
    GuideStep step,
    GuideState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: GuideTooltipCard(
            step: step,
            stepIndex: state.stepIndex,
            totalSteps: state.totalSteps,
            isFirstStep: state.isFirstStep,
            isLastStep: state.isLastStep,
            isDismissible: state.tour?.isDismissible ?? true,
            onNext: () => ref.read(guideControllerProvider.notifier).nextStep(),
            onBack: () => ref.read(guideControllerProvider.notifier).previousStep(),
            onSkip: () => ref.read(guideControllerProvider.notifier).skipTour(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnchoredTooltip({
    required BuildContext context,
    required GuideStep step,
    required GuideState state,
    required RRect spotlight,
    required Size size,
    required EdgeInsets padding,
  }) {
    // Determine whether to place above or below
    final spaceAbove = spotlight.top - padding.top;
    final spaceBelow = size.height - padding.bottom - spotlight.bottom;

    bool placeBelow = true;
    if (step.placement == GuidePlacement.top) {
      placeBelow = false;
    } else if (step.placement == GuidePlacement.bottom) {
      placeBelow = true;
    } else {
      // Auto placement: pick side with most breathing room
      placeBelow = spaceBelow >= 220 || spaceBelow >= spaceAbove;
    }

    final double verticalTop;
    if (placeBelow) {
      verticalTop = min(spotlight.bottom + 14, size.height - padding.bottom - 220);
    } else {
      verticalTop = max(padding.top + 16, spotlight.top - 230);
    }

    // Horizontal positioning (clamped with 16px gutter on both sides)
    const double horizontalMargin = 16.0;

    return Positioned(
      top: verticalTop,
      left: horizontalMargin,
      right: horizontalMargin,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GuideTooltipCard(
            step: step,
            stepIndex: state.stepIndex,
            totalSteps: state.totalSteps,
            isFirstStep: state.isFirstStep,
            isLastStep: state.isLastStep,
            isDismissible: state.tour?.isDismissible ?? true,
            onNext: () => ref.read(guideControllerProvider.notifier).nextStep(),
            onBack: () => ref.read(guideControllerProvider.notifier).previousStep(),
            onSkip: () => ref.read(guideControllerProvider.notifier).skipTour(),
          ),
        ),
      ),
    );
  }
}

/// Custom Tween smoothly interpolating between two rounded rectangles
class _RRectTween extends Tween<RRect> {
  _RRectTween({required super.begin, required super.end});

  @override
  RRect lerp(double t) {
    final b = begin ?? RRect.zero;
    final e = end ?? RRect.zero;
    if (b.isEmpty) return e;
    if (e.isEmpty) return b;
    return RRect.lerp(b, e, t) ?? RRect.zero;
  }
}
