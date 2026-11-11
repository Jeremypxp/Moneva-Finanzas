import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_gateway.dart';
import '../core/database/app_database.dart';
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

/// Preparado para sustituirse por un adaptador de Supabase Auth en la fase 2.
final authGatewayProvider = Provider<AuthGateway>((ref) {
  return const LocalOnlyAuthGateway();
});
