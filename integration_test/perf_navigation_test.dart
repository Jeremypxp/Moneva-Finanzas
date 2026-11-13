// Banco de mediciÃ³n de navegaciÃ³n de Moneva.
//
// Se ejecuta DENTRO del dispositivo con:
//   flutter drive --profile -d <device-id> \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/perf_navigation_test.dart
//
// Usa una base SQLite temporal (perf_bench.sqlite) con datos sintÃ©ticos, por lo
// que NO toca la base real ni los datos de la app instalada. Al terminar borra
// sus propios archivos.
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:moneva_finanzas/app/app.dart';
import 'package:moneva_finanzas/app/di.dart';
import 'package:moneva_finanzas/app/theme.dart';
import 'package:moneva_finanzas/core/database/app_database.dart';
import 'package:moneva_finanzas/core/formatting/dates.dart';
import 'package:moneva_finanzas/core/formatting/money.dart';
import 'package:path_provider/path_provider.dart';

const _tabs = ['Movimientos', 'Reportes', 'Ajustes', 'Resumen'];
const _budgetMicros = 16667; // 60 Hz

class _Sample {
  const _Sample({
    required this.tab,
    required this.round,
    required this.wallMs,
    required this.frames,
    required this.maxBuildMs,
    required this.maxRasterMs,
    required this.maxTotalMs,
    required this.jankyFrames,
    required this.p95TotalMs,
  });

  final String tab;
  final int round;
  final int wallMs;
  final int frames;
  final double maxBuildMs;
  final double maxRasterMs;
  final double maxTotalMs;
  final int jankyFrames;
  final double p95TotalMs;

  @override
  String toString() {
    return 'NAV tab=$tab round=$round wall=${wallMs}ms frames=$frames '
        'maxBuild=${maxBuildMs.toStringAsFixed(1)}ms '
        'maxRaster=${maxRasterMs.toStringAsFixed(1)}ms '
        'maxTotal=${maxTotalMs.toStringAsFixed(1)}ms '
        'p95=${p95TotalMs.toStringAsFixed(1)}ms janky=$jankyFrames';
  }
}

int _p95(List<int> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * 0.95).round();
  return sorted[index];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('perf de navegaciÃ³n por pestaÃ±as', (tester) async {
    Intl.defaultLocale = 'es_PE';
    final intlWatch = Stopwatch()..start();
    await initializeDateFormatting('es_PE');
    intlWatch.stop();
    debugPrint('PERF intl_init=${intlWatch.elapsedMicroseconds}us');

    final directory = await getApplicationDocumentsDirectory();
    final dbFile = File('${directory.path}/perf_bench.sqlite');
    for (final suffix in ['', '-wal', '-shm']) {
      final file = File('${dbFile.path}$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }

    final database = AppDatabase(NativeDatabase(dbFile));
    addTearDown(() async {
      await database.close();
      for (final suffix in ['', '-wal', '-shm']) {
        final file = File('${dbFile.path}$suffix');
        if (await file.exists()) {
          await file.delete();
        }
      }
    });

    // 300 movimientos sintÃ©ticos: 50 por pÃ¡gina + varias pÃ¡ginas de historial.
    final categories = await database.select(database.categories).get();
    final expense = categories.firstWhere((c) => c.type == 'expense');
    final income = categories.firstWhere((c) => c.type == 'income');
    final today = DateTime.now();
    await database.batch((batch) {
      for (var i = 0; i < 300; i++) {
        final isExpense = i.isEven;
        batch.insert(
          database.movements,
          MovementsCompanion.insert(
            type: isExpense ? 'expense' : 'income',
            amountCents: 1250 + (i % 40) * 137,
            categoryId: isExpense ? expense.id : income.id,
            occurredOn: DateTime(today.year, today.month, today.day - (i % 60)),
            note: Value('bench $i'),
          ),
        );
      }
    });

    final timings = <FrameTiming>[];
    WidgetsBinding.instance.addTimingsCallback(timings.addAll);

    final themeWatch = Stopwatch()..start();
    final theme = buildAppTheme();
    themeWatch.stop();
    final themeWatch2 = Stopwatch()..start();
    buildAppTheme();
    themeWatch2.stop();
    debugPrint(
      'PERF theme_build=${themeWatch.elapsedMicroseconds}us '
      'theme_build_again=${themeWatch2.elapsedMicroseconds}us '
      'primary=${theme.colorScheme.primary.toARGB32()}',
    );

    final formatWatch = Stopwatch()..start();
    var checksum = 0;
    for (var i = 0; i < 1000; i++) {
      checksum += Money.format(123456 + i).length;
    }
    formatWatch.stop();
    debugPrint(
      'PERF money_format_1000=${formatWatch.elapsedMicroseconds}us '
      'checksum=$checksum',
    );

    final dateWatch = Stopwatch()..start();
    var dateChecksum = 0;
    final dateStart = DateTime.now().subtract(const Duration(days: 30));
    for (var i = 0; i < 1000; i++) {
      dateChecksum += AppDates.dateRange(dateStart, DateTime.now()).length;
      dateChecksum += AppDates.historyDayLabel(dateStart).length;
    }
    dateWatch.stop();
    debugPrint(
      'PERF date_format_2000=${dateWatch.elapsedMicroseconds}us '
      'checksum=$dateChecksum',
    );

    final startupWatch = Stopwatch()..start();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MonevaApp(),
      ),
    );
    await tester.pumpAndSettle();
    startupWatch.stop();
    debugPrint('PERF first_frame_ready=${startupWatch.elapsedMilliseconds}ms');

    final samples = <_Sample>[];

    Future<void> navigate(String tab, int round) async {
      // Deja llegar los FrameTiming pendientes antes de abrir la ventana.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      timings.clear();

      final watch = Stopwatch()..start();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      watch.stop();

      await tester.pump(const Duration(milliseconds: 120));
      await Future<void>.delayed(const Duration(milliseconds: 350));

      final totals = <int>[];
      var maxBuild = 0;
      var maxRaster = 0;
      var maxTotal = 0;
      var janky = 0;
      for (final timing in List<FrameTiming>.from(timings)) {
        final build = timing.buildDuration.inMicroseconds;
        final raster = timing.rasterDuration.inMicroseconds;
        final total = build + raster;
        totals.add(total);
        if (build > maxBuild) maxBuild = build;
        if (raster > maxRaster) maxRaster = raster;
        if (total > maxTotal) maxTotal = total;
        if (total > _budgetMicros) janky++;
      }

      samples.add(
        _Sample(
          tab: tab,
          round: round,
          wallMs: watch.elapsedMilliseconds,
          frames: totals.length,
          maxBuildMs: maxBuild / 1000,
          maxRasterMs: maxRaster / 1000,
          maxTotalMs: maxTotal / 1000,
          jankyFrames: janky,
          p95TotalMs: _p95(totals) / 1000,
        ),
      );
    }

    // Primera visita a cada pestaÃ±a.
    for (final tab in _tabs) {
      await navigate(tab, 1);
    }
    // Segunda vuelta: pestaÃ±as ya visitadas (estado conservado).
    for (final tab in _tabs) {
      await navigate(tab, 2);
    }
    // Tercera vuelta de control.
    for (final tab in _tabs) {
      await navigate(tab, 3);
    }

    for (final sample in samples) {
      debugPrint(sample.toString());
    }

    final firstWall = samples
        .where((s) => s.round == 1)
        .map((s) => s.wallMs)
        .reduce((a, b) => a + b);
    final laterWall = samples
        .where((s) => s.round > 1)
        .map((s) => s.wallMs)
        .reduce((a, b) => a + b);
    debugPrint(
      'PERF total_round1=${firstWall}ms '
      'total_rounds23=${laterWall}ms',
    );

    expect(samples, hasLength(12));
  });
}
