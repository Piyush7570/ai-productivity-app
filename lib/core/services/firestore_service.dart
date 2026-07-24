import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new user document after signup
  Future<void> createUser({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'streak': 0,
      'xp': 0,
      'completedTasks': 0,
      'totalTasks': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch user document
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
    String uid,
  ) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Update user data
  Future<void> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('users').doc(uid).update(data);
  }
}
