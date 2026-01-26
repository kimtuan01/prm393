import 'package:hive/hive.dart';

part 'user.g.dart'; // Generated file

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String email;

  @HiveField(2)
  late String firstName;

  @HiveField(3)
  late String lastName;

  @HiveField(4)
  late String passwordHash; // Hashed password, not plain text

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime? lastLoginAt;

  @HiveField(7)
  late List<String> preferences; // User preferences từ Favorites screen

  @HiveField(8)
  late bool isVerified; // Email verification status

  @HiveField(9)
  String? avatarPath; // Path to avatar image file

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.passwordHash,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences = const [],
    this.isVerified = false,
    this.avatarPath,
  });

  // Get full name
  String get fullName => '$firstName $lastName';

  // Convert to Map (for debugging)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
      'isVerified': isVerified,
      'avatarPath': avatarPath,
    };
  }

  @override
  String toString() {
    return 'User{email: $email, name: $fullName}';
  }
}
