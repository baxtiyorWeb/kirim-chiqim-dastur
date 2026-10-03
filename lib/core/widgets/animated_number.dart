import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class AnimatedCurrencyText extends StatefulWidget {
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
  State<AnimatedCurrencyText> createState() => _AnimatedCurrencyTextState();
}

class _AnimatedCurrencyTextState extends State<AnimatedCurrencyText> {
  late double _oldAmount;

  @override
  void initState() {
    super.initState();
    _oldAmount = widget.amount.toDouble();
  }

  @override
  void didUpdateWidget(covariant AnimatedCurrencyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _oldAmount = oldWidget.amount.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return Text(
        '${widget.prefix}${CurrencyFormatter.format(widget.amount, includeSymbol: widget.includeSymbol)}',
        style: widget.style,
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.amount),
      tween: Tween<double>(begin: _oldAmount, end: widget.amount.toDouble()),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, child) {
        final formatted = CurrencyFormatter.format(
          value.round(),
          includeSymbol: widget.includeSymbol,
        );
        return Text(
          '${widget.prefix}$formatted',
          style: widget.style,
        );
      },
    );
  }
}
