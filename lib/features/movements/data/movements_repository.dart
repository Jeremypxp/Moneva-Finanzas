import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/category.dart';
import '../../../core/domain/movement_type.dart';
import '../../../core/domain/period_totals.dart';
import '../../../core/formatting/dates.dart';
import '../../../core/formatting/money.dart';
import '../domain/movement.dart';

abstract interface class MovementsRepository {
  Stream<PeriodTotals> watchTotals({
    required DateTime start,
    required DateTime endExclusive,
  });

  Stream<List<MovementWithCategory>> watchRecent({int limit = 5});

  Future<MovementPage> fetchPage({
    required MovementFilter filter,
    required int limit,
    required int offset,
  });

  Future<List<MovementWithCategory>> fetchForExport(MovementFilter filter);

  Future<Movement?> findById(int id);

  Future<int> create(MovementDraft draft);

  Future<void> update(int id, MovementDraft draft);

  Future<void> delete(int id);
}

class DriftMovementsRepository implements MovementsRepository {
  DriftMovementsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<PeriodTotals> watchTotals({
    required DateTime start,
    required DateTime endExclusive,
  }) {
    final income = _db.movements.amountCents.sum(
      filter: _db.movements.type.equals(MovementType.income.dbValue),
    );
    final expense = _db.movements.amountCents.sum(
      filter: _db.movements.type.equals(MovementType.expense.dbValue),
    );
    final query = _db.selectOnly(_db.movements)
      ..addColumns([income, expense])
      ..where(
        _db.movements.occurredOn.isBiggerOrEqualValue(start) &
            _db.movements.occurredOn.isSmallerThanValue(endExclusive),
      );

    return query.watchSingle().map((row) {
      return PeriodTotals(
        incomeCents: row.read(income) ?? 0,
        expenseCents: row.read(expense) ?? 0,
      );
    });
  }

  @override
  Stream<List<MovementWithCategory>> watchRecent({int limit = 5}) {
    final query = _joinedQuery()
      ..orderBy([
        OrderingTerm.desc(_db.movements.occurredOn),
        OrderingTerm.desc(_db.movements.id),
      ])
      ..limit(limit);

    return query.watch().map(_mapRows);
  }

  @override
  Future<MovementPage> fetchPage({
    required MovementFilter filter,
    required int limit,
    required int offset,
  }) async {
    _validateRange(filter);
    final query = _joinedQuery()
      ..where(_filterExpression(filter))
      ..orderBy([
        OrderingTerm.desc(_db.movements.occurredOn),
        OrderingTerm.desc(_db.movements.id),
      ])
      ..limit(limit + 1, offset: offset);

    final rows = await query.get();
    final hasMore = rows.length > limit;
    final visibleRows = hasMore ? rows.sublist(0, limit) : rows;
    return MovementPage(items: _mapRows(visibleRows), hasMore: hasMore);
  }

  @override
  Future<List<MovementWithCategory>> fetchForExport(
    MovementFilter filter,
  ) async {
    _validateRange(filter);
    final query = _joinedQuery()
      ..where(_filterExpression(filter))
      ..orderBy([
        OrderingTerm.desc(_db.movements.occurredOn),
        OrderingTerm.desc(_db.movements.id),
      ]);

    final rows = await query.get();
    return _mapRows(rows);
  }

  @override
  Future<Movement?> findById(int id) async {
    final row = await (_db.select(
      _db.movements,
    )..where((movement) => movement.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapMovement(row);
  }

  @override
  Future<int> create(MovementDraft draft) async {
    await _validate(draft);
    return _db
        .into(_db.movements)
        .insert(
          MovementsCompanion.insert(
            type: draft.type.dbValue,
            amountCents: draft.amountCents,
            categoryId: draft.categoryId,
            occurredOn: AppDates.dateOnly(draft.occurredOn),
            note: Value(_cleanNote(draft.note)),
          ),
        );
  }

  @override
  Future<void> update(int id, MovementDraft draft) async {
    await _validate(draft);
    final updated =
        await (_db.update(
          _db.movements,
        )..where((movement) => movement.id.equals(id))).write(
          MovementsCompanion(
            type: Value(draft.type.dbValue),
            amountCents: Value(draft.amountCents),
            categoryId: Value(draft.categoryId),
            occurredOn: Value(AppDates.dateOnly(draft.occurredOn)),
            note: Value(_cleanNote(draft.note)),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (updated == 0) {
      throw StateError('El movimiento ya no existe.');
    }
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(
      _db.movements,
    )..where((movement) => movement.id.equals(id))).go();
  }

  JoinedSelectStatement _joinedQuery() {
    return _db.select(_db.movements).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.movements.categoryId),
      ),
    ]);
  }

  Expression<bool> _filterExpression(MovementFilter filter) {
    Expression<bool> predicate =
        _db.movements.occurredOn.isBiggerOrEqualValue(filter.start) &
        _db.movements.occurredOn.isSmallerThanValue(filter.endExclusive);
    if (filter.type != null) {
      predicate = predicate & _db.movements.type.equals(filter.type!.dbValue);
    }
    if (filter.categoryId != null) {
      predicate =
          predicate & _db.movements.categoryId.equals(filter.categoryId!);
    }
    return predicate;
  }

  List<MovementWithCategory> _mapRows(List<TypedResult> rows) {
    return rows
        .map((row) {
          return MovementWithCategory(
            movement: _mapMovement(row.readTable(_db.movements)),
            category: _mapCategory(row.readTable(_db.categories)),
          );
        })
        .toList(growable: false);
  }

  Movement _mapMovement(MovementRow row) {
    return Movement(
      id: row.id,
      type: MovementType.fromDb(row.type),
      amountCents: row.amountCents,
      categoryId: row.categoryId,
      occurredOn: AppDates.dateOnly(row.occurredOn),
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Category _mapCategory(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      type: MovementType.fromDb(row.type),
      icon: row.icon,
      colorValue: row.colorValue,
      sortOrder: row.sortOrder,
      isDefault: row.isDefault,
    );
  }

  void _validateRange(MovementFilter filter) {
    if (!filter.start.isBefore(filter.endExclusive)) {
      throw ArgumentError('El rango de fechas no es válido.');
    }
  }

  Future<void> _validate(MovementDraft draft) async {
    if (draft.amountCents <= 0) {
      throw ArgumentError('El importe debe ser mayor que cero.');
    }
    if (draft.amountCents > Money.maxCents) {
      throw ArgumentError('El importe supera el máximo permitido.');
    }
    if (draft.categoryId <= 0) {
      throw ArgumentError('Selecciona una categoría.');
    }
    final category =
        await (_db.select(_db.categories)
              ..where((category) => category.id.equals(draft.categoryId)))
            .getSingleOrNull();
    if (category == null) {
      throw ArgumentError('Selecciona una categoría válida.');
    }
    if (category.type != draft.type.dbValue) {
      throw ArgumentError('La categoría no corresponde al tipo de movimiento.');
    }
  }

  String? _cleanNote(String? note) {
    final trimmed = note?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
