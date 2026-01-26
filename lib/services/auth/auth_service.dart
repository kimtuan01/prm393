import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../../models/user.dart';
import 'email_service.dart';
import '../data/wallet_service.dart';
import '../data/transaction_service.dart';
import '../firebase/sync_service.dart';
import '../firebase/firebase_user_repository.dart';

class AuthService extends ChangeNotifier {
  static const String _userBoxName = 'users';
  static const String _sessionBoxName = 'session';

  User? _currentUser;
  String? _currentOTP;
  String? _pendingEmail; // Email waiting for OTP verification
  String? _resetPasswordEmail; // Email for password reset
  String? _resetOTP; // OTP for password reset
  final SyncService _syncService = SyncService();
  final FirebaseUserRepository _firebaseRepo = FirebaseUserRepository();

  // Admin credentials (hardcoded)
  static const String ADMIN_EMAIL = 'admin@fintracker.com';
  static const String ADMIN_PASSWORD = 'Admin@123'; // Mật khẩu admin

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.email == ADMIN_EMAIL;

  // Hash password using SHA256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate random user ID
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  // Generate 4-digit OTP
  String _generateOTP() {
    return (1000 + Random().nextInt(9000)).toString();
  }

  // Register User (Step 1: Create account, send OTP)
  Future<Map<String, dynamic>> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      final box = await Hive.openBox<User>(_userBoxName);

      // Check if email already exists
      if (box.values.any((user) => user.email == email)) {
        return {'success': false, 'message': 'Email đã tồn tại'};
      }

      // Generate OTP
      _currentOTP = _generateOTP();
      _pendingEmail = email;

      // Send OTP via email
      bool emailSent = await EmailService.sendOTP(email, _currentOTP!);

      if (!emailSent) {
        return {
          'success': false,
          'message': 'Không thể gửi email. Vui lòng thử lại.',
        };
      }

      // Store user data temporarily (not saved until OTP verified)
      final tempUser = User(
        id: _generateUserId(),
        email: email,
        firstName: firstName,
        lastName: lastName,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
        isVerified: false,
      );

      // Save temporarily (will be saved permanently after OTP verification)
      await box.put(email, tempUser);

      notifyListeners();

      return {'success': true, 'message': 'OTP đã được gửi đến $email'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String otp) async {
    try {
      if (_currentOTP == null || _pendingEmail == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy OTP. Vui lòng đăng ký lại.',
        };
      }

      if (otp != _currentOTP) {
        return {'success': false, 'message': 'OTP không đúng'};
      }

      // OTP correct - mark user as verified
      final box = await Hive.openBox<User>(_userBoxName);
      final user = box.get(_pendingEmail);

      if (user != null) {
        user.isVerified = true;
        await user.save();
        _currentUser = user;
        await _saveSession(user);

        // 🌐 CLOUD SYNC: Save user profile to Firebase
        _firebaseRepo.saveUser(user).catchError((e) {
          print('⚠️ [Auth] Cloud user sync failed: $e');
        });

        // Seed default wallets for this user (idempotent)
        try {
          if (_currentUser!.id != 'admin') {
            final ws = WalletService();
            await ws.seedDefaultWallets(_currentUser!.id);
          }
        } catch (e) {
          debugPrint('Wallet seeding failed for user ${user.id}: $e');
        }
      }

      // Clear OTP
      _currentOTP = null;
      _pendingEmail = null;

      notifyListeners();

      return {'success': true, 'message': 'Xác thực thành công!'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Save User Preferences (from Favorites screen)
  Future<void> savePreferences(List<String> preferences) async {
    if (_currentUser != null) {
      _currentUser!.preferences = preferences;
      await _currentUser!.save();
      notifyListeners();
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Check if admin login
      if (email == ADMIN_EMAIL) {
        if (password == ADMIN_PASSWORD) {
          // Create admin user object
          _currentUser = User(
            id: 'admin',
            email: ADMIN_EMAIL,
            firstName: 'Admin',
            lastName: 'System',
            passwordHash: _hashPassword(ADMIN_PASSWORD),
            createdAt: DateTime.now(),
            isVerified: true,
          );

          await _saveSession(_currentUser!);
          notifyListeners();

          return {
            'success': true,
            'message': 'Đăng nhập Admin thành công!',
            'user': _currentUser,
            'isAdmin': true,
          };
        } else {
          return {'success': false, 'message': 'Mật khẩu Admin không đúng'};
        }
      }

      // Normal user login
      final box = await Hive.openBox<User>(_userBoxName);
      User? user = box.get(email);

      // 🌐 If user not found locally, try to load from Firebase
      if (user == null) {
        debugPrint('🔍 User not found locally, checking Firebase...');
        debugPrint('🔍 Email to search: $email');
        try {
          final firebaseUser = await _firebaseRepo.getUserByEmail(email);
          if (firebaseUser != null) {
            debugPrint('✅ User found in Firebase, downloading to local...');
            debugPrint('✅ Firebase user ID: ${firebaseUser.id}');
            debugPrint('✅ Firebase user email: ${firebaseUser.email}');
            // Save to local Hive
            await box.put(email, firebaseUser);
            user = firebaseUser;
            debugPrint('✅ User saved to local Hive');
          } else {
            debugPrint('❌ Firebase returned NULL for email: $email');
            debugPrint('❌ Possible reasons:');
            debugPrint('   1. Email not in Firebase');
            debugPrint('   2. Firebase rules blocking access');
            debugPrint('   3. Firebase not initialized');
            return {
              'success': false,
              'message':
                  'Email không tồn tại hoặc Firebase không kết nối được. Kiểm tra kết nối Internet.',
            };
          }
        } catch (e) {
          debugPrint('⚠️ Failed to check Firebase: $e');
          debugPrint('⚠️ Error type: ${e.runtimeType}');
          return {
            'success': false,
            'message': 'Lỗi kết nối Firebase: ${e.toString()}',
          };
        }
      }

      if (!user.isVerified) {
        return {'success': false, 'message': 'Tài khoản chưa được xác thực'};
      }

      String hashedPassword = _hashPassword(password);
      if (user.passwordHash != hashedPassword) {
        return {'success': false, 'message': 'Mật khẩu không đúng'};
      }

      // Login successful
      user.lastLoginAt = DateTime.now();
      await user.save();
      _currentUser = user;
      await _saveSession(user);

      // 🌐 UPLOAD USER TO FIREBASE: Ensure user exists in Firebase for cross-device login
      try {
        debugPrint('📤 Uploading user to Firebase...');
        await _firebaseRepo.saveUser(user);
        debugPrint('✅ User uploaded to Firebase successfully');
      } catch (e) {
        debugPrint('⚠️ Failed to upload user to Firebase: $e');
        // Continue anyway - not critical for login
      }

      // Seed default wallets for this user (idempotent)
      try {
        if (_currentUser!.id != 'admin') {
          final ws = WalletService();
          await ws.seedDefaultWallets(_currentUser!.id);
        }
      } catch (e) {
        debugPrint('Wallet seeding failed for user ${user.id}: $e');
      }

      // 🌐 CLOUD SYNC: Download user's data from cloud on login
      try {
        await _syncService.fullSync(user.id);
        _syncService.startAutoSync(user.id);
        debugPrint('✅ Cloud sync completed for user ${user.id}');

        // After sync, recompute wallet balances from authoritative transactions
        try {
          final txService = TransactionService();
          final walletService = WalletService();
          final txs = await txService.getTransactionsByUserId(user.id);
          await walletService.recomputeAllBalances(txs);
          debugPrint('✅ Recomputed wallet balances after login for ${user.id}');

          // Repair orphan transactions (no walletId) by assigning per-user defaults
          final orphanCount = txs
              .where((t) => t.walletId == null || t.walletId!.isEmpty)
              .length;
          if (orphanCount > 0) {
            debugPrint(
              '🔧 Found $orphanCount orphan transactions after login, assigning defaults...',
            );
            try {
              await walletService.assignDefaultWalletToTransactions(txService);
              debugPrint(
                '✅ Assigned default wallets to orphan transactions after login',
              );
            } catch (e) {
              debugPrint('⚠️ Failed to assign default wallets after login: $e');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Failed to recompute balances after login: $e');
        }
      } catch (e) {
        debugPrint('⚠️ Cloud sync failed (offline mode): $e');
      }

      notifyListeners();

      return {
        'success': true,
        'message': 'Đăng nhập thành công!',
        'user': user,
        'isAdmin': false,
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Save session
  Future<void> _saveSession(User user) async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    await sessionBox.put('current_user_email', user.email);
    await sessionBox.put('login_time', DateTime.now().toIso8601String());
  }

  // Check and restore session
  Future<void> checkSession() async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    final userEmail = sessionBox.get('current_user_email');

    if (userEmail != null) {
      final userBox = await Hive.openBox<User>(_userBoxName);
      _currentUser = userBox.get(userEmail);
      notifyListeners();

      // Seed default wallets in background (do not block startup)
      if (_currentUser != null && _currentUser!.id != 'admin') {
        Future.microtask(() async {
          try {
            final ws = WalletService();
            await ws.seedDefaultWallets(_currentUser!.id);
            debugPrint(
              'Wallet seeding on session restore complete for ${_currentUser!.id}',
            );
            // Recompute balances in background to ensure UI shows canonical values
            try {
              final txService = TransactionService();
              final txs = await txService.getTransactionsByUserId(
                _currentUser!.id,
              );
              await ws.recomputeAllBalances(txs);
              debugPrint('✅ Recomputed wallet balances on session restore');

              // Repair orphan transactions (no walletId) by assigning per-user default wallets
              final orphanCount = txs
                  .where((t) => t.walletId == null || t.walletId!.isEmpty)
                  .length;
              if (orphanCount > 0) {
                debugPrint(
                  '🔧 Found $orphanCount orphan transactions, assigning defaults...',
                );
                try {
                  await ws.assignDefaultWalletToTransactions(txService);
                  debugPrint(
                    '✅ Assigned default wallets to orphan transactions',
                  );
                } catch (e) {
                  debugPrint(
                    '⚠️ Failed to assign default wallets to transactions: $e',
                  );
                }
              }
            } catch (e) {
              debugPrint(
                '⚠️ Failed to recompute balances on session restore: $e',
              );
            }
          } catch (e) {
            debugPrint('Wallet seeding on session restore failed: $e');
          }
        });
      }
    }
  }

  // Logout
  Future<void> logout() async {
    // 🌐 CLOUD SYNC: Ensure pending changes are synced before logout
    try {
      if (_currentUser != null && _currentUser!.id != 'admin') {
        await _syncService.syncAllPendingTransactions();
        _syncService.stopAutoSync();
        debugPrint('✅ Sync completed before logout');
      }
    } catch (e) {
      debugPrint('⚠️ Error during logout sync: $e');
    }

    // 🧹 CRITICAL FIX: Clear session to prevent data leakage between users
    final sessionBox = await Hive.openBox(_sessionBoxName);
    await sessionBox.clear();

    _currentUser = null;
    notifyListeners();

    debugPrint('✅ Logout completed - session cleared');
    debugPrint(
      '⚠️ Note: Local data kept for offline access. Will be filtered by userId on next login.',
    );
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP() async {
    if (_pendingEmail == null) {
      return {'success': false, 'message': 'Không tìm thấy email'};
    }

    _currentOTP = _generateOTP();
    bool emailSent = await EmailService.sendOTP(_pendingEmail!, _currentOTP!);

    if (!emailSent) {
      return {'success': false, 'message': 'Không thể gửi email'};
    }

    return {'success': true, 'message': 'OTP mới đã được gửi'};
  }

  // ==================== PASSWORD RESET FLOW ====================

  // Step 1: Request Password Reset (send OTP to email)
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final box = await Hive.openBox<User>(_userBoxName);

      // Check if email exists
      final user = box.get(email);
      if (user == null) {
        return {'success': false, 'message': 'Email không tồn tại'};
      }

      if (!user.isVerified) {
        return {'success': false, 'message': 'Tài khoản chưa được xác thực'};
      }

      // Generate OTP
      _resetOTP = _generateOTP();
      _resetPasswordEmail = email;

      // Send OTP via email
      bool emailSent = await EmailService.sendOTP(email, _resetOTP!);

      if (!emailSent) {
        return {
          'success': false,
          'message': 'Không thể gửi email. Vui lòng thử lại.',
        };
      }

      notifyListeners();

      return {'success': true, 'message': 'Mã OTP đã được gửi đến $email'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Step 2: Verify Reset OTP
  Future<Map<String, dynamic>> verifyResetOTP(String otp) async {
    try {
      if (_resetOTP == null || _resetPasswordEmail == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy OTP. Vui lòng yêu cầu lại.',
        };
      }

      if (otp != _resetOTP) {
        return {'success': false, 'message': 'Mã OTP không đúng'};
      }

      // OTP verified - don't clear yet, need for password reset
      notifyListeners();

      return {'success': true, 'message': 'Xác thực thành công!'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Step 3: Reset Password
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    try {
      if (_resetPasswordEmail == null || _resetPasswordEmail != email) {
        return {
          'success': false,
          'message': 'Phiên làm việc không hợp lệ. Vui lòng thử lại.',
        };
      }

      final box = await Hive.openBox<User>(_userBoxName);
      final user = box.get(email);

      if (user == null) {
        return {'success': false, 'message': 'Người dùng không tồn tại'};
      }

      // Update password
      user.passwordHash = _hashPassword(newPassword);
      await user.save();

      // Clear reset data
      _resetOTP = null;
      _resetPasswordEmail = null;

      notifyListeners();

      return {'success': true, 'message': 'Đặt lại mật khẩu thành công!'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // Resend Reset OTP
  Future<Map<String, dynamic>> resendResetOTP() async {
    if (_resetPasswordEmail == null) {
      return {'success': false, 'message': 'Không tìm thấy email'};
    }

    _resetOTP = _generateOTP();
    bool emailSent = await EmailService.sendOTP(
      _resetPasswordEmail!,
      _resetOTP!,
    );

    if (!emailSent) {
      return {'success': false, 'message': 'Không thể gửi email'};
    }

    return {'success': true, 'message': 'OTP mới đã được gửi'};
  }

  // 🌐 SYNC ALL LOCAL USERS TO FIREBASE
  // Call this once on your device to upload all existing users to Firebase
  Future<Map<String, dynamic>> syncAllUsersToFirebase() async {
    try {
      final box = await Hive.openBox<User>(_userBoxName);
      final allUsers = box.values.toList();

      if (allUsers.isEmpty) {
        return {'success': false, 'message': 'Không có user nào để sync'};
      }

      int successCount = 0;
      int failCount = 0;

      for (var user in allUsers) {
        try {
          await _firebaseRepo.saveUser(user);
          debugPrint('✅ Synced user: ${user.email}');
          successCount++;
        } catch (e) {
          debugPrint('❌ Failed to sync user ${user.email}: $e');
          failCount++;
        }
      }

      return {
        'success': true,
        'message':
            'Đã sync $successCount users thành công, $failCount thất bại',
        'successCount': successCount,
        'failCount': failCount,
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }
}
