import 'dart:io';

import 'package:app_finanzas/app/app.dart';
import 'package:app_finanzas/app/di.dart';
import 'package:app_finanzas/core/database/app_database.dart';
import 'package:app_finanzas/features/movements/application/movement_csv_exporter.dart';
import 'package:app_finanzas/features/movements/domain/movement.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Intl.defaultLocale = 'es_PE';
    await initializeDateFormatting('es_PE');
  });

  testWidgets('recorre alta, historial, filtros, reporte y ajustes', (
    tester,
  ) async {
    // Base efímera: la prueba no toca la base real del teléfono.
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const FinanzasApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu resumen'), findsOneWidget);
    expect(find.text('Tu historial está vacío'), findsOneWidget);

    // Alta de un gasto.
    await tester.tap(find.text('Nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo movimiento'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '25.50');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Alimentación'));
    await tester.tap(find.text('Alimentación'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar movimiento'));
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    // El resumen refleja el gasto.
    expect(find.text('- S/ 25,50'), findsOneWidget);

    // Historial y hoja de filtros.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Movimientos'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alimentación'), findsWidgets);
    expect(find.text('- S/ 25,50'), findsOneWidget);

    await tester.tap(find.text('Este mes · Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Filtrar historial'), findsOneWidget);
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();

    // Reporte agregado.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Reportes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gastos por categoría'), findsOneWidget);
    expect(find.text('S/ 25,50'), findsWidgets);

    // Ajustes.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Sol peruano (PEN)'), findsOneWidget);

    // Exportación CSV real a archivo temporal (sin abrir el menú del sistema).
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FinanzasApp)),
    );
    final exporter = MovementCsvExporter(
      container.read(movementsRepositoryProvider),
    );
    final generated = await exporter.generateFile(MovementFilter.initial());
    final file = File(generated.filePath);
    addTearDown(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });
    final csvText = await file.readAsString();
    expect(generated.rowCount, 1);
    expect(csvText, contains('Alimentación'));
    expect(csvText, contains('Gasto'));
    expect(csvText, contains('25.50'));
  });
}
