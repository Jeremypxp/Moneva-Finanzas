import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_validators.dart';
import 'widgets/auth_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    // La contraseña no se recorta ni se altera.
    final password = _passwordController.text;

    final formValid = _formKey.currentState?.validate() ?? false;
    final emailValid = AuthValidators.emailError(email) == null;
    if (!formValid || !emailValid) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      // El router redirige al detectar la sesión.
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failure.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos iniciar sesión. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(authRepositoryProvider);
    final available = repository.isAvailable;

    return AuthScaffold(
      title: 'Bienvenido de nuevo',
      subtitle:
          'Inicia sesión para identificarte en Moneva. Tus movimientos siguen '
          'guardados en este dispositivo.',
      centerHeader: true,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '¿No tienes cuenta?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : () => context.go('/registro'),
            child: const Text('Crear una cuenta'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!available)
              const AuthErrorBanner(
                message:
                    'El inicio de sesión no está configurado en esta '
                    'compilación. La app sigue funcionando con tus datos '
                    'locales.',
              )
            else if (_error != null)
              AuthErrorBanner(message: _error!),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: AuthValidators.emailError,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              decoration: const InputDecoration(
                labelText: 'Correo',
                hintText: 'tu@correo.com',
              ),
            ),
            const SizedBox(height: 14),
            AuthPasswordField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Contraseña',
              validator: AuthValidators.loginPasswordError,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
            ),
            const SizedBox(height: 20),
            AuthSubmitButton(
              label: 'Iniciar sesión',
              loading: _submitting,
              onPressed: available ? _submit : null,
            ),
            const SizedBox(height: 14),
            const GoogleComingSoonButton(),
            const SizedBox(height: 16),
            const AuthLocalDataNote(),
          ],
        ),
      ),
    );
  }
}
