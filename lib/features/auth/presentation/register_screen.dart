import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_validators.dart';
import '../domain/password_strength.dart';
import 'widgets/auth_components.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    FocusScope.of(context).unfocus();

    final firstName = AuthValidators.normalizeName(_firstNameController.text);
    final lastName = AuthValidators.normalizeName(_lastNameController.text);
    final email = _emailController.text.trim();
    // La contraseña se envía tal cual: sin recortes ni cambios.
    final password = _passwordController.text;
    final confirmation = _confirmController.text;

    final formValid = _formKey.currentState?.validate() ?? false;
    final domainValid =
        AuthValidators.nameError(firstName) == null &&
        AuthValidators.nameError(lastName) == null &&
        AuthValidators.emailError(email) == null &&
        AuthValidators.passwordError(password) == null &&
        AuthValidators.confirmPasswordError(confirmation, password) == null;
    if (!formValid || !domainValid) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final outcome = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName,
          );

      if (!mounted) {
        return;
      }

      if (outcome.needsEmailConfirmation) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.mark_email_unread_outlined),
            title: const Text('Confirma tu correo'),
            content: Text(
              'Enviamos un mensaje a $email. Abre el enlace de confirmación y '
              'luego inicia sesión en Moneva.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        if (mounted) {
          context.go('/login');
        }
      } else if (outcome.user == null) {
        setState(
          () => _error =
              'La cuenta se creó, pero no se pudo iniciar sesión. '
              'Inténtalo desde la pantalla de acceso.',
        );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada. ¡Bienvenido a Moneva!'),
            ),
          );
        // El router redirige al detectar la sesión.
      }
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failure.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos crear la cuenta. Inténtalo de nuevo.',
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
    final available = ref.watch(authRepositoryProvider).isAvailable;
    final password = _passwordController.text;
    final strength = evaluatePasswordStrength(password);

    return AuthScaffold(
      title: 'Crea tu cuenta',
      centerHeader: true,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '¿Ya tienes cuenta?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : () => context.go('/login'),
            child: const Text('Inicia sesión'),
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
                    'El registro no está configurado en esta compilación. '
                    'La app sigue funcionando con tus datos locales.',
              )
            else if (_error != null)
              AuthErrorBanner(message: _error!),
            TextFormField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              validator: AuthValidators.nameError,
              decoration: const InputDecoration(labelText: 'Nombres'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.familyName],
              validator: AuthValidators.nameError,
              decoration: const InputDecoration(labelText: 'Apellidos'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: AuthValidators.emailError,
              decoration: const InputDecoration(
                labelText: 'Correo',
                hintText: 'tu@correo.com',
              ),
            ),
            const SizedBox(height: 14),
            AuthPasswordField(
              controller: _passwordController,
              label: 'Contraseña',
              validator: AuthValidators.passwordError,
              helperText: passwordRuleText(),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                } else {
                  setState(() {});
                }
                // Si ya se escribió la confirmación, se vuelve a comparar
                // contra la contraseña actual.
                if (_confirmController.text.isNotEmpty) {
                  _confirmKey.currentState?.validate();
                }
              },
            ),
            if (password.isNotEmpty) PasswordStrengthBar(result: strength),
            const SizedBox(height: 14),
            TextFormField(
              key: _confirmKey,
              controller: _confirmController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) => AuthValidators.confirmPasswordError(
                value,
                _passwordController.text,
              ),
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
              ),
            ),
            const SizedBox(height: 20),
            AuthSubmitButton(
              label: 'Crear cuenta',
              loading: _submitting,
              onPressed: available ? _submit : null,
            ),
            const SizedBox(height: 16),
            const AuthLocalDataNote(),
          ],
        ),
      ),
    );
  }
}
