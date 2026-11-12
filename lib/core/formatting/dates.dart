import 'package:intl/intl.dart';

/// Utilidades de fechas. La app trabaja con días completos en hora local.
class AppDates {
  const AppDates._();

  // Los `DateFormat` se construyen una vez: crearlos cuesta ~26 µs por llamada
  // y se usaban en cabeceras y agrupaciones que se reconstruyen con frecuencia.
  static final DateFormat _dayMonthFormat = DateFormat('d MMM', 'es_PE');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'es_PE');
  static final DateFormat _fullDateFormat = DateFormat(
    "EEEE, d 'de' MMMM",
    'es_PE',
  );
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy', 'es_PE');
  static final DateFormat _monthYearShortFormat = DateFormat(
    'MMM yyyy',
    'es_PE',
  );

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime today() => dateOnly(DateTime.now());

  /// Lunes de la semana que contiene [value].
  static DateTime startOfWeek(DateTime value) {
    final day = dateOnly(value);
    return DateTime(day.year, day.month, day.day - (day.weekday - 1));
  }

  /// Límite exclusivo de la semana (lunes siguiente).
  static DateTime endOfWeekExclusive(DateTime value) {
    final start = startOfWeek(value);
    return DateTime(start.year, start.month, start.day + 7);
  }

  /// Primer día del mes y primer día del mes siguiente.
  static ({DateTime start, DateTime endExclusive}) monthRange(DateTime value) {
    final start = DateTime(value.year, value.month);
    return (start: start, endExclusive: DateTime(value.year, value.month + 1));
  }

  static ({DateTime start, DateTime endExclusive}) lastMonthRange(
    DateTime value,
  ) {
    final start = DateTime(value.year, value.month - 1);
    return (start: start, endExclusive: DateTime(value.year, value.month));
  }

  static ({DateTime start, DateTime endExclusive}) lastNDays(
    DateTime value,
    int days,
  ) {
    final today = dateOnly(value);
    return (
      start: DateTime(today.year, today.month, today.day - (days - 1)),
      endExclusive: DateTime(today.year, today.month, today.day + 1),
    );
  }

  static String dayMonth(DateTime value) => _dayMonthFormat.format(value);

  static String monthYear(DateTime value) => _monthYearFormat.format(value);

  static String fullDate(DateTime value) => _fullDateFormat.format(value);

  static String shortDate(DateTime value) => _shortDateFormat.format(value);

  static String dateRange(DateTime start, DateTime endExclusive) {
    final lastDay = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day - 1,
    );
    final sameMonth =
        start.month == lastDay.month && start.year == lastDay.year;
    if (sameMonth) {
      return '${start.day} – ${lastDay.day} ${_monthYearShortFormat.format(lastDay)}';
    }
    return '${dayMonth(start)} – ${dayMonth(lastDay)} ${lastDay.year}';
  }

  /// Etiqueta amable para agrupar el historial por día.
  static String historyDayLabel(DateTime value) {
    final day = dateOnly(value);
    final now = today();
    final difference = now.difference(day).inDays;
    if (difference == 0) {
      return 'Hoy';
    }
    if (difference == 1) {
      return 'Ayer';
    }
    final formatted = fullDate(day);
    return formatted.isEmpty
        ? formatted
        : '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }
}
