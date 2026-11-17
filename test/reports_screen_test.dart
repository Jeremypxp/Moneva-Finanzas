import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:moneva_finanzas/app/di.dart';
import 'package:moneva_finanzas/app/theme.dart';
import 'package:moneva_finanzas/features/reports/data/reports_repository.dart';
import 'package:moneva_finanzas/features/reports/domain/report_data.dart';
import 'package:moneva_finanzas/features/reports/presentation/reports_screen.dart';

class _FakeReportsRepository implements ReportsRepository {
  @override
  Future<ReportData> fetchReport({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    return ReportData(
      start: start,
      endExclusive: endExclusive,
      incomeCents: 31850,
      expenseCents: 3350,
      expenseByCategory: const [],
      incomeByCategory: const [],
    );
  }
}

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'es_PE';
    await initializeDateFormatting('es_PE');
  });

  testWidgets('muestra el balance encima de ingresos y gastos', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportsRepositoryProvider.overrideWithValue(_FakeReportsRepository()),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const ReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('S/ 285,00'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Balance')).dy,
      lessThan(tester.getTopLeft(find.text('Ingresos')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Balance')).dy,
      lessThan(tester.getTopLeft(find.text('Gastos')).dy),
    );
  });
}
