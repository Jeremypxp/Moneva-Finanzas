import '../domain/auth_failure.dart';
import '../domain/auth_user.dart';
import 'auth_repository.dart';

/// Modo local: la app funciona sin cuenta. Se usa cuando la compilación no
/// incluye credenciales de Supabase o el cliente no pudo inicializarse.
class DisabledAuthRepository implements AuthRepository {
  const DisabledAuthRepository();

  @override
  bool get isAvailable => false;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    throw const AuthFailure.unavailable();
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    throw const AuthFailure.unavailable();
  }

  @override
  Future<void> signOut() async {}
}
