import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/core/app_localization.dart';
import '../../services/core/app_settings_provider.dart';

// ============================================================================
// ABOUT SCREEN - Information about the app
// ============================================================================

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        t(String key) => AppStrings.t(key, language: settings.language);

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(t('explore_fintracker')),
            backgroundColor: AppTheme.cardColor,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // App Logo/Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  color: AppTheme.cardColor,
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 80,
                        color: AppTheme.primaryTeal,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Expense Tracker',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Features Section
                _buildSection(
                  title: t('features'),
                  children: [
                    _buildListItem(
                      Icons.add_circle_outline,
                      t('track_expenses'),
                    ),
                    _buildListItem(
                      Icons.receipt_long,
                      t('manage_transactions'),
                    ),
                    _buildListItem(Icons.category, t('categorize_spending')),
                    _buildListItem(Icons.pie_chart, t('view_reports')),
                    _buildListItem(Icons.camera_alt, t('ocr_receipts')),
                  ],
                ),

                const SizedBox(height: 16),

                // About Section
                _buildSection(
                  title: t('about'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        t('app_description'),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Contact Section
                _buildSection(
                  title: t('contact'),
                  children: [
                    _buildListItem(
                      Icons.email_outlined,
                      'support@expensetracker.com',
                    ),
                    _buildListItem(Icons.language, 'www.expensetracker.com'),
                  ],
                ),

                const SizedBox(height: 32),

                // Copyright
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '© 2025 Expense Tracker. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      color: AppTheme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTeal,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
