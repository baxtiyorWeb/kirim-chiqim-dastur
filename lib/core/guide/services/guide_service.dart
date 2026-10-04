import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../providers/finance_providers.dart';
import '../models/guide_state.dart';
import '../models/guide_step.dart';
import '../models/guide_tour.dart';
import 'guide_registry.dart';

/// Riverpod State Notifier orchestrating the entire Guided Tour lifecycle.
/// Manages state transitions, geometry calculations, auto-scrolling,
/// route-aware navigation, and persistence.
class GuideNotifier extends Notifier<GuideState> {
  @override
  GuideState build() {
    return GuideState.idle;
  }

  LocalStorageService get _storage => ref.read(localStorageProvider);

  /// Checks if a tour has already been completed by the user.
  bool isTourCompleted(String tourId) {
    return _storage.isTourCompleted(tourId);
  }

  /// Starts a guided tour if not already completed or forced.
  Future<void> startTour(
    GuideTour tour, {
    int startStep = 0,
    bool force = false,
  }) async {
    if (!force && isTourCompleted(tour.id)) {
      return;
    }

    state = GuideState(
      status: GuideStatus.preparing,
      tour: tour,
      stepIndex: startStep,
    );

    await _executeStep(tour.steps[startStep]);
  }

  /// Advances to the next step or completes the tour.
  Future<void> nextStep() async {
    if (!state.isActive || state.tour == null) return;

    if (state.isLastStep) {
      await completeTour();
    } else {
      await goToStep(state.stepIndex + 1);
    }
  }

  /// Moves to the previous step.
  Future<void> previousStep() async {
    if (!state.isActive || state.isFirstStep || state.tour == null) return;
    await goToStep(state.stepIndex - 1);
  }

  /// Jumps to a specific step index.
  Future<void> goToStep(int index) async {
    final tour = state.tour;
    if (tour == null || index < 0 || index >= tour.steps.length) return;

    state = state.copyWith(
      status: GuideStatus.preparing,
      stepIndex: index,
      clearTarget: true,
    );

    await _executeStep(tour.steps[index]);
  }

  /// Gracefully cancels/skips the tour and saves completion state.
  Future<void> skipTour() async {
    final tour = state.tour;
    if (tour == null) {
      state = GuideState.idle;
      return;
    }

    try {
      tour.onSkipped?.call();
    } catch (_) {}

    await _storage.setTourCompleted(tour.id, true);
    state = GuideState.idle;
  }

  /// Completes the tour, marks it persisted, and clears the overlay.
  Future<void> completeTour() async {
    final tour = state.tour;
    if (tour == null) {
      state = GuideState.idle;
      return;
    }

    try {
      tour.onCompleted?.call();
    } catch (_) {}

    await _storage.setTourCompleted(tour.id, true);
    state = state.copyWith(status: GuideStatus.completed);

    // Give a brief moment for outro feedback if any, then go idle
    await Future.delayed(const Duration(milliseconds: 150));
    state = GuideState.idle;
  }

  /// Resets all tour completion flags (for developer debug or user replay).
  Future<void> resetAllTours() async {
    await _storage.resetAllTours();
    state = GuideState.idle;
  }

  // -------------------------------------------------------------
  // INTERNAL STEP EXECUTION PIPELINE
  // -------------------------------------------------------------

  Future<void> _executeStep(GuideStep step) async {
    // 1. Navigation synchronization
    if (step.route != null && step.route!.isNotEmpty) {
      state = state.copyWith(status: GuideStatus.navigating);
      final navContext = AppRouter.rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        try {
          navContext.go(step.route!);
          // Allow route animation and initial tree build to settle
          await Future.delayed(const Duration(milliseconds: 280));
        } catch (_) {}
      }
    }

    // 2. Center / Dialog steps without an on-screen target
    if (step.isCenterDialog) {
      state = state.copyWith(
        status: GuideStatus.showing,
        clearTarget: true,
      );
      step.onStepAction?.call();
      return;
    }

    // 3. Wait for Target Registration in RenderTree
    state = state.copyWith(status: GuideStatus.preparing);
    final targetId = step.targetId!;
    Rect? targetRect = await GuideRegistry.instance.waitForTargetGeometry(
      targetId,
      timeout: const Duration(milliseconds: 2000),
    );

    // 4. Auto-scrolling if target is not in viewport or partially obscured
    if (step.autoScroll) {
      final targetContext = GuideRegistry.instance.getContext(targetId);
      if (targetContext != null && targetContext.mounted) {
        final scrollable = Scrollable.maybeOf(targetContext);
        if (scrollable != null) {
          state = state.copyWith(status: GuideStatus.scrolling);
          try {
            await Scrollable.ensureVisible(
              targetContext,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              alignment: 0.45,
            );
            // Settle post-scroll frame
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (_) {}
        }
      }
    }

    // 5. Measure fresh target geometry after scrolling
    final freshRect = GuideRegistry.instance.getTargetRect(targetId) ?? targetRect;

    // Fallback if target was completely missing from the view hierarchy
    if (freshRect == null || freshRect.width == 0 || freshRect.height == 0) {
      state = state.copyWith(
        status: GuideStatus.showing,
        clearTarget: true,
      );
      step.onStepAction?.call();
      return;
    }

    // 6. Calculate Spotlight Rounded Rectangle with custom padding and shape
    final RRect spotlight;
    if (step.shape == GuideTargetShape.circle) {
      final radius = max(freshRect.width, freshRect.height) / 2 +
          max(step.targetPadding.horizontal, step.targetPadding.vertical) / 2;
      spotlight = RRect.fromRectAndRadius(
        Rect.fromCircle(center: freshRect.center, radius: radius),
        Radius.circular(radius),
      );
    } else {
      final paddedRect = Rect.fromLTRB(
        freshRect.left - step.targetPadding.left,
        freshRect.top - step.targetPadding.top,
        freshRect.right + step.targetPadding.right,
        freshRect.bottom + step.targetPadding.bottom,
      );
      spotlight = RRect.fromRectAndRadius(
        paddedRect,
        Radius.circular(step.borderRadius),
      );
    }

    // 7. Update to showing state
    state = state.copyWith(
      status: GuideStatus.showing,
      targetRect: freshRect,
      spotlightRRect: spotlight,
    );

    step.onStepAction?.call();
  }
}

/// Global provider for the Guided Tour controller.
final guideControllerProvider =
    NotifierProvider<GuideNotifier, GuideState>(GuideNotifier.new);
