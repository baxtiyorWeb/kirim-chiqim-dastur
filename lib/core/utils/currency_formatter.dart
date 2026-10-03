import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,###', 'ru_RU');

  /// Formats amount into "1 250 000 so'm"
  static String format(num amount, {bool includeSymbol = true}) {
    final formatted = _formatter.format(amount).replaceAll(',', ' ');
    if (includeSymbol) {
      return '$formatted so\'m';
    }
    return formatted;
  }

  /// Formats compact amounts like "500k", "1.2M"
  static String formatCompact(num amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}M';
    } else if (amount >= 1000) {
      final val = amount / 1000;
      return '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)}k';
    }
    return amount.toString();
  }

  /// Parses text input to numeric amount
  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
