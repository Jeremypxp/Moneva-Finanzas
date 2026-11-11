import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/domain/category.dart';
import '../../../core/domain/movement_type.dart';

abstract interface class CategoriesRepository {
  Stream<List<Category>> watchAll();

  Future<List<Category>> fetchAll();

  Future<Category?> findById(int id);

  Future<int> create({
    required String name,
    required MovementType type,
    required String icon,
    required int colorValue,
  });

  Future<void> delete(int id);
}

class CategoryValidationException implements Exception {
  const CategoryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CategoryInUseException implements Exception {
  const CategoryInUseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriftCategoriesRepository implements CategoriesRepository {
  DriftCategoriesRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Category>> watchAll() {
    return _orderedQuery().watch().map(
      (rows) => rows.map(_mapRow).toList(growable: false),
    );
  }

  @override
  Future<List<Category>> fetchAll() async {
    final rows = await _orderedQuery().get();
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<Category?> findById(int id) async {
    final row = await (_db.select(
      _db.categories,
    )..where((category) => category.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<int> create({
    required String name,
    required MovementType type,
    required String icon,
    required int colorValue,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const CategoryValidationException('Escribe un nombre.');
    }
    if (cleanName.length > 40) {
      throw const CategoryValidationException(
        'El nombre no puede superar 40 caracteres.',
      );
    }

    final siblings = await (_db.select(
      _db.categories,
    )..where((category) => category.type.equals(type.dbValue))).get();
    final duplicate = siblings.any(
      (category) => category.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (duplicate) {
      throw const CategoryValidationException(
        'Ya existe una categoría con ese nombre.',
      );
    }

    var nextOrder = 1;
    for (final category in siblings) {
      if (category.sortOrder >= nextOrder) {
        nextOrder = category.sortOrder + 1;
      }
    }

    return _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: cleanName,
            type: type.dbValue,
            icon: Value(icon),
            colorValue: colorValue,
            sortOrder: Value(nextOrder),
          ),
        );
  }

  @override
  Future<void> delete(int id) async {
    final usage = _db.movements.id.count();
    final usageQuery = _db.selectOnly(_db.movements)
      ..addColumns([usage])
      ..where(_db.movements.categoryId.equals(id));
    final usageRow = await usageQuery.getSingle();
    if ((usageRow.read(usage) ?? 0) > 0) {
      throw const CategoryInUseException(
        'Esta categoría tiene movimientos asociados. Cambia esos movimientos '
        'de categoría antes de eliminarla.',
      );
    }
    await (_db.delete(
      _db.categories,
    )..where((category) => category.id.equals(id))).go();
  }

  SimpleSelectStatement<$CategoriesTable, CategoryRow> _orderedQuery() {
    return _db.select(_db.categories)..orderBy([
      (category) => OrderingTerm.asc(category.type),
      (category) => OrderingTerm.asc(category.sortOrder),
      (category) => OrderingTerm.asc(category.name),
    ]);
  }

  Category _mapRow(CategoryRow row) {
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
