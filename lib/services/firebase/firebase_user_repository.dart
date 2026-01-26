import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';

// ============================================================================
// FIREBASE USER REPOSITORY - Cloud storage for user profiles
// ============================================================================

class FirebaseUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection path: users/{userId}
  CollectionReference<Map<String, dynamic>> get _usersRef {
    return _firestore.collection('users');
  }

  // ================= CREATE/UPDATE =================
  Future<void> saveUser(User user) async {
    try {
      await _usersRef.doc(user.id).set(_userToMap(user));
      print('✅ [Firebase] Saved user: ${user.id}');
    } catch (e) {
      print('❌ [Firebase] Error saving user: $e');
      rethrow;
    }
  }

  // ================= READ =================
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) return null;
      return _userFromMap(doc.data()!);
    } catch (e) {
      print('❌ [Firebase] Error getting user: $e');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      print('🔍 [Firebase] Searching for user with email: $email');
      final snapshot = await _usersRef
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      print('📊 [Firebase] Found ${snapshot.docs.length} documents');
      if (snapshot.docs.isEmpty) {
        print('⚠️ [Firebase] No user found with email: $email');
        return null;
      }
      print('✅ [Firebase] User found: ${snapshot.docs.first.id}');
      return _userFromMap(snapshot.docs.first.data());
    } catch (e) {
      print('❌ [Firebase] Error getting user by email: $e');
      print('❌ [Firebase] Error type: ${e.runtimeType}');
      return null;
    }
  }

  // ================= DELETE =================
  Future<void> deleteUser(String userId) async {
    try {
      await _usersRef.doc(userId).delete();
      print('✅ [Firebase] Deleted user: $userId');
    } catch (e) {
      print('❌ [Firebase] Error deleting user: $e');
      rethrow;
    }
  }

  // ================= UPDATE FIELDS =================
  Future<void> updateLastLogin(String userId) async {
    try {
      await _usersRef.doc(userId).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ [Firebase] Error updating last login: $e');
    }
  }

  Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    try {
      await _usersRef.doc(userId).update({'isVerified': isVerified});
    } catch (e) {
      print('❌ [Firebase] Error updating verification status: $e');
    }
  }

  // ================= HELPERS =================
  Map<String, dynamic> _userToMap(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'passwordHash': user.passwordHash,
      'createdAt': user.createdAt.toIso8601String(),
      'lastLoginAt': user.lastLoginAt?.toIso8601String(),
      'preferences': user.preferences,
      'isVerified': user.isVerified,
    };
  }

  User _userFromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      passwordHash: map['passwordHash'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
      preferences: List<String>.from(map['preferences'] ?? []),
      isVerified: map['isVerified'] ?? false,
    );
  }
}
