import 'package:app_finanzas/core/domain/movement_type.dart';
import 'package:app_finanzas/features/movements/domain/movement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_PE');
  });

  test('el filtro inicial es el mes actual', () {
    final filter = MovementFilter.initial(DateTime(2026, 11, 10));
    expect(filter.preset, MovementPeriodPreset.currentMonth);
    expect(filter.start, DateTime(2026, 11, 1));
    expect(filter.endExclusive, DateTime(2026, 12, 1));
    expect(filter.type, isNull);
    expect(filter.categoryId, isNull);
  });

  test('cambiar de tipo conserva el periodo', () {
    final filter = MovementFilter.initial(DateTime(2026, 11, 10))
        .withType(MovementType.income);
    expect(filter.type, MovementType.income);
    expect(filter.start, DateTime(2026, 11, 1));
    expect(filter.endExclusive, DateTime(2026, 12, 1));
  });

  test('el rango personalizado muestra su etiqueta', () {
    final filter = MovementFilter.initial(DateTime(2026, 11, 10)).withRange(
      MovementPeriodPreset.custom,
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 20),
    );
    expect(filter.preset, MovementPeriodPreset.custom);
    expect(filter.rangeLabel, contains('oct'));
  });
}
