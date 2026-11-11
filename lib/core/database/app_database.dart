import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get type => text().withLength(min: 6, max: 7)();
  TextColumn get icon => text().withDefault(const Constant('category'))();
  IntColumn get colorValue => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => const [
    "CHECK (type IN ('expense', 'income'))",
  ];
}

@DataClassName('MovementRow')
@TableIndex(name: 'idx_movements_occurred_on', columns: {#occurredOn})
@TableIndex(name: 'idx_movements_type_date', columns: {#type, #occurredOn})
class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text().withLength(min: 6, max: 7)();
  IntColumn get amountCents => integer()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get occurredOn => dateTime()();
  TextColumn get note => text().withLength(max: 280).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => const [
    "CHECK (type IN ('expense', 'income'))",
    'CHECK (amount_cents > 0)',
  ];
}

@DriftDatabase(tables: [Categories, Movements])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'app_finanzas'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seedCategories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedCategories() async {
    final defaults = <CategoriesCompanion>[
      CategoriesCompanion.insert(
        name: 'Alimentación',
        type: 'expense',
        icon: Value('restaurant'),
        colorValue: 0xFFB95E43,
        sortOrder: Value(1),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Transporte',
        type: 'expense',
        icon: Value('transport'),
        colorValue: 0xFF3F6F9E,
        sortOrder: Value(2),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Snacks y mascota',
        type: 'expense',
        icon: Value('pets'),
        colorValue: 0xFF8A5A9E,
        sortOrder: Value(3),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Hogar',
        type: 'expense',
        icon: Value('home'),
        colorValue: 0xFF6E7D3A,
        sortOrder: Value(4),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Salud',
        type: 'expense',
        icon: Value('health'),
        colorValue: 0xFFB4435B,
        sortOrder: Value(5),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Servicios',
        type: 'expense',
        icon: Value('services'),
        colorValue: 0xFFC18A2D,
        sortOrder: Value(6),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Ocio',
        type: 'expense',
        icon: Value('leisure'),
        colorValue: 0xFF4A7C79,
        sortOrder: Value(7),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Educación',
        type: 'expense',
        icon: Value('education'),
        colorValue: 0xFF5D5FA8,
        sortOrder: Value(8),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Otros gastos',
        type: 'expense',
        icon: Value('other'),
        colorValue: 0xFF747C76,
        sortOrder: Value(9),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Sueldo',
        type: 'income',
        icon: Value('salary'),
        colorValue: 0xFF16805F,
        sortOrder: Value(1),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Trabajo independiente',
        type: 'income',
        icon: Value('freelance'),
        colorValue: 0xFF2D7F9B,
        sortOrder: Value(2),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Ventas',
        type: 'income',
        icon: Value('sales'),
        colorValue: 0xFF9C7A22,
        sortOrder: Value(3),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Regalos',
        type: 'income',
        icon: Value('gift'),
        colorValue: 0xFFB0567C,
        sortOrder: Value(4),
        isDefault: Value(true),
      ),
      CategoriesCompanion.insert(
        name: 'Otros ingresos',
        type: 'income',
        icon: Value('other_income'),
        colorValue: 0xFF4A7C79,
        sortOrder: Value(5),
        isDefault: Value(true),
      ),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaults);
    });
  }
}
