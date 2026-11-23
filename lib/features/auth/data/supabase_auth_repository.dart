import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../domain/auth_failure.dart';
import '../domain/auth_user.dart';
import '../domain/auth_validators.dart';
import 'auth_repository.dart';

/// Implementación de Supabase Auth. No conoce ni toca la base SQLite.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final supabase.SupabaseClient _client;

  @override
  bool get isAvailable => true;

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.map(
      (event) => _mapUser(event.session?.user),
    );
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthFailure(
          AuthFailureKind.unknown,
          'No se pudo iniciar sesión. Inténtalo de nuevo.',
        );
      }
      return user;
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName',
        },
      );

      // Con la confirmación desactivada, Supabase puede devolver un usuario
      // "ofuscado" sin identidades cuando el correo ya existe.
      final identities = response.user?.identities;
      if (identities != null && identities.isEmpty) {
        throw const AuthFailure(
          AuthFailureKind.alreadyExists,
          'Ya existe una cuenta con este correo. Inicia sesión.',
        );
      }

      return SignUpOutcome(
        user: _mapUser(response.user),
        needsEmailConfirmation: response.session == null,
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw _mapError(error);
    }
  }

  AuthUser? _mapUser(supabase.User? user) {
    if (user == null) {
      return null;
    }
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AuthUser(
      id: user.id,
      email: user.email,
      firstName: _readMetadata(metadata, 'first_name'),
      lastName: _readMetadata(metadata, 'last_name'),
    );
  }

  String? _readMetadata(Map<String, dynamic> metadata, String key) {
    final value = metadata[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  AuthFailure _mapError(Object error) {
    if (error is AuthFailure) {
      return error;
    }
    if (error is supabase.AuthException) {
      return _mapAuthException(error);
    }
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return const AuthFailure(
        AuthFailureKind.network,
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
      );
    }
    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('failed host lookup') ||
        text.contains('network') ||
        text.contains('timed out')) {
      return const AuthFailure(
        AuthFailureKind.network,
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
      );
    }
    return const AuthFailure(
      AuthFailureKind.unknown,
      'No pudimos completar la operación. Inténtalo de nuevo.',
    );
  }

  AuthFailure _mapAuthException(supabase.AuthException error) {
    final code = (error.code ?? '').toLowerCase();
    final message = error.message.toLowerCase();

    if (code == 'invalid_credentials' || message.contains('invalid login')) {
      return const AuthFailure(
        AuthFailureKind.invalidCredentials,
        'Correo o contraseña incorrectos.',
      );
    }
    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return const AuthFailure(
        AuthFailureKind.emailNotConfirmed,
        'Tu correo aún no está confirmado. Revisa tu bandeja de entrada y '
        'confirma la cuenta antes de iniciar sesión.',
      );
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('already registered') ||
        message.contains('already exists')) {
      return const AuthFailure(
        AuthFailureKind.alreadyExists,
        'Ya existe una cuenta con este correo. Inicia sesión.',
      );
    }
    if (code == 'weak_password' ||
        message.contains('password should be at least') ||
        message.contains('password is too short') ||
        message.contains('weak password')) {
      return AuthFailure(
        AuthFailureKind.weakPassword,
        'La contraseña es demasiado débil. Usa al menos '
        '${AuthValidators.minPasswordLength} caracteres.',
      );
    }
    if (code == 'over_email_send_rate_limit' ||
        code == 'over_request_rate_limit' ||
        message.contains('rate limit') ||
        message.contains('too many requests')) {
      return const AuthFailure(
        AuthFailureKind.rateLimited,
        'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
      );
    }
    if (code == 'email_address_invalid' ||
        code == 'email_address_not_authorized' ||
        message.contains('invalid email') ||
        message.contains('unable to validate email')) {
      return const AuthFailure(
        AuthFailureKind.invalidEmail,
        'Ingresa un correo válido.',
      );
    }
    if (message.contains('failed host lookup') ||
        message.contains('socket') ||
        message.contains('network')) {
      return const AuthFailure(
        AuthFailureKind.network,
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
      );
    }
    return AuthFailure(
      AuthFailureKind.unknown,
      'No pudimos completar la operación. Inténtalo de nuevo.',
    );
  }
}
