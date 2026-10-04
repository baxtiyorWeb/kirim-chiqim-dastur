import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Production grade currency formatter for Uzbek So'm (UZS).
/// Enforces integer arithmetic to prevent floating point inaccuracies.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,###', 'ru_RU');

  /// Formats amount into standard full representation: "1 250 000 so'm" or "1 250 000"
  /// Safe for both int and num, rounding to whole integer Uzbek so'm.
  static String format(num amount, {bool includeSymbol = true}) {
    final int wholeAmount = amount.round();
    final formatted = _formatter
        .format(wholeAmount)
        .replaceAll('\u00A0', ' ')
        .replaceAll(',', ' ');
    if (includeSymbol) {
      return '$formatted so\'m';
    }
    return formatted;
  }

  /// Formats large numbers compactly in Uzbek financial notation:
  /// Examples:
  /// - 500 -> "500"
  /// - 45 000 -> "45 ming"
  /// - 1 000 000 -> "1 mln"
  /// - 1 500 000 -> "1.5 mln"
  /// - 1 250 000 -> "1.25 mln"
  /// - 25 000 000 -> "25 mln"
  /// - 120 500 000 -> "120.5 mln"
  /// - 1 200 000 000 -> "1.2 mlrd"
  /// - 1 500 000 000 000 -> "1.5 trln"
  static String formatCompactUz(num amount, {bool includeSymbol = false}) {
    final double absVal = amount.abs().toDouble();
    final String sign = amount < 0 ? '-' : '';

    String numStr;
    String unit;

    if (absVal >= 1000000000000) { // Trillion
      final val = absVal / 1000000000000;
      numStr = _formatDecimal(val);
      unit = 'trln';
    } else if (absVal >= 1000000000) { // Milliard / Billion
      final val = absVal / 1000000000;
      numStr = _formatDecimal(val);
      unit = 'mlrd';
    } else if (absVal >= 1000000) { // Million
      final val = absVal / 1000000;
      numStr = _formatDecimal(val);
      unit = 'mln';
    } else if (absVal >= 10000) { // Ming
      final val = absVal / 1000;
      numStr = _formatDecimal(val);
      unit = 'ming';
    } else {
      numStr = _formatter.format(absVal.round()).replaceAll('\u00A0', ' ').replaceAll(',', ' ');
      unit = '';
    }

    final combined = unit.isEmpty ? '$sign$numStr' : '$sign$numStr $unit';
    if (includeSymbol) {
      return '$combined so\'m';
    }
    return combined;
  }

  /// Compact English/Global notation (e.g. "500k", "1.5M", "1.2B")
  static String formatCompact(num amount, {bool useUzbek = true}) {
    if (useUzbek) {
      return formatCompactUz(amount);
    }
    final double absVal = amount.abs().toDouble();
    final String sign = amount < 0 ? '-' : '';

    if (absVal >= 1000000000) {
      final val = absVal / 1000000000;
      return '$sign${_formatDecimal(val)}B';
    } else if (absVal >= 1000000) {
      final val = absVal / 1000000;
      return '$sign${_formatDecimal(val)}M';
    } else if (absVal >= 1000) {
      final val = absVal / 1000;
      return '$sign${_formatDecimal(val)}k';
    }
    return '$sign${absVal.toInt()}';
  }

  static String _formatDecimal(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    String str;
    if (val < 10) {
      str = val.toStringAsFixed(2);
    } else {
      str = val.toStringAsFixed(1);
    }

    // Strip trailing zeros: 1.50 -> 1.5, 2.0 -> 2
    if (str.contains('.')) {
      while (str.endsWith('0')) {
        str = str.substring(0, str.length - 1);
      }
      if (str.endsWith('.')) {
        str = str.substring(0, str.length - 1);
      }
    }
    return str;
  }

  /// Adaptive Formatter:
  /// - Automatically switches to compact Uzbek notation ("1.5 mln so'm", "25 mln so'm")
  ///   when the number reaches or exceeds [threshold] (default 1,000,000 UZS) to prevent UI overflows.
  /// - For amounts below [threshold], retains full clarity (e.g. "45 000 so'm").
  static String formatAdaptive(
    num amount, {
    bool includeSymbol = true,
    num threshold = 1000000,
  }) {
    if (amount.abs() >= threshold) {
      return formatCompactUz(amount, includeSymbol: includeSymbol);
    }
    return format(amount, includeSymbol: includeSymbol);
  }

  /// Parses text input to whole integer amount safely
  static int parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }

  /// Formats input while typing with thousand spaces
  static String formatTyping(String rawText) {
    final parsed = parse(rawText);
    if (parsed == 0) return '';
    return format(parsed, includeSymbol: false);
  }
}

/// Real-time automatic currency input formatter that inserts thousand space separators
/// (e.g. 50000 -> "50 000", 1000000 -> "1 000 000") while precisely maintaining cursor position.
class CurrencyInputFormatter extends TextInputFormatter {
  final int maxDigits;

  CurrencyInputFormatter({this.maxDigits = 14}); // Up to 99 trillion UZS

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Strip non-digits
    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Limit maximum digits
    if (cleanText.length > maxDigits) {
      cleanText = cleanText.substring(0, maxDigits);
    }

    // Parse number
    final number = int.tryParse(cleanText);
    if (number == null) {
      return oldValue;
    }

    final formatted = CurrencyFormatter.format(number, includeSymbol: false);

    // Calculate how many digits were before the cursor in newValue
    int cursorPosition = newValue.selection.end;
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPosition && i < newValue.text.length; i++) {
      if (RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

    if (digitsBeforeCursor > cleanText.length) {
      digitsBeforeCursor = cleanText.length;
    }

    // Map digit count to cursor index in formatted string
    int newCursor = 0;
    int currentDigits = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        currentDigits++;
      }
      if (currentDigits == digitsBeforeCursor) {
        newCursor = i + 1;
        break;
      }
    }

    if (digitsBeforeCursor == 0) {
      newCursor = 0;
    }
    if (newCursor > formatted.length) {
      newCursor = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }
}
