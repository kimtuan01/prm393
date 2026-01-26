import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../screens/profile/account/account_management_screen.dart';
import '../user_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final dynamic user;
  final Function(String) t;

  const ProfileHeader({super.key, required this.user, required this.t});

  @override
  Widget build(BuildContext context) {
    final userName = user?.fullName ?? 'User';
    final userEmail = user?.email ?? 'email@example.com';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountManagementScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        color: AppTheme.cardColor,
        child: Row(
          children: [
            const UserAvatar(radius: 30, navigateOnTap: false),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AccountBadge(t: t),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  final Function(String) t;
  const _AccountBadge({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        t('free_account'),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
