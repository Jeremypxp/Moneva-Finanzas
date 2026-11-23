import 'package:flutter_test/flutter_test.dart';
import 'package:moneva_finanzas/features/auth/domain/auth_validators.dart';

void main() {
  group('nombres', () {
    test('acepta letras españolas, tildes, ñ, espacios y guiones', () {
      expect(AuthValidators.nameError('José María'), isNull);
      expect(AuthValidators.nameError('Ñusta'), isNull);
      expect(AuthValidators.nameError('Ana-Lucía'), isNull);
      expect(AuthValidators.nameError("O'Higgins"), isNull);
    });

    test('recorta extremos y colapsa espacios internos', () {
      expect(AuthValidators.normalizeName('  José   María  '), 'José María');
    });

    test('rechaza vacío, solo espacios y caracteres no permitidos', () {
      expect(AuthValidators.nameError(''), isNotNull);
      expect(AuthValidators.nameError('   '), isNotNull);
      expect(AuthValidators.nameError('Ana2'), isNotNull);
      expect(AuthValidators.nameError('Ana@'), isNotNull);
    });
  });

  group('correo', () {
    test('recorta y valida un formato razonable', () {
      expect(AuthValidators.emailError('  ana@moneva.app '), isNull);
      expect(AuthValidators.emailError('ana@moneva'), isNotNull);
      expect(AuthValidators.emailError('ana moneva.app'), isNotNull);
      expect(AuthValidators.emailError(''), isNotNull);
    });
  });

  group('contraseña', () {
    test('exige el mínimo sin recortar el valor', () {
      expect(AuthValidators.passwordError('1234567'), isNotNull);
      expect(AuthValidators.passwordError('12345678'), isNull);
      // Los espacios cuentan como caracteres: la contraseña no se recorta.
      expect(AuthValidators.passwordError('  abcdef  '), isNull);
    });

    test('la confirmación debe coincidir exactamente', () {
      expect(
        AuthValidators.confirmPasswordError('Secreta123', 'Secreta123'),
        isNull,
      );
      expect(
        AuthValidators.confirmPasswordError('secreta123', 'Secreta123'),
        isNotNull,
      );
      expect(AuthValidators.confirmPasswordError('', 'Secreta123'), isNotNull);
    });

    test('el inicio de sesión solo exige contraseña no vacía', () {
      expect(AuthValidators.loginPasswordError('123'), isNull);
      expect(AuthValidators.loginPasswordError(''), isNotNull);
    });
  });
}
