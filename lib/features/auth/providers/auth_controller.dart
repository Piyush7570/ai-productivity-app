import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});

class AuthController {
  final AuthRepository _repository;

  AuthController(this._repository);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _repository.signInWithEmail(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _repository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordReset(email);
  }

  Future<void> signInWithGoogle() async {
    await _repository.signInWithGoogle();
  }
}
