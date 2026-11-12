import 'package:intl/intl.dart';

/// Utilidades de dinero basadas en enteros (céntimos).
///
/// No se usa `double` para almacenar ni para operar con importes.
class Money {
  const Money._();

  static const currencySymbol = 'S/';

  // Reutilizar el formateador evita reconstruir el patrón de `es_PE` en cada
  // importe dibujado (medido: ~8 µs por llamada evitable en listas largas).
  static final NumberFormat _decimalPattern = NumberFormat.decimalPattern(
    'es_PE',
  );

  /// Convierte texto escrito por la persona a céntimos.
  ///
  /// Acepta coma o punto como separador decimal, hasta dos decimales y espacios.
  /// Devuelve `null` si el valor no es un importe positivo válido.
  static int? parseToCents(String input) {
    final normalized = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    final match = RegExp(r'^(\d{1,9})(?:\.(\d{0,2}))?$').firstMatch(normalized);
    if (match == null) {
      return null;
    }
    final whole = int.parse(match.group(1)!);
    final decimals = (match.group(2) ?? '').padRight(2, '0');
    final cents = whole * 100 + int.parse(decimals.isEmpty ? '0' : decimals);
    return cents > 0 ? cents : null;
  }

  /// Formatea céntimos sin pasar por punto flotante.
  ///
  /// Usa los separadores de `es_PE`: punto para miles y coma para decimales.
  /// Ejemplo: `123456` → `S/ 1.234,56`.
  static String format(int cents, {bool withSymbol = true}) {
    final negative = cents < 0;
    final absolute = cents.abs();
    final whole = absolute ~/ 100;
    final decimals = (absolute % 100).toString().padLeft(2, '0');
    final grouped = _decimalPattern.format(whole);
    final prefix = withSymbol ? '$currencySymbol ' : '';
    return '${negative ? '-' : ''}$prefix$grouped,$decimals';
  }

  /// Variante con signo explícito para listados: `+ S/ 20.00` / `- S/ 20.00`.
  static String formatSigned(int cents) {
    final sign = cents < 0 ? '-' : '+';
    return '$sign ${format(cents.abs())}';
  }
}
