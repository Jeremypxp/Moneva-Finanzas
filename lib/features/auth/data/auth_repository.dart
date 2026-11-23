import '../domain/auth_user.dart';

/// Resultado del registro. Si Supabase exige confirmación por correo, no hay
/// sesión todavía y la persona debe revisar su bandeja.
class SignUpOutcome {
  const SignUpOutcome({
    required this.user,
    required this.needsEmailConfirmation,
  });

  final AuthUser? user;
  final bool needsEmailConfirmation;
}

/// Operaciones de autenticación, aisladas del almacenamiento SQLite.
abstract interface class AuthRepository {
  bool get isAvailable;

  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signIn({required String email, required String password});

  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });

  Future<void> signOut();
}
