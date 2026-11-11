import 'package:app_finanzas/core/formatting/dates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_PE');
  });

  test('la semana empieza el lunes y termina el domingo', () {
    final tuesday = DateTime(2026, 11, 10, 15, 30);
    expect(AppDates.dateOnly(tuesday), DateTime(2026, 11, 10));
    expect(AppDates.startOfWeek(tuesday), DateTime(2026, 11, 9));
    expect(AppDates.endOfWeekExclusive(tuesday), DateTime(2026, 11, 16));
  });

  test('el rango mensual cruza correctamente el fin de año', () {
    final december = AppDates.monthRange(DateTime(2026, 12, 20));
    expect(december.start, DateTime(2026, 12, 1));
    expect(december.endExclusive, DateTime(2027, 1, 1));

    final january = AppDates.lastMonthRange(DateTime(2027, 1, 15));
    expect(january.start, DateTime(2026, 12, 1));
    expect(january.endExclusive, DateTime(2027, 1, 1));
  });

  test('los últimos 30 días incluyen hoy', () {
    final range = AppDates.lastNDays(DateTime(2026, 11, 10, 23), 30);
    expect(range.start, DateTime(2026, 10, 12));
    expect(range.endExclusive, DateTime(2026, 11, 11));
  });

  test('las etiquetas usan español', () {
    expect(AppDates.shortDate(DateTime(2026, 11, 10)), '10/11/2026');
    expect(
      AppDates.dateRange(DateTime(2026, 11, 1), DateTime(2026, 12, 1)),
      contains('nov'),
    );
    expect(AppDates.historyDayLabel(DateTime.now()), 'Hoy');
  });
}
