/// Configuración de Supabase inyectada en tiempo de compilación.
///
/// No se versionan credenciales: los valores se pasan con
/// `--dart-define-from-file=supabase.local.json` (ver README). La clave debe
/// ser la **publishable/anon key**; nunca una secret key ni `service_role`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static String get url => _url.trim();

  /// Acepta ambos nombres: `SUPABASE_ANON_KEY` (nombre del paquete) o
  /// `SUPABASE_PUBLISHABLE_KEY` (nombre actual en Supabase).
  static String get key =>
      _anonKey.trim().isNotEmpty ? _anonKey.trim() : _publishableKey.trim();

  static bool get hasCredentials => url.isNotEmpty && key.isNotEmpty;
}
