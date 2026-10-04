import 'package:flutter/foundation.dart';
import 'guide_step.dart';

/// Strongly typed definition of an entire guided tour.
class GuideTour {
  final String id;
  final String title;
  final List<GuideStep> steps;
  final bool isDismissible;
  final VoidCallback? onCompleted;
  final VoidCallback? onSkipped;

  const GuideTour({
    required this.id,
    required this.title,
    required this.steps,
    this.isDismissible = true,
    this.onCompleted,
    this.onSkipped,
  });

  int get totalSteps => steps.length;
}
