import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/categories/presentation/categories_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/movements/presentation/movement_form_screen.dart';
import '../features/movements/presentation/movements_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/resumen',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/resumen',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/movimientos',
              builder: (context, state) => const MovementsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reportes',
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ajustes',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/movimiento/nuevo',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MovementFormScreen(),
    ),
    GoRoute(
      path: '/movimiento/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return MovementFormScreen(movementId: id);
      },
    ),
    GoRoute(
      path: '/categorias',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CategoriesScreen(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/resumen'),
          child: const Text('Volver al resumen'),
        ),
      ),
    );
  },
);
