import 'dart:io';
import 'dart:isolate';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/formatting/dates.dart';
import '../data/movements_repository.dart';
import '../domain/movement.dart';

class NoMovementsToExportException implements Exception {
  const NoMovementsToExportException();
}

class CsvExportFile {
  const CsvExportFile({required this.filePath, required this.rowCount});

  final String filePath;
  final int rowCount;
}

class CsvExportResult {
  const CsvExportResult({
    required this.filePath,
    required this.shareResult,
    required this.rowCount,
  });

  final String filePath;
  final ShareResult shareResult;
  final int rowCount;
}

class MovementCsvExporter {
  MovementCsvExporter(this._repository);

  final MovementsRepository _repository;

  /// Genera el archivo CSV local sin abrir el menú de compartir.
  Future<CsvExportFile> generateFile(MovementFilter filter) async {
    final movements = await _repository.fetchForExport(filter);
    if (movements.isEmpty) {
      throw const NoMovementsToExportException();
    }

    final rows = buildRows(movements);
    // La serialización se hace fuera del hilo de UI.
    final csvText = await Isolate.run(() => _serialize(rows));

    final directory = await getTemporaryDirectory();
    final now = DateTime.now();
    final stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}_'
        '${_two(now.hour)}${_two(now.minute)}';
    final file = File('${directory.path}/movimientos_$stamp.csv');
    await file.writeAsString(csvText, flush: true);

    return CsvExportFile(filePath: file.path, rowCount: movements.length);
  }

  Future<CsvExportResult> export(MovementFilter filter) async {
    final generated = await generateFile(filter);
    final shareResult = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(generated.filePath, mimeType: 'text/csv')],
        subject: 'Movimientos de Finanzas',
        text:
            'Historial exportado desde Finanzas (${generated.rowCount} movimientos).',
      ),
    );

    return CsvExportResult(
      filePath: generated.filePath,
      shareResult: shareResult,
      rowCount: generated.rowCount,
    );
  }

  static List<List<String>> buildRows(List<MovementWithCategory> movements) {
    final rows = <List<String>>[
      ['Fecha', 'Tipo', 'Categoría', 'Importe (PEN)', 'Nota'],
    ];
    for (final item in movements) {
      final movement = item.movement;
      rows.add([
        AppDates.shortDate(movement.occurredOn),
        movement.type.label,
        item.category.name,
        _plainAmount(movement.amountCents),
        movement.note ?? '',
      ]);
    }
    return rows;
  }

  static String _serialize(List<List<String>> rows) {
    return Csv(addBom: true).encode(rows);
  }

  static String _plainAmount(int cents) {
    final whole = cents ~/ 100;
    final decimals = (cents % 100).toString().padLeft(2, '0');
    return '$whole.$decimals';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
