import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneva_finanzas/app/theme.dart';
import 'package:moneva_finanzas/core/domain/period_totals.dart';
import 'package:moneva_finanzas/features/dashboard/presentation/dashboard_screen.dart';
import 'package:moneva_finanzas/features/movements/application/movements_providers.dart';
import 'package:moneva_finanzas/features/movements/domain/movement.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_PE');
  });

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required PeriodTotals totals,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklyTotalsProvider.overrideWith((ref) => Stream.value(totals)),
          recentMovementsProvider.overrideWith(
            (ref) => Stream.value(const <MovementWithCategory>[]),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el aviso cuando el balance semanal es negativo', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      totals: const PeriodTotals(incomeCents: 10000, expenseCents: 12500),
    );

    expect(
      find.text('Tus gastos superan tus ingresos registrados'),
      findsOneWidget,
    );
    expect(
      find.textContaining('llevas S/ 25,00 más en gastos que en ingresos'),
      findsOneWidget,
    );
    expect(find.textContaining('Revisa tus movimientos'), findsOneWidget);
  });

  testWidgets('no muestra el aviso si el balance es cero o positivo', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      totals: const PeriodTotals(incomeCents: 10000, expenseCents: 10000),
    );

    expect(
      find.text('Tus gastos superan tus ingresos registrados'),
      findsNothing,
    );
  });
}
