import 'package:moneva_finanzas/app/app.dart';
import 'package:moneva_finanzas/core/domain/period_totals.dart';
import 'package:moneva_finanzas/features/movements/application/movements_providers.dart';
import 'package:moneva_finanzas/features/movements/domain/movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_PE');
  });

  testWidgets('abre el resumen con el estado inicial vacío', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyTotalsProvider.overrideWith(
            (ref) => Stream.value(PeriodTotals.empty),
          ),
          recentMovementsProvider.overrideWith(
            (ref) => Stream.value(const <MovementWithCategory>[]),
          ),
        ],
        child: const MonevaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu resumen'), findsOneWidget);
    expect(find.text('Tu historial está vacío'), findsOneWidget);
    expect(find.text('Nuevo'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Acerca de Moneva'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Acerca de Moneva'), findsOneWidget);
  });
}
