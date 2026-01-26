import 'package:expense_tracker_app/screens/wallet/wallets_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../services/auth/auth_service.dart';
import '../../utils/notification_helper.dart';

import '../../screens/profile/settings/category_group/category_group_screen.dart';
import '../../screens/profile/account/account_management_screen.dart';
import '../../screens/profile/settings/settings_screen.dart';
import '../../screens/about/about_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/chatbot/financial_chatbot_screen.dart';

class ProfileMenuSection extends StatelessWidget {
  final String Function(String) t;

  const ProfileMenuSection({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= WALLET & FEATURES =================
        _buildGroup(
          children: [
            _menuItem(
              icon: Icons.account_balance_wallet_outlined,
              title: t('my_wallets'),
              onTap: () => _push(context, const MyWalletScreen()),
            ),
            _divider(),

            // ✅ NHÓM DANH MỤC – ĐÃ MỞ ĐƯỢC
            _menuItem(
              icon: Icons.category_outlined,
              title: t('category_groups'),
              onTap: () => _push(context, const CategoryGroupScreen()),
            ),
            _divider(),

            _menuItem(
              icon: Icons.repeat,
              title: t('recurring_transactions'),
              onTap: () => _comingSoon(context),
            ),
            _divider(),

            _menuItem(
              icon: Icons.build_outlined,
              title: t('tools'),
              onTap: () => _comingSoon(context),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ================= ACCOUNT & SETTINGS =================
        _buildGroup(
          children: [
            _menuItem(
              icon: Icons.person_outline,
              title: t('account_management'),
              onTap: () => _push(context, const AccountManagementScreen()),
            ),
            _divider(),

            _menuItem(
              icon: Icons.settings_outlined,
              title: t('settings'),
              onTap: () => _push(context, const SettingsScreen()),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ================= INFO & SUPPORT =================
        _buildGroup(
          children: [
            _menuItem(
              icon: Icons.explore_outlined,
              title: t('explore_fintracker'),
              onTap: () => _push(context, const AboutScreen()),
            ),
            _divider(),

            _menuItem(
              icon: Icons.smart_toy,
              title: 'Chatbot Tài Chính',
              onTap: () => _push(context, const FinancialChatbotScreen()),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ================= LOGOUT =================
        _buildGroup(
          children: [
            _menuItem(
              icon: Icons.logout,
              title: t('logout'),
              textColor: Colors.red,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ],
    );
  }

  // ================= UI HELPERS =================

  Widget _buildGroup({required List<Widget> children}) {
    return Container(
      color: AppTheme.cardColor,
      child: Column(children: children),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: textColor ?? AppTheme.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: textColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: Colors.grey[200],
    );
  }

  // ================= ACTIONS =================

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _comingSoon(BuildContext context) {
    AppNotification.showInfo(context, t('feature_under_development'));
  }

  void _logout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    await authService.logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
