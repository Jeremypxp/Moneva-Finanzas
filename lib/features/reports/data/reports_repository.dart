import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/category.dart';
import '../../../core/domain/movement_type.dart';
import '../domain/report_data.dart';

abstract interface class ReportsRepository {
  Future<ReportData> fetchReport({
    required DateTime start,
    required DateTime endExclusive,
  });
}

class DriftReportsRepository implements ReportsRepository {
  DriftReportsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ReportData> fetchReport({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final sum = _db.movements.amountCents.sum();
    final query = _db.selectOnly(_db.movements)
      ..addColumns([_db.movements.type, _db.movements.categoryId, sum])
      ..where(
        _db.movements.occurredOn.isBiggerOrEqualValue(start) &
            _db.movements.occurredOn.isSmallerThanValue(endExclusive),
      )
      ..groupBy([_db.movements.type, _db.movements.categoryId])
      ..orderBy([OrderingTerm.desc(sum)]);

    final rows = await query.get();
    final categoryRows = await _db.select(_db.categories).get();
    final categoriesById = {
      for (final row in categoryRows) row.id: _mapCategory(row),
    };

    var incomeCents = 0;
    var expenseCents = 0;
    final expenseTotals = <CategoryTotal>[];
    final incomeTotals = <CategoryTotal>[];

    for (final row in rows) {
      final typeValue = row.read(_db.movements.type);
      final categoryId = row.read(_db.movements.categoryId);
      final total = row.read(sum) ?? 0;
      if (typeValue == null || categoryId == null || total <= 0) {
        continue;
      }
      final category = categoriesById[categoryId];
      if (category == null) {
        continue;
      }
      if (typeValue == MovementType.income.dbValue) {
        incomeCents += total;
        incomeTotals.add(
          CategoryTotal(category: category, totalCents: total, share: 0),
        );
      } else {
        expenseCents += total;
        expenseTotals.add(
          CategoryTotal(category: category, totalCents: total, share: 0),
        );
      }
    }

    return ReportData(
      start: start,
      endExclusive: endExclusive,
      incomeCents: incomeCents,
      expenseCents: expenseCents,
      expenseByCategory: _withShares(expenseTotals, expenseCents),
      incomeByCategory: _withShares(incomeTotals, incomeCents),
    );
  }

  List<CategoryTotal> _withShares(List<CategoryTotal> items, int total) {
    if (total <= 0) {
      return const [];
    }
    return items
        .map(
          (item) => CategoryTotal(
            category: item.category,
            totalCents: item.totalCents,
            share: item.totalCents / total,
          ),
        )
        .toList(growable: false);
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
}
