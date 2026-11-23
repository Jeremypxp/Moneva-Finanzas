/// Validaciones del formulario de autenticación.
///
/// La interfaz las usa para mostrar errores y las vuelve a aplicar antes de
/// enviar a Supabase. No sustituyen las comprobaciones del servidor.
class AuthValidators {
  const AuthValidators._();

  /// Longitud mínima aplicada por Moneva. Es igual o más estricta que el
  /// mínimo de Supabase y se explica en la pantalla de registro.
  static const minPasswordLength = 8;

  // Letras españolas (con tildes y ñ), espacios simples y guiones.
  static final _namePattern = RegExp(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:[ '\-][A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$",
  );
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// Recorta extremos y colapsa espacios internos repetidos.
  static String normalizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? nameError(String? value) {
    final name = normalizeName(value ?? '');
    if (name.isEmpty) {
      return 'Ingresa tu nombre.';
    }
    if (name.length < 2) {
      return 'El nombre es demasiado corto.';
    }
    if (name.length > 60) {
      return 'El nombre es demasiado largo.';
    }
    if (!_namePattern.hasMatch(name)) {
      return 'Usa solo letras, espacios o guiones.';
    }
    return null;
  }

  static String? emailError(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Ingresa tu correo.';
    }
    if (email.length > 254 || !_emailPattern.hasMatch(email)) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  /// Validación de contraseña para el registro.
  static String? passwordError(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Ingresa una contraseña.';
    }
    if (password.length < minPasswordLength) {
      return 'Usa al menos $minPasswordLength caracteres.';
    }
    return null;
  }

  /// En el inicio de sesión solo se exige que no esté vacía: una cuenta creada
  /// con otra longitud mínima debe poder entrar.
  static String? loginPasswordError(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Ingresa tu contraseña.';
    }
    return null;
  }

  static String? confirmPasswordError(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }
}
