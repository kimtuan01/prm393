import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth/user_provider.dart';
import '../screens/profile/account/account_management_screen.dart';

/// Reusable avatar widget that syncs across all screens
class UserAvatar extends StatelessWidget {
  final double radius;
  final bool navigateOnTap;

  const UserAvatar({super.key, this.radius = 24, this.navigateOnTap = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        final userName = user?.fullName ?? 'User';
        final avatarPath = user?.avatarPath;

        // Check if avatar file exists safely
        bool hasValidAvatar = false;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          try {
            hasValidAvatar = File(avatarPath).existsSync();
          } catch (e) {
            // File path invalid or file not accessible
            hasValidAvatar = false;
          }
        }

        Widget avatar = CircleAvatar(
          key: ValueKey(avatarPath ?? 'default_avatar'),
          radius: radius,
          backgroundColor: Colors.blueAccent,
          backgroundImage: hasValidAvatar ? FileImage(File(avatarPath!)) : null,
          child: !hasValidAvatar
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.8,
                  ),
                )
              : null,
        );

        if (navigateOnTap) {
          return GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountManagementScreen(),
                ),
              );
              // Refresh avatar after returning from account management
              if (context.mounted) {
                userProvider.refresh();
              }
            },
            child: avatar,
          );
        }

        return avatar;
      },
    );
  }
}
