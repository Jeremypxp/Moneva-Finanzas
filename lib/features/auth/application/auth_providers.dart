import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../application/auth_deep_link_handler.dart';
import '../domain/auth_user.dart';

/// Sesión actual. Su valor inicial es síncrono (sesión restaurada por el
/// cliente) y se mantiene al día con el flujo de Supabase.
final authSessionProvider = NotifierProvider<AuthSessionController, AuthUser?>(
  AuthSessionController.new,
);

/// Maneja los deep links entrantes de verificación de correo.
final authDeepLinkHandlerProvider = Provider<AuthDeepLinkHandler>((ref) {
  return AuthDeepLinkHandler.instance;
});

class AuthSessionController extends Notifier<AuthUser?> {
  @override
  AuthUser? build() {
    final repository = ref.watch(authRepositoryProvider);
    var disposed = false;
    final subscription = repository.authStateChanges().listen((user) {
      if (!disposed) {
        state = user;
      }
    });
    ref.onDispose(() {
      disposed = true;
      subscription.cancel();
    });
    return repository.currentUser;
  }
}
