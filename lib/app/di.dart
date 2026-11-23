import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/database/app_database.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/disabled_auth_repository.dart';
import '../features/auth/data/supabase_auth_repository.dart';
import '../features/categories/data/categories_repository.dart';
import '../features/movements/data/movements_repository.dart';
import '../features/reports/data/reports_repository.dart';

/// Composición de dependencias de la app (composition root).
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final movementsRepositoryProvider = Provider<MovementsRepository>((ref) {
  return DriftMovementsRepository(ref.watch(databaseProvider));
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return DriftCategoriesRepository(ref.watch(databaseProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return DriftReportsRepository(ref.watch(databaseProvider));
});

/// `true` solo si `Supabase.initialize` terminó correctamente en `main`.
///
/// Por defecto es `false` (modo local), de modo que las pruebas y las
/// compilaciones sin credenciales siguen funcionando sin red.
final authConfiguredProvider = Provider<bool>((ref) => false);

/// Autenticación independiente de SQLite. Sin configuración, la app queda en
/// modo local y los movimientos siguen disponibles.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(authConfiguredProvider)) {
    return const DisabledAuthRepository();
  }
  return SupabaseAuthRepository(Supabase.instance.client);
});
