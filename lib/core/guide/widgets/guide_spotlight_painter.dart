import 'package:flutter/material.dart';

/// High-performance CustomPainter drawing the darkened backdrop
/// and the crisp, smooth rounded cutout for the active target.
/// Uses GPU-accelerated PathFillType.evenOdd for 60/120 FPS rendering.
class GuideSpotlightPainter extends CustomPainter {
  final RRect? spotlightRRect;
  final Color backdropColor;
  final Color? borderColor;
  final double borderWidth;

  GuideSpotlightPainter({
    required this.spotlightRRect,
    required this.backdropColor,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backdropPaint = Paint()
      ..color = backdropColor
      ..style = PaintingStyle.fill;

    if (spotlightRRect == null || spotlightRRect!.isEmpty) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backdropPaint);
      return;
    }

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(spotlightRRect!);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backdropPaint);

    if (borderColor != null && borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawRRect(spotlightRRect!, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GuideSpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRRect != spotlightRRect ||
        oldDelegate.backdropColor != backdropColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
