import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user.dart';

/// Provider to manage user state and sync avatar across screens
class UserProvider extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  /// Load current user from Hive
  Future<void> loadCurrentUser() async {
    try {
      final userBox = await Hive.openBox<User>('users');
      final users = userBox.values.toList();

      if (users.isNotEmpty) {
        _currentUser = users.first;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  /// Update avatar path and notify all listeners
  Future<void> updateAvatar(String? avatarPath) async {
    try {
      if (_currentUser == null) return;

      final userBox = await Hive.openBox<User>('users');

      // Find user by checking all keys (could be email or id)
      User? existingUser;
      for (var key in userBox.keys) {
        final user = userBox.get(key);
        if (user?.id == _currentUser!.id ||
            user?.email == _currentUser!.email) {
          existingUser = user;
          break;
        }
      }

      if (existingUser != null) {
        // Update the avatar path
        existingUser.avatarPath = avatarPath;
        await existingUser.save(); // Use save() to update in-place

        // Update local reference
        _currentUser = existingUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      rethrow;
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar() async {
    await updateAvatar(null);
  }

  /// Refresh user data
  Future<void> refresh() async {
    await loadCurrentUser();
  }
}
