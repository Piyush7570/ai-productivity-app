import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
  );
});

class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user =
          await _repository.signInWithEmail(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: name,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordReset(email);
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repository);
});
