import 'package:flutter/material.dart';

enum GuidePlacement {
  auto,
  top,
  bottom,
  center,
}

enum GuideTargetShape {
  rrect,
  circle,
}

/// Strongly typed definition of a single step in a guided tour.
class GuideStep {
  final String id;
  final String? targetId;
  final String title;
  final String description;
  final String? route;
  final int? tabIndex;
  final GuidePlacement placement;
  final GuideTargetShape shape;
  final double borderRadius;
  final EdgeInsets targetPadding;
  final bool isInteractive;
  final bool autoScroll;
  final String? nextButtonText;
  final String? backButtonText;
  final VoidCallback? onStepAction;

  const GuideStep({
    required this.id,
    this.targetId,
    required this.title,
    required this.description,
    this.route,
    this.tabIndex,
    this.placement = GuidePlacement.auto,
    this.shape = GuideTargetShape.rrect,
    this.borderRadius = 16.0,
    this.targetPadding = const EdgeInsets.all(6.0),
    this.isInteractive = false,
    this.autoScroll = true,
    this.nextButtonText,
    this.backButtonText,
    this.onStepAction,
  });

  bool get isCenterDialog => targetId == null || placement == GuidePlacement.center;
}
