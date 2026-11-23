import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/email_verification_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/movements/presentation/movement_form_screen.dart';
import '../features/movements/presentation/movements_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';
import 'di.dart';

/// Router de la app. Se recrea solo con el `ProviderScope`; los cambios de
/// sesión disparan un refresco para reevaluar el redirect.
final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authSessionProvider, (previous, next) => refresh.value++);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/resumen',
    refreshListenable: refresh,
    redirect: (context, state) {
      if (!ref.read(authConfiguredProvider)) {
        // Sin credenciales, la app sigue funcionando con datos locales.
        return null;
      }
      final user = ref.read(authSessionProvider);
      final location = state.matchedLocation;
      final isAuthLocation = location == '/login' || location == '/registro';
      final isVerificationLocation = location == '/auth-callback';
      if (user == null && !isAuthLocation && !isVerificationLocation) {
        return '/login';
      }
      if (user != null && (isAuthLocation || isVerificationLocation)) {
        return '/resumen';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth-callback',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
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
});
