import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth? _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  // Helper to determine if we are operating in Mock or Firebase mode
  bool get _useFirebase {
    try {
      return _firebaseAuth != null;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    if (_useFirebase) {
      final user = _firebaseAuth!.currentUser;
      if (user != null) {
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoUrl: user.photoURL,
        );
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('mock_uid');
      final email = prefs.getString('mock_email');
      final name = prefs.getString('mock_name');
      if (uid != null && email != null) {
        return UserModel(
          uid: uid,
          email: email,
          displayName: name ?? 'Guest User',
        );
      }
    }
    return null;
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_useFirebase) {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
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
    } else {
      // Mock validation
      if (email.contains('@') && password.length >= 6) {
        final user = UserModel(
          uid: 'mock_user_123',
          email: email,
          displayName: email.split('@')[0],
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mock_uid', user.uid);
        await prefs.setString('mock_email', user.email);
        await prefs.setString('mock_name', user.displayName);
        return user;
      } else {
        throw Exception('Invalid email or password (min 6 characters).');
      }
    }
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_useFirebase) {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(displayName);
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
      );
    } else {
      final user = UserModel(
        uid: 'mock_user_123',
        email: email,
        displayName: displayName,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_uid', user.uid);
      await prefs.setString('mock_email', user.email);
      await prefs.setString('mock_name', user.displayName);
      return user;
    }
  }

  Future<UserModel> signInWithGoogle() async {
    if (_useFirebase) {
      // Google sign-in details on Firebase
      // Note: Actual native implementation depends on google_sign_in package, but we mock/handle it
      // as part of the repository capability.
      throw UnimplementedError('Configure google_sign_in package on real hardware.');
    } else {
      final user = UserModel(
        uid: 'mock_google_user',
        email: 'google.guest@example.com',
        displayName: 'Google Guest',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_uid', user.uid);
      await prefs.setString('mock_email', user.email);
      await prefs.setString('mock_name', user.displayName);
      return user;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (_useFirebase) {
      await _firebaseAuth!.sendPasswordResetEmail(email: email);
    } else {
      // Mock action
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> signOut() async {
    if (_useFirebase) {
      await _firebaseAuth!.signOut();
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mock_uid');
      await prefs.remove('mock_email');
      await prefs.remove('mock_name');
    }
  }
}
