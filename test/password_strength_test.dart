import 'package:flutter_test/flutter_test.dart';
import 'package:moneva_finanzas/features/auth/domain/password_strength.dart';

void main() {
  test('una contraseña corta siempre es débil', () {
    final result = evaluatePasswordStrength('Ab1!');
    expect(result.strength, PasswordStrength.weak);
    expect(result.label, 'Débil');
  });

  test('una contraseña común no llega a fuerte', () {
    final result = evaluatePasswordStrength('Password1');
    expect(result.strength, isNot(PasswordStrength.strong));
  });

  test('combina longitud y variedad', () {
    expect(
      evaluatePasswordStrength('Abcdef12').strength,
      PasswordStrength.good,
    );
    expect(
      evaluatePasswordStrength('Nube\$Verde2026').strength,
      PasswordStrength.strong,
    );
    // Una frase larga con espacios obtiene buena, no fuerte.
    expect(
      evaluatePasswordStrength('correcto caballo grapa').strength,
      PasswordStrength.good,
    );
  });

  test('el puntaje se mantiene entre 0 y 4', () {
    for (final password in ['', 'a', 'Password1', 'Nube\$Verde2026']) {
      final score = evaluatePasswordStrength(password).score;
      expect(score, inInclusiveRange(0, 4));
    }
  });
}
