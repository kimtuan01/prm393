import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import '../../../config/theme.dart';
import '../../../models/user.dart';
import '../../../services/core/app_localization.dart';
import '../../../services/core/app_settings_provider.dart';
import '../../../services/auth/user_provider.dart';
import '../../../utils/notification_helper.dart';
import '../../auth/login_screen.dart';

// ============================================================================
// ACCOUNT MANAGEMENT SCREEN - Change password, delete account
// ============================================================================

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  User? currentUser;

  // ========================================================================
  // LIFECYCLE
  // ========================================================================

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userBox = await Hive.openBox<User>('users');
    final users = userBox.values.toList();

    if (users.isNotEmpty) {
      setState(() {
        currentUser = users.first;
      });
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ========================================================================
  // BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settings, _) {
        t(String key) => AppStrings.t(key, language: settings.language);

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryTeal,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              t('account_management'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildUserHeader(t),
                const SizedBox(height: 32),
                Container(
                  color: AppTheme.cardColor,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: t('change_password'),
                        onTap: () => _showChangePasswordDialog(t),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.delete_outline,
                        title: t('delete_account'),
                        onTap: () => _showDeleteAccountDialog(t),
                        textColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(t),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t('logout'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // UI COMPONENTS
  // ========================================================================

  Widget _buildUserHeader(Function(String) t) {
    final userName = currentUser?.fullName ?? 'User';
    final userEmail = currentUser?.email ?? 'email@example.com';
    final avatarPath = currentUser?.avatarPath;

    // Check avatar file safely
    bool hasValidAvatar = false;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        hasValidAvatar = File(avatarPath).existsSync();
      } catch (e) {
        hasValidAvatar = false;
      }
    }

    return Column(
      children: [
        // Avatar with click to upload
        GestureDetector(
          onTap: _showAvatarOptions,
          child: Stack(
            key: ValueKey(avatarPath ?? 'default_${currentUser?.id}'),
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: hasValidAvatar
                    ? ClipOval(
                        child: Image.file(
                          File(avatarPath!),
                          key: ValueKey(avatarPath),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      )
                    : Center(
                        child: Text(
                          currentUser?.firstName.isNotEmpty == true
                              ? currentUser!.firstName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Username
        Text(
          userName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 4),

        // Email
        Text(
          userEmail,
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),

        const SizedBox(height: 8),

        // Verified Badge
        if (currentUser?.isVerified == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  t('verified'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMenuItem({
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: Colors.grey[200],
    );
  }

  // ========================================================================
  // CHANGE PASSWORD
  // ========================================================================

  void _showChangePasswordDialog(Function(String) t) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t('change_password')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Old Password
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: t('current_password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureOld = !obscureOld);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: t('new_password'),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureNew = !obscureNew);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: t('confirm_new_password'),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  AppNotification.showError(context, t('password_mismatch'));
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  AppNotification.showError(context, t('password_too_short'));
                  return;
                }

                final success = await _changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                  t,
                );

                if (success && context.mounted) {
                  Navigator.pop(context);
                  AppNotification.showSuccess(
                    context,
                    t('password_changed_success'),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
              ),
              child: Text(t('confirm')),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _changePassword(
    String oldPassword,
    String newPassword,
    Function(String) t,
  ) async {
    try {
      if (currentUser == null) return false;

      // Verify old password
      final oldPasswordHash = _hashPassword(oldPassword);
      if (currentUser!.passwordHash != oldPasswordHash) {
        if (mounted) {
          AppNotification.showError(context, t('current_password_incorrect'));
        }
        return false;
      }

      // Update password
      final newPasswordHash = _hashPassword(newPassword);
      currentUser!.passwordHash = newPasswordHash;
      await currentUser!.save();
      setState(() {});

      return true;
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, '${t('error')}: $e');
      }
      return false;
    }
  }

  // ========================================================================
  // DELETE ACCOUNT
  // ========================================================================
  // AVATAR UPLOAD
  // ========================================================================

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thay đổi ảnh đại diện',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primaryTeal),
                ),
                title: const Text('Chụp ảnh'),
                subtitle: const Text('Dùng camera của điện thoại'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarFromCamera();
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: AppTheme.primaryTeal),
                ),
                title: const Text('Chọn từ thư viện'),
                subtitle: const Text('Chọn ảnh từ thư viện điện thoại'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarFromGallery();
                },
              ),
              const SizedBox(height: 10),
              if (currentUser?.avatarPath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha((0.1 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Xóa ảnh đại diện'),
                  subtitle: const Text('Quay lại ảnh chữ cái'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatarFromCamera() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (mounted) {
          AppNotification.showError(
            context,
            'Ứng dụng cần quyền truy cập camera',
          );
        }
        return;
      }

      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _saveAvatarPath(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Lỗi chụp ảnh: $e');
      }
    }
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      // Request photos permission
      final photosStatus = await Permission.photos.request();
      if (!photosStatus.isGranted) {
        if (mounted) {
          AppNotification.showError(
            context,
            'Ứng dụng cần quyền truy cập thư viện ảnh',
          );
        }
        return;
      }

      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _saveAvatarPath(pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Lỗi chọn ảnh: $e');
      }
    }
  }

  Future<void> _saveAvatarPath(String imagePath) async {
    try {
      // Get provider reference before async operation
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.updateAvatar(imagePath);

      if (mounted) {
        // Force rebuild immediately
        setState(() {
          currentUser = userProvider.currentUser;
        });

        AppNotification.showSuccess(
          context,
          'Cập nhật ảnh đại diện thành công',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Lỗi lưu ảnh: $e');
      }
    }
  }

  Future<void> _deleteAvatar() async {
    try {
      // Get provider reference before async operation
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.deleteAvatar();

      if (mounted) {
        // Force rebuild immediately
        setState(() {
          currentUser = userProvider.currentUser;
        });

        AppNotification.showSuccess(context, 'Đã xóa ảnh đại diện');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Lỗi xóa ảnh: $e');
      }
    }
  }

  // ========================================================================
  // DELETE ACCOUNT
  // ========================================================================

  void _showDeleteAccountDialog(Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_account')),
        content: Text(t('confirm_delete_account')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteAccount(t);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('delete_account')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(Function(String) t) async {
    try {
      final userBox = await Hive.openBox<User>('users');

      if (currentUser != null) {
        // Delete user from Hive
        await userBox.delete(currentUser!.id);

        // Delete all user transactions
        try {
          final transactionBox = await Hive.openBox('transactions');
          final userTransactions = transactionBox.values
              .where((t) => t.userId == currentUser!.id)
              .toList();

          for (var transaction in userTransactions) {
            await transactionBox.delete(transaction.key);
          }
        } catch (e) {
          print('Error deleting transactions: $e');
        }

        // Clear session
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        final sessionBox = await Hive.openBox('session');
        await sessionBox.clear();
      }

      if (mounted) {
        AppNotification.showSuccess(context, t('account_deleted_success'));
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, '${t('delete_account_error')}: $e');
      }
    }
  }

  // ========================================================================
  // LOGOUT
  // ========================================================================

  void _showLogoutDialog(Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('logout')),
        content: Text(t('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(t('logout'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
