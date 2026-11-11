import '../../../core/domain/category.dart';
import '../../../core/domain/movement_type.dart';
import '../../../core/formatting/dates.dart';

class Movement {
  const Movement({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.categoryId,
    required this.occurredOn,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  final int id;
  final MovementType type;
  final int amountCents;
  final int categoryId;
  final DateTime occurredOn;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get signedCents => type.isExpense ? -amountCents : amountCents;
}

class MovementWithCategory {
  const MovementWithCategory({required this.movement, required this.category});

  final Movement movement;
  final Category category;
}

class MovementDraft {
  const MovementDraft({
    required this.type,
    required this.amountCents,
    required this.categoryId,
    required this.occurredOn,
    this.note,
  });

  final MovementType type;
  final int amountCents;
  final int categoryId;
  final DateTime occurredOn;
  final String? note;

  static MovementDraft fromMovement(Movement movement) {
    return MovementDraft(
      type: movement.type,
      amountCents: movement.amountCents,
      categoryId: movement.categoryId,
      occurredOn: movement.occurredOn,
      note: movement.note,
    );
  }
}

class MovementPage {
  const MovementPage({required this.items, required this.hasMore});

  final List<MovementWithCategory> items;
  final bool hasMore;
}

enum MovementPeriodPreset {
  currentMonth('Este mes'),
  currentWeek('Esta semana'),
  lastMonth('Mes anterior'),
  last30Days('Últimos 30 días'),
  custom('Personalizado');

  const MovementPeriodPreset(this.label);

  final String label;

  ({DateTime start, DateTime endExclusive}) rangeFor(DateTime now) {
    switch (this) {
      case MovementPeriodPreset.currentMonth:
        return AppDates.monthRange(now);
      case MovementPeriodPreset.currentWeek:
        return (
          start: AppDates.startOfWeek(now),
          endExclusive: AppDates.endOfWeekExclusive(now),
        );
      case MovementPeriodPreset.lastMonth:
        return AppDates.lastMonthRange(now);
      case MovementPeriodPreset.last30Days:
        return AppDates.lastNDays(now, 30);
      case MovementPeriodPreset.custom:
        final today = AppDates.today();
        return (
          start: DateTime(today.year, today.month, 1),
          endExclusive: DateTime(today.year, today.month, today.day + 1),
        );
    }
  }
}

class MovementFilter {
  const MovementFilter({
    required this.preset,
    required this.start,
    required this.endExclusive,
    this.type,
    this.categoryId,
  });

  final MovementPeriodPreset preset;
  final DateTime start;
  final DateTime endExclusive;
  final MovementType? type;
  final int? categoryId;

  factory MovementFilter.initial([DateTime? now]) {
    final range = MovementPeriodPreset.currentMonth.rangeFor(
      now ?? DateTime.now(),
    );
    return MovementFilter(
      preset: MovementPeriodPreset.currentMonth,
      start: range.start,
      endExclusive: range.endExclusive,
    );
  }

  MovementFilter withRange(
    MovementPeriodPreset preset,
    DateTime start,
    DateTime endExclusive,
  ) {
    return MovementFilter(
      preset: preset,
      start: AppDates.dateOnly(start),
      endExclusive: AppDates.dateOnly(endExclusive),
      type: type,
      categoryId: categoryId,
    );
  }

  MovementFilter withType(MovementType? type) {
    return MovementFilter(
      preset: preset,
      start: start,
      endExclusive: endExclusive,
      type: type,
      categoryId: categoryId,
    );
  }

  MovementFilter withCategory(int? categoryId) {
    return MovementFilter(
      preset: preset,
      start: start,
      endExclusive: endExclusive,
      type: type,
      categoryId: categoryId,
    );
  }

  String get rangeLabel => preset == MovementPeriodPreset.custom
      ? AppDates.dateRange(start, endExclusive)
      : preset.label;
}
