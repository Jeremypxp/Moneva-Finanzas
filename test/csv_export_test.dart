import 'package:moneva_finanzas/core/domain/category.dart';
import 'package:moneva_finanzas/core/domain/movement_type.dart';
import 'package:moneva_finanzas/features/movements/application/movement_csv_exporter.dart';
import 'package:moneva_finanzas/features/movements/domain/movement.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_PE');
  });

  test('genera filas CSV escapables con importes enteros', () {
    final category = Category(
      id: 1,
      name: 'Snacks y mascota',
      type: MovementType.expense,
      icon: 'pets',
      colorValue: 0xFF8A5A9E,
      sortOrder: 1,
      isDefault: true,
    );
    final item = MovementWithCategory(
      category: category,
      movement: Movement(
        id: 9,
        type: MovementType.expense,
        amountCents: 123456,
        categoryId: 1,
        occurredOn: DateTime(2026, 11, 10),
        note: 'Café, pan',
        createdAt: DateTime(2026, 11, 10),
        updatedAt: DateTime(2026, 11, 10),
      ),
    );

    final rows = MovementCsvExporter.buildRows([item]);

    expect(rows.first, ['Fecha', 'Tipo', 'Categoría', 'Importe (PEN)', 'Nota']);
    expect(rows[1], [
      '10/11/2026',
      'Gasto',
      'Snacks y mascota',
      '1234.56',
      'Café, pan',
    ]);
  });
}
