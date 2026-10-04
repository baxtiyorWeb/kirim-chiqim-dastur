import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class AnimatedCurrencyText extends StatefulWidget {
  final num amount;
  final TextStyle? style;
  final bool includeSymbol;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final bool adaptive;
  final num adaptiveThreshold;
  final AlignmentGeometry alignment;

  const AnimatedCurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.includeSymbol = true,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.adaptive = true,
    this.adaptiveThreshold = 1000000,
    this.alignment = Alignment.centerLeft,
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

  String _format(num amt) {
    if (widget.adaptive) {
      return CurrencyFormatter.formatAdaptive(
        amt,
        includeSymbol: widget.includeSymbol,
        threshold: widget.adaptiveThreshold,
      );
    }
    return CurrencyFormatter.format(amt, includeSymbol: widget.includeSymbol);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: widget.alignment,
        child: Text(
          '${widget.prefix}${_format(widget.amount)}',
          style: widget.style,
          maxLines: 1,
          softWrap: false,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.amount),
      tween: Tween<double>(begin: _oldAmount, end: widget.amount.toDouble()),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, child) {
        final formatted = _format(value.round());
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: widget.alignment,
          child: Text(
            '${widget.prefix}$formatted',
            style: widget.style,
            maxLines: 1,
            softWrap: false,
          ),
        );
      },
    );
  }
}
