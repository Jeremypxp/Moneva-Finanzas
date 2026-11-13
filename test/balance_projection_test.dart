import 'package:flutter_test/flutter_test.dart';
import 'package:moneva_finanzas/core/domain/balance_projection.dart';
import 'package:moneva_finanzas/core/domain/movement_type.dart';
import 'package:moneva_finanzas/core/domain/period_totals.dart';

void main() {
  group('projectPeriod', () {
    test('un gasto que deja el balance negativo debe advertir', () {
      final projection = projectPeriod(
        current: const PeriodTotals(incomeCents: 10000, expenseCents: 0),
        type: MovementType.expense,
        amountCents: 12000,
      );

      expect(projection.projected.incomeCents, 10000);
      expect(projection.projected.expenseCents, 12000);
      expect(projection.balanceCents, -2000);
      expect(projection.shouldWarn, isTrue);
    });

    test('un gasto que deja el balance exactamente en cero no advierte', () {
      final projection = projectPeriod(
        current: const PeriodTotals(incomeCents: 10000, expenseCents: 0),
        type: MovementType.expense,
        amountCents: 10000,
      );

      expect(projection.balanceCents, 0);
      expect(projection.shouldWarn, isFalse);
    });

    test('un gasto dentro de los ingresos registrados no advierte', () {
      final projection = projectPeriod(
        current: const PeriodTotals(incomeCents: 10000, expenseCents: 0),
        type: MovementType.expense,
        amountCents: 9999,
      );

      expect(projection.balanceCents, 1);
      expect(projection.shouldWarn, isFalse);
    });

    test('un ingreso nunca advierte y suma al balance', () {
      final projection = projectPeriod(
        current: const PeriodTotals(incomeCents: 0, expenseCents: 5000),
        type: MovementType.income,
        amountCents: 7000,
      );

      expect(projection.balanceCents, 2000);
      expect(projection.shouldWarn, isFalse);
    });

    test('al editar descuenta el movimiento anterior del mismo periodo', () {
      // Totales reales: 100 de ingreso y 120 de gasto (el movimiento editado).
      final projection = projectPeriod(
        current: const PeriodTotals(incomeCents: 10000, expenseCents: 12000),
        type: MovementType.expense,
        amountCents: 11000,
        replacedType: MovementType.expense,
        replacedAmountCents: 12000,
      );

      expect(projection.baseline.balanceCents, 10000);
      expect(projection.balanceCents, -1000);
      expect(projection.shouldWarn, isTrue);
    });

    test('editar a la baja sin volver a negativo no advierte', () {
      final projection = projectPeriod(
        current: const PeriodTotals(incomeCents: 10000, expenseCents: 12000),
        type: MovementType.expense,
        amountCents: 8000,
        replacedType: MovementType.expense,
        replacedAmountCents: 12000,
      );

      expect(projection.baseline.balanceCents, 10000);
      expect(projection.balanceCents, 2000);
      expect(projection.shouldWarn, isFalse);
    });

    test('convertir un ingreso en gasto usa la línea base sin el anterior', () {
      final projection = projectPeriod(
        current: const PeriodTotals(incomeCents: 10000, expenseCents: 0),
        type: MovementType.expense,
        amountCents: 12000,
        replacedType: MovementType.income,
        replacedAmountCents: 10000,
      );

      expect(projection.baseline.incomeCents, 0);
      expect(projection.baseline.expenseCents, 0);
      expect(projection.balanceCents, -12000);
      expect(projection.shouldWarn, isTrue);
    });

    test('no modifica los totales recibidos y tolera datos incoherentes', () {
      const current = PeriodTotals(incomeCents: 5000, expenseCents: 1000);
      final projection = projectPeriod(
        current: current,
        type: MovementType.expense,
        amountCents: 200,
        replacedType: MovementType.expense,
        replacedAmountCents: 9000,
      );

      expect(current.incomeCents, 5000);
      expect(current.expenseCents, 1000);
      expect(projection.baseline.expenseCents, 0);
      expect(projection.balanceCents, 4800);
      expect(projection.shouldWarn, isFalse);
    });

    test('un importe negativo no mejora el balance proyectado', () {
      final projection = projectPeriod(
        current: const PeriodTotals(incomeCents: 0, expenseCents: 100),
        type: MovementType.expense,
        amountCents: -500,
      );

      expect(projection.balanceCents, -100);
    });
  });
}
