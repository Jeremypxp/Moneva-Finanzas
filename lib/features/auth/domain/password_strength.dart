import 'auth_validators.dart';

enum PasswordStrength { weak, fair, good, strong }

/// Resultado local de robustez. Es orientativo: no garantiza que una
/// contraseña sea imposible de adivinar.
class PasswordStrengthResult {
  const PasswordStrengthResult({
    required this.strength,
    required this.label,
    required this.score,
  });

  final PasswordStrength strength;
  final String label;

  /// De 0 a 4, para pintar los segmentos de la barra.
  final int score;
}

const _commonPatterns = <String>[
  'password',
  'contrasena',
  'contraseña',
  '123456',
  'qwerty',
  'admin',
  'iloveyou',
  'welcome',
  'moneva',
];

PasswordStrengthResult evaluatePasswordStrength(String password) {
  if (password.isEmpty) {
    return const PasswordStrengthResult(
      strength: PasswordStrength.weak,
      label: 'Débil',
      score: 0,
    );
  }

  final lower = password.toLowerCase();
  final hasCommonPattern = _commonPatterns.any(lower.contains);
  final hasLower = password.contains(RegExp(r'[a-záéíóúüñ]'));
  final hasUpper = password.contains(RegExp(r'[A-ZÁÉÍÓÚÜÑ]'));
  final hasDigit = password.contains(RegExp(r'\d'));
  final hasSymbol = password.contains(RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ]'));
  final hasRepeatedRun = RegExp(r'(.)\1{2,}').hasMatch(password);

  var points = 0;
  if (password.length >= AuthValidators.minPasswordLength) points++;
  if (password.length >= 12) points++;
  if (hasLower && hasUpper) points++;
  if (hasDigit) points++;
  if (hasSymbol) points++;

  if (hasCommonPattern) points -= 2;
  if (hasRepeatedRun) points -= 1;
  points = points.clamp(0, 5);

  // Nunca se muestra mejor que "Débil" si no cumple el mínimo.
  if (password.length < AuthValidators.minPasswordLength) {
    return const PasswordStrengthResult(
      strength: PasswordStrength.weak,
      label: 'Débil',
      score: 1,
    );
  }

  if (points <= 1) {
    return const PasswordStrengthResult(
      strength: PasswordStrength.weak,
      label: 'Débil',
      score: 1,
    );
  }
  if (points == 2) {
    return const PasswordStrengthResult(
      strength: PasswordStrength.fair,
      label: 'Aceptable',
      score: 2,
    );
  }
  if (points == 3) {
    return const PasswordStrengthResult(
      strength: PasswordStrength.good,
      label: 'Buena',
      score: 3,
    );
  }
  return const PasswordStrengthResult(
    strength: PasswordStrength.strong,
    label: 'Fuerte',
    score: 4,
  );
}
