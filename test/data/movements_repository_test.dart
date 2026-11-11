import 'package:moneva_finanzas/core/database/app_database.dart';
import 'package:moneva_finanzas/core/domain/movement_type.dart';
import 'package:moneva_finanzas/features/categories/data/categories_repository.dart';
import 'package:moneva_finanzas/features/movements/data/movements_repository.dart';
import 'package:moneva_finanzas/features/movements/domain/movement.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftMovementsRepository movements;
  late DriftCategoriesRepository categories;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    movements = DriftMovementsRepository(database);
    categories = DriftCategoriesRepository(database);
    // Fuerza la apertura y la siembra de categorías iniciales.
    await categories.fetchAll();
  });

  tearDown(() async {
    await database.close();
  });

  test('siembra categorías útiles de gasto e ingreso', () async {
    final all = await categories.fetchAll();
    expect(all.length, 14);
    expect(
      all.any(
        (category) =>
            category.name == 'Transporte' &&
            category.type == MovementType.expense,
      ),
      isTrue,
    );
    expect(
      all.any(
        (category) =>
            category.name == 'Snacks y mascota' &&
            category.type == MovementType.expense,
      ),
      isTrue,
    );
    expect(
      all.any(
        (category) =>
            category.name == 'Sueldo' && category.type == MovementType.income,
      ),
      isTrue,
    );
  });

  test('crea, consulta, actualiza y elimina un movimiento', () async {
    final all = await categories.fetchAll();
    final expense = all.firstWhere(
      (category) => category.type == MovementType.expense,
    );
    final day = DateTime(2026, 11, 10);

    final id = await movements.create(
      MovementDraft(
        type: MovementType.expense,
        amountCents: 2550,
        categoryId: expense.id,
        occurredOn: day,
        note: '  Menú del día  ',
      ),
    );

    final filter = MovementFilter(
      preset: MovementPeriodPreset.custom,
      start: DateTime(2026, 11, 10),
      endExclusive: DateTime(2026, 11, 11),
    );
    final page = await movements.fetchPage(
      filter: filter,
      limit: 10,
      offset: 0,
    );

    expect(page.items, hasLength(1));
    expect(page.items.single.movement.amountCents, 2550);
    expect(page.items.single.movement.note, 'Menú del día');
    expect(page.items.single.category.id, expense.id);
    expect(page.hasMore, isFalse);

    final totals = await movements
        .watchTotals(
          start: DateTime(2026, 11, 10),
          endExclusive: DateTime(2026, 11, 11),
        )
        .first;
    expect(totals.expenseCents, 2550);
    expect(totals.incomeCents, 0);
    expect(totals.balanceCents, -2550);

    await movements.update(
      id,
      MovementDraft(
        type: MovementType.expense,
        amountCents: 3000,
        categoryId: expense.id,
        occurredOn: DateTime(2026, 11, 9),
        note: null,
      ),
    );
    final updated = await movements.findById(id);
    expect(updated, isNotNull);
    expect(updated!.amountCents, 3000);
    expect(updated.note, isNull);
    expect(updated.occurredOn, DateTime(2026, 11, 9));

    await movements.delete(id);
    expect(await movements.findById(id), isNull);
  });

  test('no elimina categorías con movimientos asociados', () async {
    final all = await categories.fetchAll();
    final expense = all.firstWhere(
      (category) => category.type == MovementType.expense,
    );
    await movements.create(
      MovementDraft(
        type: MovementType.expense,
        amountCents: 100,
        categoryId: expense.id,
        occurredOn: DateTime(2026, 11, 10),
      ),
    );

    expect(
      () => categories.delete(expense.id),
      throwsA(isA<CategoryInUseException>()),
    );
  });

  test('pagina el historial sin cargar todo de golpe', () async {
    final all = await categories.fetchAll();
    final expense = all.firstWhere(
      (category) => category.type == MovementType.expense,
    );
    for (var index = 0; index < 3; index++) {
      await movements.create(
        MovementDraft(
          type: MovementType.expense,
          amountCents: 100 + index,
          categoryId: expense.id,
          occurredOn: DateTime(2026, 11, 10),
        ),
      );
    }
    final filter = MovementFilter(
      preset: MovementPeriodPreset.custom,
      start: DateTime(2026, 11, 10),
      endExclusive: DateTime(2026, 11, 11),
    );

    final firstPage = await movements.fetchPage(
      filter: filter,
      limit: 2,
      offset: 0,
    );
    expect(firstPage.items, hasLength(2));
    expect(firstPage.hasMore, isTrue);

    final secondPage = await movements.fetchPage(
      filter: filter,
      limit: 2,
      offset: 2,
    );
    expect(secondPage.items, hasLength(1));
    expect(secondPage.hasMore, isFalse);
  });
}
