import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:thego_getters/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyInputFormatter Tests', () {
    final formatter = CurrencyInputFormatter();

    test('Formats digits into space-separated thousands', () {
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '50000',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(res.text, '50 000');
      expect(res.selection.baseOffset, 6);
    });

    test('Formats 1000000 into 1 000 000', () {
      final res = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1000000',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      expect(res.text, '1 000 000');
      expect(res.selection.baseOffset, 9);
    });

    test('Handles empty input gracefully', () {
      final res = formatter.formatEditUpdate(
        const TextEditingValue(text: '50', selection: TextSelection.collapsed(offset: 2)),
        const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0)),
      );
      expect(res.text, '');
      expect(res.selection.baseOffset, 0);
    });

    test('CurrencyFormatter.parse correctly parses formatted text', () {
      expect(CurrencyFormatter.parse('1 000 000'), 1000000);
      expect(CurrencyFormatter.parse('50 000 so\'m'), 50000);
      expect(CurrencyFormatter.parse(''), 0);
    });
  });
}
