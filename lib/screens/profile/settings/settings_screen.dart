import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../services/core/app_localization.dart';
import '../../../services/core/app_settings_provider.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/firebase/sync_service.dart';
import '../../../utils/notification_helper.dart';
import 'category_group/category_group_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _languages = ['Tiếng Việt', 'English'];
  final List<String> _languageCodes = ['vi', 'en'];
  final List<String> _currencies = ['VND', 'USD', 'EUR', 'JPY'];
  final List<String> _dateFormats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'];
  final List<String> _weekDays = ['Monday', 'Sunday'];
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    t(String key) => AppStrings.t(key, language: settings.language);

    if (settings.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(t('settings')),
          backgroundColor: AppTheme.cardColor,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(t('settings')),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ===================== DISPLAY =====================
          _buildSectionHeader(t('display')),

          _buildSettingItem(
            title: t('language'),
            subtitle: _getLanguageName(settings.language),
            icon: Icons.language,
            onTap: () => _showLanguagePicker(context, settings),
          ),
          _buildDivider(),

          _buildSettingItem(
            title: t('currency'),
            subtitle: settings.currency,
            icon: Icons.attach_money,
            onTap: () => _showCurrencyPicker(context, settings),
          ),
          _buildDivider(),

          _buildSettingItem(
            title: t('date_format'),
            subtitle: settings.dateFormat,
            icon: Icons.calendar_today_outlined,
            onTap: () => _showDateFormatPicker(context, settings),
          ),
          _buildDivider(),

          _buildSettingItem(
            title: t('first_day_week'),
            subtitle: settings.firstDayOfWeek,
            icon: Icons.event_outlined,
            onTap: () => _showWeekDayPicker(context, settings),
          ),
          _buildDivider(),

          _buildSettingItem(
            title: t('first_day_month'),
            subtitle: settings.firstDayOfMonth,
            icon: Icons.date_range_outlined,
            onTap: () => _showDayOfMonthPicker(context, settings),
          ),
          _buildDivider(),

          _buildSettingItem(
            title: t('first_month_year'),
            subtitle: settings.firstMonthOfYear,
            icon: Icons.calendar_month_outlined,
            onTap: () => _showMonthOfYearPicker(context, settings),
          ),

          const SizedBox(height: 24),

          // ===================== CATEGORY =====================
          _buildSectionHeader(t('category')),

          _buildSettingItem(
            title: t('manage_categories'),
            subtitle: t('income_expense_categories'),
            icon: Icons.category_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryGroupScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // ===================== NOTIFICATION =====================
          _buildSectionHeader(t('notifications')),

          _buildSwitchItem(
            title: t('show_notifications'),
            subtitle: t('allow_notifications'),
            icon: Icons.notifications_outlined,
            value: settings.showNotifications,
            onChanged: (value) => settings.setShowNotifications(value),
          ),
          _buildDivider(),

          _buildSwitchItem(
            title: t('notification_sound'),
            subtitle: t('enable_sound'),
            icon: Icons.volume_up_outlined,
            value: settings.soundEnabled,
            onChanged: settings.showNotifications
                ? (v) => settings.setSoundEnabled(v)
                : null,
          ),
          _buildDivider(),

          _buildSwitchItem(
            title: t('vibration'),
            subtitle: t('enable_vibration'),
            icon: Icons.vibration,
            value: settings.vibrationEnabled,
            onChanged: settings.showNotifications
                ? (v) => settings.setVibrationEnabled(v)
                : null,
          ),

          const SizedBox(height: 24),

          // ===================== FIREBASE SYNC =====================
          _buildSectionHeader('Firebase / Cloud'),

          _buildSettingItem(
            title: 'Đồng bộ Users lên Firebase',
            subtitle: 'Upload thông tin tài khoản lên cloud',
            icon: Icons.person_add_outlined,
            onTap: _syncUsersToFirebase,
          ),
          _buildDivider(),

          _buildSettingItem(
            title: 'Upload TẤT CẢ Data lên Firebase',
            subtitle: 'Giao dịch, ví, ngân sách, danh mục',
            icon: Icons.cloud_upload_outlined,
            onTap: _uploadAllDataToFirebase,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ===================== UI HELPERS =====================

  Widget _buildSectionHeader(String title) {
    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.primaryTeal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      color: AppTheme.cardColor,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryTeal),
        title: Text(title),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(color: AppTheme.textSecondary))
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return Container(
      color: AppTheme.cardColor,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryTeal),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryTeal,
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 56);

  // ===================== PICKERS =====================

  void _showLanguagePicker(BuildContext context, AppSettingsProvider settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_languageCodes.length, (i) {
            return RadioListTile<String>(
              value: _languageCodes[i],
              groupValue: settings.language,
              title: Text(_languages[i]),
              onChanged: (v) async {
                if (v == null) return;
                await settings.setLanguage(v);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, AppSettingsProvider settings) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tiền tệ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _currencies.map((c) {
            return ListTile(
              title: Text(c),
              onTap: () async {
                await settings.setCurrency(c);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDateFormatPicker(BuildContext c, AppSettingsProvider s) =>
      _showComingSoon(c, 'Định dạng ngày');

  void _showWeekDayPicker(BuildContext c, AppSettingsProvider s) =>
      _showComingSoon(c, 'Ngày đầu tuần');

  void _showDayOfMonthPicker(BuildContext c, AppSettingsProvider s) =>
      _showComingSoon(c, 'Ngày đầu tháng');

  void _showMonthOfYearPicker(BuildContext c, AppSettingsProvider s) =>
      _showComingSoon(c, 'Tháng đầu năm');

  void _showComingSoon(BuildContext context, String feature) {
    AppNotification.showInfo(context, '$feature sẽ sớm được cập nhật');
  }

  String _getLanguageName(String code) {
    final index = _languageCodes.indexOf(code);
    return index >= 0 ? _languages[index] : _languages.first;
  }

  // ===================== FIREBASE SYNC =====================
  Future<void> _syncUsersToFirebase() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryTeal),
            const SizedBox(width: 20),
            const Expanded(child: Text('Đang đồng bộ users lên Firebase...')),
          ],
        ),
      ),
    );

    final authService = context.read<AuthService>();
    final result = await authService.syncAllUsersToFirebase();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        AppNotification.showSuccess(
          context,
          result['message'],
          duration: const Duration(seconds: 4),
        );
      } else {
        AppNotification.showError(context, result['message']);
      }
    }
  }

  // ===================== UPLOAD ALL DATA TO FIREBASE =====================
  Future<void> _uploadAllDataToFirebase() async {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      AppNotification.showError(context, 'Vui lòng đăng nhập trước');
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Data lên Firebase?'),
        content: const Text(
          'Sẽ upload TẤT CẢ giao dịch, ví, ngân sách, danh mục của bạn lên Firebase. '
          'Sau đó bạn có thể đăng nhập trên máy khác và tải data về.\n\n'
          'Quá trình có thể mất vài phút nếu có nhiều dữ liệu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
            child: const Text('UPLOAD'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.primaryTeal),
              const SizedBox(width: 20),
              const Expanded(
                child: Text(
                  'Đang upload data lên Firebase...\nVui lòng chờ...',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final syncService = SyncService();
    final result = await syncService.uploadAllLocalDataToFirebase(
      currentUser.id,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        AppNotification.showSuccess(
          context,
          result['message'],
          duration: const Duration(seconds: 5),
        );
      } else {
        AppNotification.showError(context, result['message']);
      }
    }
  }
}
