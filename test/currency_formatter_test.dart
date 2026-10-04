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

  group('Uzbek Compact and Adaptive Formatting Tests', () {
    test('formatCompactUz formats thousands, millions, and billions correctly', () {
      expect(CurrencyFormatter.formatCompactUz(500), '500');
      expect(CurrencyFormatter.formatCompactUz(45000), '45 ming');
      expect(CurrencyFormatter.formatCompactUz(1000000), '1 mln');
      expect(CurrencyFormatter.formatCompactUz(1500000), '1.5 mln');
      expect(CurrencyFormatter.formatCompactUz(1250000), '1.25 mln');
      expect(CurrencyFormatter.formatCompactUz(25000000), '25 mln');
      expect(CurrencyFormatter.formatCompactUz(120500000), '120.5 mln');
      expect(CurrencyFormatter.formatCompactUz(1200000000), '1.2 mlrd');
      expect(CurrencyFormatter.formatCompactUz(1500000000000), '1.5 trln');
      expect(CurrencyFormatter.formatCompactUz(1500000, includeSymbol: true), '1.5 mln so\'m');
    });

    test('formatAdaptive dynamically chooses between full som and compact notation', () {
      // Under 1,000,000 -> full format
      expect(CurrencyFormatter.formatAdaptive(50000), '50 000 so\'m');
      expect(CurrencyFormatter.formatAdaptive(950000), '950 000 so\'m');

      // >= 1,000,000 -> compact notation
      expect(CurrencyFormatter.formatAdaptive(1000000), '1 mln so\'m');
      expect(CurrencyFormatter.formatAdaptive(2500000), '2.5 mln so\'m');
      expect(CurrencyFormatter.formatAdaptive(150000000), '150 mln so\'m');
    });
  });
}
