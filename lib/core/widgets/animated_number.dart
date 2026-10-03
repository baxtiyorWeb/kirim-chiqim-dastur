import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class AnimatedCurrencyText extends StatelessWidget {
  final num amount;
  final TextStyle? style;
  final bool includeSymbol;
  final Duration duration;
  final Curve curve;
  final String prefix;

  const AnimatedCurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.includeSymbol = true,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        final formatted = CurrencyFormatter.format(
          value.round(),
          includeSymbol: includeSymbol,
        );
        return Text(
          '$prefix$formatted',
          style: style,
        );
      },
    );
  }
}
