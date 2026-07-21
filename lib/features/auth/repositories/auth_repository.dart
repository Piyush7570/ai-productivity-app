import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

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
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    await user.updateDisplayName(displayName);
    await user.reload();

    final updatedUser = _firebaseAuth.currentUser!;

    return UserModel(
      uid: updatedUser.uid,
      email: updatedUser.email ?? '',
      displayName: updatedUser.displayName ?? displayName,
      photoUrl: updatedUser.photoURL,
    );
  }

  Future<UserModel> signInWithGoogle() async {
    throw UnimplementedError(
      'Google Sign-In will be implemented later.',
    );
  }

  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
