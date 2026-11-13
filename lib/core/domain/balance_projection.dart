import 'movement_type.dart';
import 'period_totals.dart';

/// Proyección del balance de un periodo al registrar un movimiento.
///
/// No consulta la base de datos: recibe los totales actuales del periodo y
/// aplica el movimiento. Si se está editando uno que ya pertenece al periodo,
/// [replacedType]/[replacedAmountCents] descuentan su aporte anterior para no
/// contarlo dos veces.
class PeriodProjection {
  const PeriodProjection({
    required this.type,
    required this.baseline,
    required this.projected,
  });

  final MovementType type;

  /// Totales del periodo sin el movimiento que se reemplaza (si lo hay).
  final PeriodTotals baseline;

  /// Totales del periodo después de aplicar el movimiento.
  final PeriodTotals projected;

  int get balanceCents => projected.balanceCents;

  /// Solo los gastos pueden dejar el periodo en negativo.
  bool get shouldWarn => type.isExpense && balanceCents < 0;
}

/// Calcula los totales de un periodo tras registrar [type]/[amountCents].
///
/// [current] son los totales reales del periodo. Cuando se edita un movimiento
/// que ya está dentro de ese periodo, sus valores anteriores deben indicarse en
/// [replacedType] y [replacedAmountCents] para descontarlos antes de aplicar el
/// nuevo borrador.
PeriodProjection projectPeriod({
  required PeriodTotals current,
  required MovementType type,
  required int amountCents,
  MovementType? replacedType,
  int? replacedAmountCents,
}) {
  final amount = amountCents < 0 ? 0 : amountCents;
  var income = current.incomeCents;
  var expense = current.expenseCents;

  if (replacedType != null && replacedAmountCents != null) {
    final replaced = replacedAmountCents < 0 ? 0 : replacedAmountCents;
    if (replacedType.isExpense) {
      expense = _nonNegative(expense - replaced);
    } else {
      income = _nonNegative(income - replaced);
    }
  }

  final baseline = PeriodTotals(incomeCents: income, expenseCents: expense);
  final projected = PeriodTotals(
    incomeCents: income + (type.isExpense ? 0 : amount),
    expenseCents: expense + (type.isExpense ? amount : 0),
  );

  return PeriodProjection(type: type, baseline: baseline, projected: projected);
}

int _nonNegative(int value) => value < 0 ? 0 : value;
