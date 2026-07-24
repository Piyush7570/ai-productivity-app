import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../../core/services/firestore_service.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirestoreService _firestoreService = FirestoreService();

  AuthRepository({required FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) return null;

    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'User',
      photoUrl: user.photoURL,
    );
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
          throw Exception('Invalid email or password.');

        case 'user-not-found':
          throw Exception('No account found with this email.');

        case 'wrong-password':
          throw Exception('Incorrect password.');

        case 'invalid-email':
          throw Exception('Please enter a valid email address.');

        case 'too-many-requests':
          throw Exception(
            'Too many login attempts. Please try again later.',
          );

        case 'network-request-failed':
          throw Exception(
            'No internet connection. Please check your network.',
          );

        default:
          throw Exception(e.message ?? 'Login failed.');
      }
    }
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      await user.updateDisplayName(displayName);
      await user.reload();

      final updatedUser = _firebaseAuth.currentUser!;
      await _firestoreService.createUser(
        uid: updatedUser.uid,
        displayName: displayName,
        email: updatedUser.email ?? '',
      );

      return UserModel(
        uid: updatedUser.uid,
        email: updatedUser.email ?? '',
        displayName: updatedUser.displayName ?? displayName,
        photoUrl: updatedUser.photoURL,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
            'An account already exists with this email.',
          );

        case 'weak-password':
          throw Exception(
            'Password should be at least 6 characters long.',
          );

        case 'invalid-email':
          throw Exception(
            'Please enter a valid email address.',
          );

        case 'network-request-failed':
          throw Exception(
            'No internet connection. Please check your network.',
          );

        default:
          throw Exception(e.message ?? 'Registration failed.');
      }
    }
  }

  Future<UserModel> signInWithGoogle() async {
    throw UnimplementedError(
      'Google Sign-In will be implemented later.',
    );
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');

        case 'invalid-email':
          throw Exception('Please enter a valid email address.');

        case 'network-request-failed':
          throw Exception(
            'No internet connection. Please check your network.',
          );

        default:
          throw Exception(e.message ?? 'Unable to send reset email.');
      }
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
  );
});
