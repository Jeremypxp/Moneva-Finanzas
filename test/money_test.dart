import 'package:moneva_finanzas/core/formatting/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.parseToCents', () {
    test('acepta punto y coma decimal', () {
      expect(Money.parseToCents('12.50'), 1250);
      expect(Money.parseToCents('12,50'), 1250);
      expect(Money.parseToCents(' 7 '), 700);
      expect(Money.parseToCents('0.5'), 50);
      expect(Money.parseToCents('10.'), 1000);
    });

    test('rechaza valores inválidos o no positivos', () {
      expect(Money.parseToCents(''), isNull);
      expect(Money.parseToCents('0'), isNull);
      expect(Money.parseToCents('0.00'), isNull);
      expect(Money.parseToCents('-5'), isNull);
      expect(Money.parseToCents('1.234'), isNull);
      expect(Money.parseToCents('1,234.56'), isNull);
      expect(Money.parseToCents('abc'), isNull);
    });
  });

  group('Money.format', () {
    test('formatea céntimos sin usar punto flotante', () {
      expect(Money.format(1250), 'S/ 12,50');
      expect(Money.format(123456), 'S/ 1.234,56');
      expect(Money.format(0), 'S/ 0,00');
      expect(Money.format(-125), '-S/ 1,25');
    });

    test('formatea con signo para listados', () {
      expect(Money.formatSigned(1250), '+ S/ 12,50');
      expect(Money.formatSigned(-1250), '- S/ 12,50');
    });
  });
}
