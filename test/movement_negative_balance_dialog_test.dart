import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:moneva_finanzas/app/app.dart';
import 'package:moneva_finanzas/app/di.dart';
import 'package:moneva_finanzas/core/domain/category.dart';
import 'package:moneva_finanzas/core/domain/movement_type.dart';
import 'package:moneva_finanzas/core/domain/period_totals.dart';
import 'package:moneva_finanzas/features/categories/application/categories_providers.dart';
import 'package:moneva_finanzas/features/movements/data/movements_repository.dart';
import 'package:moneva_finanzas/features/movements/domain/movement.dart';

/// Repositorio en memoria: permite probar el flujo del diálogo sin depender de
/// SQLite ni del reloj real de la base de datos.
class _FakeMovementsRepository implements MovementsRepository {
  final _totals = StreamController<PeriodTotals>.broadcast();
  PeriodTotals current = PeriodTotals.empty;
  int createCalls = 0;

  static const _category = Category(
    id: 1,
    name: 'Alimentación',
    type: MovementType.expense,
    icon: 'restaurant',
    colorValue: 0xFFB95E43,
    sortOrder: 1,
    isDefault: true,
  );

  @override
  Stream<PeriodTotals> watchTotals({
    required DateTime start,
    required DateTime endExclusive,
  }) async* {
    yield current;
    yield* _totals.stream;
  }

  @override
  Stream<List<MovementWithCategory>> watchRecent({int limit = 5}) =>
      Stream.value(const <MovementWithCategory>[]);

  @override
  Future<MovementPage> fetchPage({
    required MovementFilter filter,
    required int limit,
    required int offset,
  }) async => const MovementPage(items: [], hasMore: false);

  @override
  Future<List<MovementWithCategory>> fetchForExport(
    MovementFilter filter,
  ) async => const [];

  @override
  Future<Movement?> findById(int id) async => null;

  @override
  Future<int> create(MovementDraft draft) async {
    createCalls++;
    current = PeriodTotals(
      incomeCents: current.incomeCents,
      expenseCents: current.expenseCents + draft.amountCents,
    );
    _totals.add(current);
    return 1;
  }

  @override
  Future<void> update(int id, MovementDraft draft) async {}

  @override
  Future<void> delete(int id) async {}

  void dispose() => _totals.close();

  static Category get category => _category;
}

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'es_PE';
    await initializeDateFormatting('es_PE');
  });

  testWidgets('advierte y solo guarda si se elige Registrar gasto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeMovementsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          movementsRepositoryProvider.overrideWithValue(repository),
          categoriesProvider.overrideWith(
            (ref) => Stream.value([_FakeMovementsRepository.category]),
          ),
        ],
        child: const MonevaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '25.50');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Alimentación'));
    await tester.tap(find.text('Alimentación'));
    await tester.pumpAndSettle();

    // Primer intento: cancelar no guarda.
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();
    expect(find.text('Balance negativo'), findsOneWidget);
    expect(
      find.textContaining('el balance de ese periodo quedará en -S/ 25,50'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo movimiento'), findsOneWidget);
    expect(repository.createCalls, 0);

    // Segundo intento: cerrar con la X tampoco guarda.
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo movimiento'), findsOneWidget);
    expect(repository.createCalls, 0);

    // Tercer intento: la acción explícita sí guarda y actualiza el resumen.
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar gasto'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(find.text('Tu resumen'), findsOneWidget);
    expect(find.text('-S/ 25,50'), findsOneWidget);
    expect(
      find.text('Tus gastos superan tus ingresos registrados'),
      findsOneWidget,
    );
  });
}
