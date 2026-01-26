// ============================================================================
// APP LOCALIZATION - Vietnamese & English Translations
// ============================================================================

class AppStrings {
  static const Map<String, Map<String, String>> translations = {
    // ========== VIETNAMESE ==========
    'vi': {
      // Common
      'app_name': 'FinTrack',
      'hello': 'Xin chào',
      'ok': 'OK',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'delete': 'Xóa',
      'edit': 'Chỉnh sửa',
      'add': 'Thêm',
      'close': 'Đóng',
      'back': 'Quay lại',
      'chat': 'Chat',
      'confirm': 'Xác nhận',
      'error': 'Lỗi',

      // Home Screen
      'hello_greeting': 'Xin chào,',
      'balance': 'Số dư ví',
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'statistics': 'Thống kê',
      'year': 'Năm',
      'recent_transactions': 'Giao dịch gần đây',
      'no_transactions': 'Chưa có giao dịch',
      'add_transaction_hint': 'Nhấn nút + để thêm giao dịch',

      // Settings
      'settings': 'Cài đặt',
      'language': 'Ngôn ngữ',
      'currency': 'Đơn vị tiền tệ',
      'language_changed': 'Ngôn ngữ đã được thay đổi',
      'currency_changed': 'Đơn vị tiền tệ đã được thay đổi',

      // Profile
      'account': 'Tài khoản',
      'logout': 'Đăng xuất',
      'confirm_logout': 'Bạn có chắc muốn đăng xuất?',
      'free_account': 'TÀI KHOẢN MIỄN PHÍ',
      'my_wallets': 'Ví của tôi',
      'category_groups': 'Nhóm danh mục',
      'recurring_transactions': 'Giao dịch định kỳ',
      'tools': 'Công cụ',
      'explore_fintracker': 'Khám phá FinTracker',
      'help': 'Hỗ trợ',
      'coming_soon': 'Sắp ra mắt',
      'feature_under_development': 'Tính năng đang được phát triển.',
      'need_support': 'Cần hỗ trợ?',
      'support_info':
          'Email: support@fintracker.com\nHotline: 1900-xxxx\nWebsite: www.fintracker.com',
      'wallet_management_feature': 'Tính năng quản lý ví sắp ra mắt',

      // About Screen
      'features': 'Tính năng',
      'track_expenses': 'Theo dõi chi tiêu',
      'manage_transactions': 'Quản lý giao dịch',
      'categorize_spending': 'Phân loại chi tiêu',
      'view_reports': 'Xem báo cáo',
      'ocr_receipts': 'Quét hóa đơn OCR',
      'about': 'Về chúng tôi',
      'app_description':
          'Expense Tracker là ứng dụng quản lý tài chính cá nhân giúp bạn theo dõi thu chi, lập ngân sách và phân tích chi tiêu một cách dễ dàng.',
      'contact': 'Liên hệ',

      // Account Management
      'account_management': 'Quản lý tài khoản',
      'change_password': 'Thay đổi mật khẩu',
      'delete_account': 'Xóa tài khoản',
      'verified': 'Đã xác thực',
      'current_password': 'Mật khẩu hiện tại',
      'new_password': 'Mật khẩu mới',
      'confirm_new_password': 'Xác nhận mật khẩu mới',
      'password_mismatch': 'Mật khẩu mới không khớp!',
      'password_too_short': 'Mật khẩu phải ít nhất 6 ký tự!',
      'password_changed_success': 'Đổi mật khẩu thành công!',
      'current_password_incorrect': 'Mật khẩu hiện tại không đúng!',
      'confirm_delete_account':
          'Bạn có chắc chắn muốn xóa tài khoản?\n\nToàn bộ dữ liệu của bạn sẽ bị xóa vĩnh viễn và không thể khôi phục.',
      'account_deleted_success': 'Tài khoản đã được xóa thành công',
      'delete_account_error': 'Lỗi khi xóa tài khoản',

      // Currencies
      'vnd': 'VND (₫)',
      'usd': 'USD (\$)',
      'eur': 'EUR (€)',
      'jpy': 'JPY (¥)',
    },

    // ========== ENGLISH ==========
    'en': {
      // Common
      'app_name': 'FinTrack',
      'hello': 'Hello',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'back': 'Back',
      'chat': 'Chat',
      'confirm': 'Confirm',
      'error': 'Error',

      // Home Screen
      'hello_greeting': 'Hello',
      'balance': 'Balance',
      'income': 'Income',
      'expense': 'Expense',
      'statistics': 'Statistics',
      'year': 'Year',
      'recent_transactions': 'Recent Transactions',
      'no_transactions': 'No transactions yet',
      'add_transaction_hint': 'Tap + button to add a transaction',

      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'currency': 'Currency',
      'language_changed': 'Language has been changed',
      'currency_changed': 'Currency has been changed',

      // Profile
      'account': 'Account',
      'logout': 'Logout',
      'confirm_logout': 'Are you sure you want to logout?',
      'free_account': 'FREE ACCOUNT',
      'my_wallets': 'My Wallets',
      'category_groups': 'Category Groups',
      'recurring_transactions': 'Recurring Transactions',
      'tools': 'Tools',
      'explore_fintracker': 'Explore FinTracker',
      'help': 'Help',
      'coming_soon': 'Coming Soon',
      'feature_under_development': 'Feature is under development.',
      'need_support': 'Need support?',
      'support_info':
          'Email: support@fintracker.com\nHotline: 1900-xxxx\nWebsite: www.fintracker.com',
      'wallet_management_feature': 'Wallet management feature coming soon',

      // About Screen
      'features': 'Features',
      'track_expenses': 'Track Expenses',
      'manage_transactions': 'Manage Transactions',
      'categorize_spending': 'Categorize Spending',
      'view_reports': 'View Reports',
      'ocr_receipts': 'OCR Receipt Scanning',
      'about': 'About',
      'app_description':
          'Expense Tracker is a personal finance management app that helps you track income and expenses, create budgets, and analyze spending easily.',
      'contact': 'Contact',

      // Account Management
      'account_management': 'Account Management',
      'change_password': 'Change Password',
      'delete_account': 'Delete Account',
      'verified': 'Verified',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'confirm_new_password': 'Confirm New Password',
      'password_mismatch': 'New passwords do not match!',
      'password_too_short': 'Password must be at least 6 characters!',
      'password_changed_success': 'Password changed successfully!',
      'current_password_incorrect': 'Current password is incorrect!',
      'confirm_delete_account':
          'Are you sure you want to delete your account?\n\nAll your data will be permanently deleted and cannot be recovered.',
      'account_deleted_success': 'Account deleted successfully',
      'delete_account_error': 'Error deleting account',

      // Currencies
      'vnd': 'VND (₫)',
      'usd': 'USD (\$)',
      'eur': 'EUR (€)',
      'jpy': 'JPY (¥)',
    },
  };

  /// Get translated string
  static String t(String key, {String language = 'vi'}) {
    return translations[language]?[key] ?? key;
  }

  /// Get currency symbol
  static String getCurrencySymbol(String currency) {
    const symbols = {'VND': '₫', 'USD': '\$', 'EUR': '€', 'JPY': '¥'};
    return symbols[currency] ?? '₫';
  }
}
