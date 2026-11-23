/// Tipos de fallo de autenticación que la interfaz traduce a mensajes claros.
enum AuthFailureKind {
  network,
  invalidCredentials,
  invalidEmail,
  alreadyExists,
  weakPassword,
  emailNotConfirmed,
  rateLimited,
  unavailable,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind, this.message);

  const AuthFailure.unavailable()
    : kind = AuthFailureKind.unavailable,
      message =
          'El inicio de sesión no está configurado en esta compilación. '
          'Añade las credenciales de Supabase para activarlo.';

  final AuthFailureKind kind;
  final String message;

  @override
  String toString() => message;
}
