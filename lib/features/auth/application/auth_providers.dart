import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../domain/auth_user.dart';

/// Sesión actual. Su valor inicial es síncrono (sesión restaurada por el
/// cliente) y se mantiene al día con el flujo de Supabase.
final authSessionProvider = NotifierProvider<AuthSessionController, AuthUser?>(
  AuthSessionController.new,
);

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
