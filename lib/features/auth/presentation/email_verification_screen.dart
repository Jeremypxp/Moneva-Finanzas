import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_components.dart';

/// Pantalla mostrada cuando la app se abre desde el enlace de verificación de
/// correo de Supabase (`moneva://auth-callback/`).
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  @override
  void initState() {
    super.initState();
    // Limpia el enlace pendiente después de mostrar la pantalla, para no
    // navegar de nuevo en cada reconstrucción.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(authDeepLinkHandlerProvider).clearPendingLink();
    });
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(authDeepLinkHandlerProvider);
    final theme = Theme.of(context);
    final colors = theme.extension<FinanceColors>()!;

    final verified = handler.hasPendingLink;

    return AuthScaffold(
      title: verified ? 'Correo verificado' : 'Enlace inválido',
      subtitle: verified
          ? 'Tu correo ha sido confirmado. Ahora puedes iniciar sesión con tu '
                'correo y contraseña.'
          : 'El enlace de verificación es inválido o ha expirado. Solicita un '
                'nuevo código de confirmación desde la pantalla de inicio de '
                'sesión.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ir a iniciar sesión'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            verified
                ? Icons.mark_email_read_rounded
                : Icons.error_outline_rounded,
            size: 64,
            color: verified ? colors.income : colors.expense,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
