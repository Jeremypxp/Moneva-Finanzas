import '../../../core/domain/category.dart';
import '../../../core/formatting/dates.dart';

class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.totalCents,
    required this.share,
  });

  final Category category;
  final int totalCents;

  /// Proporción del total (0..1). Solo se usa para dibujar barras.
  final double share;
}

class ReportData {
  const ReportData({
    required this.start,
    required this.endExclusive,
    required this.incomeCents,
    required this.expenseCents,
    required this.expenseByCategory,
    required this.incomeByCategory,
  });

  final DateTime start;
  final DateTime endExclusive;
  final int incomeCents;
  final int expenseCents;
  final List<CategoryTotal> expenseByCategory;
  final List<CategoryTotal> incomeByCategory;

  int get balanceCents => incomeCents - expenseCents;

  bool get isEmpty => incomeCents == 0 && expenseCents == 0;
}

enum ReportPeriod {
  thisMonth('Este mes'),
  lastMonth('Mes anterior'),
  last3Months('Últimos 3 meses'),
  thisYear('Este año');

  const ReportPeriod(this.label);

  final String label;

  ({DateTime start, DateTime endExclusive}) rangeFor(DateTime now) {
    switch (this) {
      case ReportPeriod.thisMonth:
        return AppDates.monthRange(now);
      case ReportPeriod.lastMonth:
        return AppDates.lastMonthRange(now);
      case ReportPeriod.last3Months:
        return (
          start: DateTime(now.year, now.month - 2),
          endExclusive: DateTime(now.year, now.month + 1),
        );
      case ReportPeriod.thisYear:
        return (
          start: DateTime(now.year),
          endExclusive: DateTime(now.year + 1),
        );
    }
  }
}
