/// Punto de extensión para autenticación.
///
/// En esta primera entrega la app funciona solo con datos locales y no hay
/// inicio de sesión. Cuando se integre Supabase Auth, se implementará esta
/// interfaz y se cambiará el proveedor de inyección; las pantallas no necesitan
/// conocer el proveedor de identidad.
abstract interface class AuthGateway {
  /// Identificador del usuario actual, o `null` si la sesión es local.
  Future<String?> currentUserId();

  /// Flujo de cambios de sesión para futuras sincronizaciones.
  Stream<String?> authStateChanges();
}

/// Implementación local: no simula un inicio de sesión ni crea usuarios.
class LocalOnlyAuthGateway implements AuthGateway {
  const LocalOnlyAuthGateway();

  @override
  Future<String?> currentUserId() async => null;

  @override
  Stream<String?> authStateChanges() => const Stream<String?>.empty();
}
