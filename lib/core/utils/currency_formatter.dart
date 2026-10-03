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
