import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';

class CategoryDonutData {
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;

  const CategoryDonutData({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class AnimatedDonutChartWidget extends StatefulWidget {
  final List<CategoryDonutData> data;

  const AnimatedDonutChartWidget({
    super.key,
    required this.data,
  });

  @override
  State<AnimatedDonutChartWidget> createState() => _AnimatedDonutChartWidgetState();
}

class _AnimatedDonutChartWidgetState extends State<AnimatedDonutChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        // Donut Chart Custom Painter
        SizedBox(
          width: 120,
          height: 120,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _DonutChartPainter(
                  data: widget.data,
                  progress: _animation.value,
                ),
              );
            },
          ),
        ),

        const SizedBox(width: AppDimensions.space20),

        // Legend List
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.data.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    // Color indicator dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Category name
                    Expanded(
                      child: Text(
                        item.categoryName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // Percentage
                    Text(
                      '${item.percentage.round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Amount
                    Text(
                      CurrencyFormatter.format(item.amount, includeSymbol: false),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategoryDonutData> data;
  final double progress;

  _DonutChartPainter({
    required this.data,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const strokeWidth = 18.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    for (final item in data) {
      final sweepAngle = (item.percentage / 100.0) * 2 * pi * progress;

      // Leave a tiny gap between segments
      const gapAngle = 0.08;
      final adjustedSweep = max(0.0, sweepAngle - gapAngle);

      paint.color = item.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
