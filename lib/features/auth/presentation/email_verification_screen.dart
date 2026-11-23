import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_providers.dart';
import 'widgets/auth_components.dart';

/// Pantalla mostrada cuando la app se abre desde el enlace de verificación de
/// correo de Supabase (`moneva://auth-callback/`).
///
/// Muestra un mensaje flotante (SnackBar) informando si la verificación se
/// completó o falló, y permite ir a iniciar sesión.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final handler = ref.read(authDeepLinkHandlerProvider);
      final verified = handler.hasPendingLink;
      handler.clearPendingLink();

      if (verified) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Correo verificado. Ya puedes iniciar sesión.'),
              backgroundColor: Color(0xFF16805F),
              duration: Duration(seconds: 3),
            ),
          );
        // Navega al login después de mostrar el mensaje flotante.
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/login');
          }
        });
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Enlace inválido o expirado. Solicita un nuevo enlace de '
                'confirmación desde el inicio de sesión.',
              ),
              backgroundColor: Color(0xFFC8543A),
              duration: Duration(seconds: 4),
            ),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Verificación de correo',
      subtitle:
          'Espera un momento mientras procesamos la confirmación de tu '
          'correo electrónico.',
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
          const Icon(Icons.mark_email_unread_rounded, size: 64),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
