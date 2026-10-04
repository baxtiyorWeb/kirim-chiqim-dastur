import 'package:flutter/material.dart';
import 'guide_step.dart';
import 'guide_tour.dart';

enum GuideStatus {
  idle,
  preparing,
  navigating,
  scrolling,
  showing,
  animating,
  completed,
}

/// Immutable state snapshot of the active guided tour.
class GuideState {
  final GuideStatus status;
  final GuideTour? tour;
  final int stepIndex;
  final Rect? targetRect;
  final RRect? spotlightRRect;
  final String? errorMessage;

  const GuideState({
    this.status = GuideStatus.idle,
    this.tour,
    this.stepIndex = 0,
    this.targetRect,
    this.spotlightRRect,
    this.errorMessage,
  });

  bool get isActive =>
      status != GuideStatus.idle && status != GuideStatus.completed && tour != null;

  GuideStep? get currentStep {
    if (tour == null || stepIndex < 0 || stepIndex >= tour!.steps.length) {
      return null;
    }
    return tour!.steps[stepIndex];
  }

  int get totalSteps => tour?.totalSteps ?? 0;
  bool get isFirstStep => stepIndex == 0;
  bool get isLastStep => tour != null && stepIndex == tour!.totalSteps - 1;

  double get progressRatio =>
      totalSteps > 0 ? (stepIndex + 1) / totalSteps.toDouble() : 0.0;

  String get stepCounterLabel => '${stepIndex + 1} / $totalSteps';

  GuideState copyWith({
    GuideStatus? status,
    GuideTour? tour,
    int? stepIndex,
    Rect? targetRect,
    RRect? spotlightRRect,
    String? errorMessage,
    bool clearTarget = false,
  }) {
    return GuideState(
      status: status ?? this.status,
      tour: tour ?? this.tour,
      stepIndex: stepIndex ?? this.stepIndex,
      targetRect: clearTarget ? null : (targetRect ?? this.targetRect),
      spotlightRRect: clearTarget ? null : (spotlightRRect ?? this.spotlightRRect),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static const GuideState idle = GuideState();
}
