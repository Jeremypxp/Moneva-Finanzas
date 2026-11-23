import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneva_finanzas/app/app.dart';
import 'package:moneva_finanzas/app/di.dart';
import 'package:moneva_finanzas/app/theme.dart';
import 'package:moneva_finanzas/core/domain/period_totals.dart';
import 'package:moneva_finanzas/features/auth/application/auth_deep_link_handler.dart';
import 'package:moneva_finanzas/features/auth/data/auth_repository.dart';
import 'package:moneva_finanzas/features/auth/domain/auth_failure.dart';
import 'package:moneva_finanzas/features/auth/domain/auth_user.dart';
import 'package:moneva_finanzas/features/auth/presentation/login_screen.dart';
import 'package:moneva_finanzas/features/auth/presentation/register_screen.dart';
import 'package:moneva_finanzas/features/movements/application/movements_providers.dart';
import 'package:moneva_finanzas/features/movements/domain/movement.dart';

import 'helpers/fake_auth_repository.dart';

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _authApp(Widget child, FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [
      authConfiguredProvider.overrideWithValue(true),
      authRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(theme: buildAppTheme(), home: child),
  );
}

Widget _fullApp(FakeAuthRepository repository) {
  return ProviderScope(
    overrides: [
      authConfiguredProvider.overrideWithValue(true),
      authRepositoryProvider.overrideWithValue(repository),
      allTimeTotalsProvider.overrideWith(
        (ref) => Stream.value(PeriodTotals.empty),
      ),
      recentMovementsProvider.overrideWith(
        (ref) => Stream.value(const <MovementWithCategory>[]),
      ),
    ],
    child: const MonevaApp(),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_PE');
  });

  setUp(() {
    // Evita que un enlace pendiente de una prueba previa afecte la navegación.
    AuthDeepLinkHandler.instance.clearPendingLink();
  });

  group('inicio de sesión', () {
    testWidgets('muestra errores y no llama a Supabase con campos vacíos', (
      tester,
    ) async {
      _setPhoneSize(tester);
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(_authApp(const LoginScreen(), repository));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu correo.'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
      expect(repository.signInCalls, 0);
    });

    testWidgets('el botón de Google está desactivado y marcado Próximamente', (
      tester,
    ) async {
      _setPhoneSize(tester);
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(_authApp(const LoginScreen(), repository));
      await tester.pumpAndSettle();

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Próximamente'), findsOneWidget);

      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 0);
      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    });

    testWidgets('envía el correo recortado y la contraseña sin cambios', (
      tester,
    ) async {
      _setPhoneSize(tester);
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(_authApp(const LoginScreen(), repository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        '  ana@moneva.app  ',
      );
      await tester.enterText(find.byType(TextFormField).last, ' Clave 123 ');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 1);
      expect(repository.lastEmail, 'ana@moneva.app');
      expect(repository.lastPassword, ' Clave 123 ');
    });

    testWidgets('muestra el mensaje de credenciales incorrectas', (
      tester,
    ) async {
      _setPhoneSize(tester);
      final repository = FakeAuthRepository()
        ..signInFailure = const AuthFailure(
          AuthFailureKind.invalidCredentials,
          'Correo o contraseña incorrectos.',
        );
      addTearDown(repository.dispose);

      await tester.pumpWidget(_authApp(const LoginScreen(), repository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'ana@moneva.app',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Clave123');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    });

    testWidgets('muestra el aviso de correo pendiente de confirmación', (
      tester,
    ) async {
      _setPhoneSize(tester);
      final repository = FakeAuthRepository()
        ..signInFailure = const AuthFailure(
          AuthFailureKind.emailNotConfirmed,
          'Tu correo aún no está confirmado.',
        );
      addTearDown(repository.dispose);

      await tester.pumpWidget(_authApp(const LoginScreen(), repository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'ana@moneva.app',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Clave123');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Tu correo aún no está confirmado.'), findsOneWidget);
    });
  });

  group('registro', () {
    Future<void> pumpRegister(
      WidgetTester tester,
      FakeAuthRepository repository,
    ) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(_authApp(const RegisterScreen(), repository));
      await tester.pumpAndSettle();
    }

    testWidgets('valida campos vacíos sin llamar a Supabase', (tester) async {
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpRegister(tester, repository);

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Crear cuenta'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu nombre.'), findsNWidgets(2));
      expect(find.text('Ingresa tu correo.'), findsOneWidget);
      expect(find.text('Ingresa una contraseña.'), findsOneWidget);
      expect(find.text('Confirma tu contraseña.'), findsOneWidget);
      expect(repository.signUpCalls, 0);
    });

    testWidgets('muestra la barra de seguridad con etiqueta textual', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpRegister(tester, repository);

      final passwordField = find.byType(TextFormField).at(3);
      await tester.enterText(passwordField, 'Ab1!');
      await tester.pumpAndSettle();
      expect(find.text('Seguridad: Débil'), findsOneWidget);

      await tester.enterText(passwordField, 'Abcdef12');
      await tester.pumpAndSettle();
      expect(find.text('Seguridad: Buena'), findsOneWidget);

      await tester.enterText(passwordField, 'Nube\$Verde2026');
      await tester.pumpAndSettle();
      expect(find.text('Seguridad: Fuerte'), findsOneWidget);
    });

    testWidgets('la confirmación se revalida si cambia la contraseña', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpRegister(tester, repository);

      final passwordField = find.byType(TextFormField).at(3);
      final confirmField = find.byType(TextFormField).at(4);
      await tester.enterText(passwordField, 'Clave123');
      await tester.enterText(confirmField, 'Clave123');
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden.'), findsNothing);

      await tester.enterText(passwordField, 'Clave124');
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    });

    testWidgets('normaliza nombres y envía la contraseña sin recortar', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await pumpRegister(tester, repository);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        '  José   María ',
      );
      await tester.enterText(find.byType(TextFormField).at(1), ' Pérez-Ñúñez ');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        '  jose@moneva.app ',
      );
      await tester.enterText(find.byType(TextFormField).at(3), ' Clave 123 ');
      await tester.enterText(find.byType(TextFormField).at(4), ' Clave 123 ');

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Crear cuenta'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(repository.signUpCalls, 1);
      expect(repository.lastFirstName, 'José María');
      expect(repository.lastLastName, 'Pérez-Ñúñez');
      expect(repository.lastEmail, 'jose@moneva.app');
      expect(repository.lastPassword, ' Clave 123 ');
      expect(find.text('Cuenta creada. ¡Bienvenido a Moneva!'), findsOneWidget);
    });

    testWidgets('pide confirmar el correo cuando no hay sesión', (
      tester,
    ) async {
      final repository = FakeAuthRepository(
        signUpOutcome: const SignUpOutcome(
          user: null,
          needsEmailConfirmation: true,
        ),
      );
      addTearDown(repository.dispose);
      await pumpRegister(tester, repository);

      await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
      await tester.enterText(find.byType(TextFormField).at(1), 'Pérez');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'ana@moneva.app',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'Clave123');
      await tester.enterText(find.byType(TextFormField).at(4), 'Clave123');

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Crear cuenta'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      // El botón mantiene el indicador de carga mientras el aviso está
      // abierto, así que no se usa pumpAndSettle aquí.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Confirma tu correo'), findsOneWidget);
      expect(
        find.textContaining('Enviamos un mensaje a ana@moneva.app'),
        findsOneWidget,
      );
    });
  });

  group('navegación por sesión', () {
    testWidgets('sin sesión muestra el inicio de sesión', (tester) async {
      _setPhoneSize(tester);
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(_fullApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido de nuevo'), findsOneWidget);
      expect(find.text('Tu resumen'), findsNothing);
    });

    testWidgets('con sesión restaurada muestra el resumen', (tester) async {
      _setPhoneSize(tester);
      final repository = FakeAuthRepository(
        user: const AuthUser(
          id: 'user-1',
          email: 'ana@moneva.app',
          firstName: 'Ana',
          lastName: 'Pérez',
        ),
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(_fullApp(repository));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hola, Ana'), findsOneWidget);
      expect(find.text('Bienvenido de nuevo'), findsNothing);
    });

    testWidgets('al iniciar sesión navega al resumen', (tester) async {
      _setPhoneSize(tester);
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(_fullApp(repository));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'ana@moneva.app',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Clave123');
      await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hola, Ana'), findsOneWidget);
      expect(repository.signInCalls, 1);
    });
  });
}
