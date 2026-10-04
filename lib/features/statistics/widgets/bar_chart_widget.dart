import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/haptic_feedback_util.dart';

class MonthlyBarData {
  final String monthLabel;
  final num amount;
  final bool isSelected;

  const MonthlyBarData({
    required this.monthLabel,
    required this.amount,
    this.isSelected = false,
  });
}

class AnimatedBarChartWidget extends StatefulWidget {
  final List<MonthlyBarData> data;
  final Function(int)? onBarSelected;

  const AnimatedBarChartWidget({
    super.key,
    required this.data,
    this.onBarSelected,
  });

  @override
  State<AnimatedBarChartWidget> createState() => _AnimatedBarChartWidgetState();
}

class _AnimatedBarChartWidgetState extends State<AnimatedBarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.data.isNotEmpty ? widget.data.length - 1 : 0;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBarChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.length != oldWidget.data.length) {
      _selectedIndex = widget.data.isNotEmpty ? widget.data.length - 1 : 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;

    final maxVal = widget.data
        .map((e) => e.amount)
        .reduce((curr, next) => curr > next ? curr : next);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.data.length, (index) {
              final item = widget.data[index];
              final isCurrent = index == _selectedIndex;
              final normalizedHeight = maxVal > 0 ? (item.amount / maxVal) : 0.0;
              final barHeight = (normalizedHeight * 110.0 * _animation.value).clamp(8.0, 110.0);

              return GestureDetector(
                onTap: () {
                  HapticUtil.selection();
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onBarSelected?.call(index);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tooltip Badge if selected
                    if (isCurrent)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.formatCompactUz(item.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 24),

                    // Rounded Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 14,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary
                            : colors.chartInactive,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Month label
                    Text(
                      item.monthLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
