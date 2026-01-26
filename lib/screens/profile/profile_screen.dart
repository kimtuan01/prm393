import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../services/auth/auth_service.dart';
import '../../services/core/app_localization.dart';
import '../../services/core/app_settings_provider.dart';

import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_menu_section.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        final t = (String key) =>
            AppStrings.t(key, language: settings.language);

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(t('account')),
            backgroundColor: AppTheme.cardColor,
            elevation: 0,
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: t('help'),
                onPressed: () => _showHelpDialog(context, t),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ================= HEADER =================
                  ProfileHeader(user: currentUser, t: t),

                  const SizedBox(height: 16),

                  // ================= MENU =================
                  ProfileMenuSection(t: t),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= HELP DIALOG =================
  void _showHelpDialog(BuildContext context, String Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('help')),
        content: Text('${t('need_support')}\n\n${t('support_info')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close')),
          ),
        ],
      ),
    );
  }
}
