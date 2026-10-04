import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Production grade currency formatter for Uzbek So'm (UZS).
/// Enforces integer arithmetic to prevent floating point inaccuracies.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,###', 'ru_RU');

  /// Formats amount into "1 250 000 so'm" or "1 250 000"
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

  /// Formats compact amounts like "500k", "1.2M", "15M"
  static String formatCompact(num amount) {
    final double absVal = amount.abs().toDouble();
    final String sign = amount < 0 ? '-' : '';

    if (absVal >= 1000000000) {
      final val = absVal / 1000000000;
      return '$sign${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}B';
    } else if (absVal >= 1000000) {
      final val = absVal / 1000000;
      return '$sign${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (absVal >= 1000) {
      final val = absVal / 1000;
      return '$sign${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}k';
    }
    return '$sign${absVal.toInt()}';
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
