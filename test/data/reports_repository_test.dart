import 'package:moneva_finanzas/core/database/app_database.dart';
import 'package:moneva_finanzas/core/domain/movement_type.dart';
import 'package:moneva_finanzas/features/categories/data/categories_repository.dart';
import 'package:moneva_finanzas/features/movements/data/movements_repository.dart';
import 'package:moneva_finanzas/features/movements/domain/movement.dart';
import 'package:moneva_finanzas/features/reports/data/reports_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftMovementsRepository movements;
  late DriftCategoriesRepository categories;
  late DriftReportsRepository reports;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    movements = DriftMovementsRepository(database);
    categories = DriftCategoriesRepository(database);
    reports = DriftReportsRepository(database);
    await categories.fetchAll();
  });

  tearDown(() async {
    await database.close();
  });

  test('agrega totales y desglose por categoría para el reporte', () async {
    final all = await categories.fetchAll();
    final food = all.firstWhere(
      (category) =>
          category.name == 'Alimentación' &&
          category.type == MovementType.expense,
    );
    final transport = all.firstWhere(
      (category) =>
          category.name == 'Transporte' &&
          category.type == MovementType.expense,
    );
    final salary = all.firstWhere(
      (category) =>
          category.name == 'Sueldo' && category.type == MovementType.income,
    );
    final day = DateTime(2026, 11, 10);

    await movements.create(
      MovementDraft(
        type: MovementType.expense,
        amountCents: 2000,
        categoryId: food.id,
        occurredOn: day,
      ),
    );
    await movements.create(
      MovementDraft(
        type: MovementType.expense,
        amountCents: 1500,
        categoryId: food.id,
        occurredOn: day,
      ),
    );
    await movements.create(
      MovementDraft(
        type: MovementType.expense,
        amountCents: 500,
        categoryId: transport.id,
        occurredOn: day,
      ),
    );
    await movements.create(
      MovementDraft(
        type: MovementType.income,
        amountCents: 100000,
        categoryId: salary.id,
        occurredOn: day,
      ),
    );
    // Fuera del periodo: no debe sumarse.
    await movements.create(
      MovementDraft(
        type: MovementType.expense,
        amountCents: 9999,
        categoryId: food.id,
        occurredOn: DateTime(2026, 10, 1),
      ),
    );

    final report = await reports.fetchReport(
      start: DateTime(2026, 11, 1),
      endExclusive: DateTime(2026, 12, 1),
    );

    expect(report.incomeCents, 100000);
    expect(report.expenseCents, 4000);
    expect(report.balanceCents, 96000);
    expect(report.expenseByCategory, hasLength(2));
    expect(report.expenseByCategory.first.category.id, food.id);
    expect(report.expenseByCategory.first.totalCents, 3500);
    expect(report.expenseByCategory.first.share, closeTo(0.875, 0.0001));
    expect(report.incomeByCategory.single.totalCents, 100000);
    expect(report.incomeByCategory.single.share, 1.0);
  });
}
