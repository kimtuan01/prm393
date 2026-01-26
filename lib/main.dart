import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/theme.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth/auth_service.dart';
import 'services/auth/user_provider.dart';
import 'services/core/app_settings_provider.dart';
import 'services/data/transaction_notifier.dart';

import 'models/user.dart';
import 'models/transaction.dart';
import 'models/category_group.dart';
import 'models/wallet.dart';
import 'services/data/wallet_service.dart';
import 'services/data/transaction_service.dart';
import 'services/data/notification_service.dart';
import 'utils/category_seed.dart';
import 'firebase_options.dart'; // file do flutterfire generate

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);

  // ================== HIVE (LUÔN KHỞI TẠO) ==================
  await Hive.initFlutter();

  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(CategoryGroupAdapter());
  Hive.registerAdapter(CategoryTypeAdapter());
  // Wallet adapters
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(WalletTypeAdapter());

  await Hive.openBox<User>('users');
  await Hive.openBox<CategoryGroup>('category_groups');
  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox('session');
  await Hive.openBox('preferences');

  // Seed system categories in background (idempotent) to avoid blocking UI.
  Future.microtask(() async {
    try {
      await CategorySeed.seedIfNeeded();
      debugPrint('✅ Category seeding complete');

      // Remove duplicate categories (if any from old data)
      await CategorySeed.deduplicateCategories();
      debugPrint('✅ Category deduplication complete');

      // Clean up invalid income categories
      final cleanedIncomeCount =
          await CategorySeed.cleanupInvalidIncomeCategories();
      if (cleanedIncomeCount > 0) {
        debugPrint('✅ Removed $cleanedIncomeCount invalid income categories');
      }

      // Clean up invalid expense categories
      final cleanedExpenseCount =
          await CategorySeed.cleanupInvalidExpenseCategories();
      if (cleanedExpenseCount > 0) {
        debugPrint('✅ Removed $cleanedExpenseCount invalid expense categories');
      }
    } catch (e) {
      debugPrint('Category seeding/cleanup failed: $e');
    }
  });

  // Initialize wallet storage and run migration in background.
  Future.microtask(() async {
    try {
      final walletService = WalletService();
      await walletService.init();
      final all = await walletService.getAll();
      debugPrint(
        '✅ Wallets initialized: ${all.length} wallets (user-scoped wallets are seeded on first login)',
      );

      try {
        final txService = TransactionService();
        await txService.init();
        await walletService.assignDefaultWalletToTransactions(txService);
        debugPrint('✅ Wallet migration complete');
      } catch (e) {
        debugPrint('Wallet migration failed: $e');
      }
    } catch (e) {
      debugPrint('Wallet seeding/init failed: $e');
    }
  });

  // ================== MOBILE ONLY ==================
  // if (!kIsWeb) {
  //   await dotenv.load(fileName: '.env');
  //
  //   try {
  //     await Firebase.initializeApp();
  //   } catch (e) {
  //     debugPrint('Firebase init skipped: $e');
  //   }
  // }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => TransactionNotifier()),
        ChangeNotifierProvider(create: (_) => NotificationService()..init()),
        ChangeNotifierProvider(
          create: (_) => UserProvider()..loadCurrentUser(),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FinTracker',
            locale: Locale(settings.language),
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
