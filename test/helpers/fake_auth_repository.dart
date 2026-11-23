import 'dart:async';

import 'package:moneva_finanzas/features/auth/data/auth_repository.dart';
import 'package:moneva_finanzas/features/auth/domain/auth_failure.dart';
import 'package:moneva_finanzas/features/auth/domain/auth_user.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.signUpOutcome});

  AuthUser? user;
  final _controller = StreamController<AuthUser?>.broadcast();

  SignUpOutcome? signUpOutcome;
  AuthFailure? signInFailure;
  AuthFailure? signUpFailure;

  int signInCalls = 0;
  int signUpCalls = 0;
  int signOutCalls = 0;

  String? lastEmail;
  String? lastPassword;
  String? lastFirstName;
  String? lastLastName;

  @override
  bool get isAvailable => true;

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield user;
    yield* _controller.stream;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    if (signInFailure != null) {
      throw signInFailure!;
    }
    user = const AuthUser(
      id: 'user-1',
      email: 'ana@moneva.app',
      firstName: 'Ana',
      lastName: 'Pérez',
    );
    _controller.add(user);
    return user!;
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    signUpCalls++;
    lastEmail = email;
    lastPassword = password;
    lastFirstName = firstName;
    lastLastName = lastName;
    if (signUpFailure != null) {
      throw signUpFailure!;
    }
    final outcome =
        signUpOutcome ??
        SignUpOutcome(
          user: const AuthUser(
            id: 'user-1',
            email: 'ana@moneva.app',
            firstName: 'Ana',
            lastName: 'Pérez',
          ),
          needsEmailConfirmation: false,
        );
    if (!outcome.needsEmailConfirmation) {
      user = outcome.user;
      _controller.add(user);
    }
    return outcome;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    user = null;
    _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
