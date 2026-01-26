import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart' show TransactionType;
import 'transaction_service.dart';
import '../firebase/firebase_wallet_repository.dart';

class WalletService {
  static const _boxName = 'wallets';
  final FirebaseWalletRepository _firebaseRepo = FirebaseWalletRepository();

  Future<void> init() async {
    // ensure box is open
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Wallet>(_boxName);
    }
  }

  Box<Wallet> get _box => Hive.box<Wallet>(_boxName);

  // Protected default wallet id prefixes (seeded per-user as 'wallet_cash_$userId' etc).
  bool _isProtectedDefaultWallet(Wallet wallet) {
    final id = wallet.id;
    const prefixes = [
      'wallet_cash',
      'wallet_bank',
      'wallet_ewallet',
      'wallet_saving',
      'wallet_investment',
    ];
    for (final p in prefixes) {
      if (id == p || id.startsWith('${p}_')) return true;
    }
    return false;
  }

  /// Get all wallets. If [userId] is provided, return only wallets owned by the user.
  Future<List<Wallet>> getAll({String? userId}) async {
    await init();
    final all = _box.values.toList();
    if (userId == null || userId.isEmpty) return all;
    return all.where((w) => w.userId == userId).toList();
  }

  Future<Wallet?> getById(String id) async {
    await init();
    return _box.get(id);
  }

  Future<List<Wallet>> getByUser(String userId) async {
    return getAll(userId: userId);
  }

  Future<void> add(Wallet wallet) async {
    await init();

    // Ensure wallet has an id (some callers may create a wallet without one)
    if (wallet.id.trim().isEmpty) {
      wallet.id = const Uuid().v4();
    }

    // Validate userId
    if (wallet.userId.trim().isEmpty) {
      throw ArgumentError('wallet.userId must be set');
    }
    final userId = wallet.userId.trim();

    // Normalize and validate name
    final name = wallet.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Wallet name cannot be empty');
    }

    // Fast-path: check only this user's wallets (avoid scanning whole box)
    final exists = _box.values
        .where((w) => w.userId == userId)
        .any((w) => w.name.trim().toLowerCase() == name.toLowerCase());
    if (exists) {
      throw ArgumentError(
        'A wallet with the name "$name" already exists for this user.',
      );
    }

    // If this wallet is marked default, unset existing defaults for the user
    if (wallet.isDefault) {
      final toUnset = _box.values
          .where((w) => w.userId == userId && w.id != wallet.id && w.isDefault)
          .toList();
      for (final w in toUnset) {
        w.isDefault = false;
        await w.save();
        // Yield briefly to keep UI responsive if many wallets are updated
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    wallet.name = name;
    // Small yield so progress indicator can render before disk IO
    await Future.delayed(const Duration(milliseconds: 1));

    // 🔥 HYBRID: Save locally first
    await _box.put(wallet.id, wallet);

    // 🌐 CLOUD SYNC: Upload to Firebase asynchronously
    _firebaseRepo.saveWallet(wallet).catchError((e) {
      print('⚠️ [Wallet] Cloud sync failed, will retry later: $e');
    });
  }

  Future<void> update(Wallet wallet, {bool force = false}) async {
    await init();

    // Basic validation
    if (wallet.id.trim().isEmpty) {
      throw ArgumentError('wallet.id must be set for update');
    }
    if (wallet.userId.trim().isEmpty) {
      throw ArgumentError('wallet.userId must be set');
    }
    final userId = wallet.userId.trim();

    // Ensure the wallet exists in the box
    final existing = _box.get(wallet.id);
    if (existing == null) {
      throw StateError(
        'Cannot update non-existing wallet with id "${wallet.id}". Use add() instead.',
      );
    }

    // Protect seeded default wallets from unintended renames/type changes unless forced
    if (_isProtectedDefaultWallet(existing) && !force) {
      if (existing.name.trim() != wallet.name.trim() ||
          existing.type != wallet.type) {
        throw StateError(
          'Cannot modify protected default wallet "${existing.name}" without force=true.',
        );
      }
    }

    // Normalize and validate name
    final name = wallet.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Wallet name cannot be empty');
    }

    // Fast-path: check only this user's wallets to avoid scanning everything
    final exists = _box.values
        .where((w) => w.userId == userId)
        .any(
          (w) =>
              w.id != wallet.id &&
              w.name.trim().toLowerCase() == name.toLowerCase(),
        );

    if (exists) {
      throw ArgumentError(
        'Another wallet with the name "$name" already exists for this user.',
      );
    }

    // If being set as default, unset other defaults for the user
    if (wallet.isDefault) {
      final toUnset = _box.values
          .where((w) => w.userId == userId && w.id != wallet.id && w.isDefault)
          .toList();
      for (final w in toUnset) {
        w.isDefault = false;
        await w.save();
        // Yield briefly in case multiple saves are required
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    wallet.name = name;
    // Yield slightly before final save to allow UI update
    await Future.delayed(const Duration(milliseconds: 1));
    // Use _box.put so detached instances (not previously opened from Hive) are persisted correctly

    // 🔥 HYBRID: Save locally first
    await _box.put(wallet.id, wallet);

    // 🌐 CLOUD SYNC: Upload to Firebase asynchronously
    _firebaseRepo.saveWallet(wallet).catchError((e) {
      print('⚠️ [Wallet] Cloud update failed: $e');
    });
  }

  /// Delete a wallet safely.
  /// If [txService] is provided, transactions referencing the deleted wallet will be
  /// reassigned to a replacement wallet (prefer default, otherwise first other wallet).
  /// If this is the last wallet for the user, deletion will be prevented unless [force] is true.
  Future<void> deleteWallet(
    String id, {
    TransactionService? txService,
    bool force = false,
  }) async {
    await init();
    final wallet = _box.get(id);
    if (wallet == null) return;

    // Prevent removing protected default wallets (seeded templates) unless forced
    if (_isProtectedDefaultWallet(wallet) && !force) {
      throw StateError(
        'Cannot delete protected default wallet "${wallet.name}". Use force=true to override.',
      );
    }

    final uid = wallet.userId;
    final userWallets = _box.values.where((w) => w.userId == uid).toList();

    // Prevent deleting the last wallet for a user unless forced
    if (userWallets.length <= 1 && !force) {
      throw StateError('Cannot delete the last wallet for user "$uid".');
    }

    // Find replacement wallet (prefer another default, otherwise first other wallet)
    Wallet? replacement;
    try {
      replacement = userWallets.firstWhere(
        (w) => w.userId == uid && w.id != id && w.isDefault,
      );
    } catch (_) {
      try {
        replacement = userWallets.firstWhere(
          (w) => w.userId == uid && w.id != id,
        );
      } catch (_) {
        replacement = null;
      }
    }

    // If transactions exist and no txService is provided, prevent deletion unless forced
    List<dynamic> txsToReassign = [];
    if (txService != null) {
      final allUserTx = await txService.getTransactionsByUserId(uid);
      txsToReassign = allUserTx.where((t) => t.walletId == id).toList();
    } else {
      // Best-effort check: ensure there are no transactions pointing to this wallet
      final txServiceCheck = TransactionService();
      final allUserTx = await txServiceCheck.getTransactionsByUserId(uid);
      final hasTx = allUserTx.any((t) => t.walletId == id);
      if (hasTx && !force) {
        throw StateError(
          'Wallet has transactions; provide a TransactionService to reassign them or set force=true.',
        );
      }
    }

    // If deleting a default wallet, make replacement the new default (if exists)
    if (wallet.isDefault && replacement != null) {
      await setDefaultWallet(replacement.id);
    }

    // Reassign transactions to replacement if possible
    if (txsToReassign.isNotEmpty) {
      if (replacement == null && !force) {
        throw StateError(
          'No replacement wallet available to reassign transactions. Use force=true to proceed.',
        );
      }
      for (final tx in txsToReassign) {
        tx.walletId = replacement?.id ?? '';
        await txService!.updateTransaction(tx);
      }
    }

    // Finally delete the wallet
    await _box.delete(id);

    // 🌐 CLOUD SYNC: Delete from Firebase
    _firebaseRepo.deleteWallet(uid, id).catchError((e) {
      print('⚠️ [Wallet] Cloud delete failed: $e');
    });

    // Recompute balances for user's wallets if we handled transactions
    if (txService != null) {
      final updated = await txService.getTransactionsByUserId(uid);
      await recomputeAllBalances(updated);
    }
  }

  /// Seed default wallets for a specific user if that user has no wallets yet.
  Future<void> seedDefaultWallets(String userId) async {
    await init();

    // Guard against empty userId - do not seed global/system defaults without a user
    if (userId.trim().isEmpty) {
      print('⚠️ seedDefaultWallets called with empty userId, aborting');
      return;
    }

    final existing = await getByUser(userId);

    // If the user already has any wallets, do NOT seed defaults (business rule)
    if (existing.isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    // When seeding for a user with no wallets, make the cash wallet the default
    final defaults = <Wallet>[
      Wallet(
        id: 'wallet_cash_$userId',
        userId: userId,
        name: 'Tiền mặt',
        type: WalletType.cash,
        balance: 0,
        isDefault: true,
        createdAt: now,
      ),
      Wallet(
        id: 'wallet_bank_$userId',
        userId: userId,
        name: 'Tiền gửi ngân hàng',
        type: WalletType.bank,
        balance: 0,
        createdAt: now,
      ),
      Wallet(
        id: 'wallet_ewallet_$userId',
        userId: userId,
        name: 'Ví điện tử',
        type: WalletType.ewallet,
        balance: 0,
        createdAt: now,
      ),
      Wallet(
        id: 'wallet_saving_$userId',
        userId: userId,
        name: 'Tiết kiệm',
        type: WalletType.saving,
        balance: 0,
        createdAt: now,
      ),
      Wallet(
        id: 'wallet_investment_$userId',
        userId: userId,
        name: 'Đầu tư',
        type: WalletType.investment,
        balance: 0,
        createdAt: now,
      ),
    ];

    for (final w in defaults) {
      if (!_box.containsKey(w.id)) {
        await _box.put(w.id, w);
      }
    }
  }

  Future<Wallet?> getByName(String name, {String? userId}) async {
    await init();
    final needle = name.trim().toLowerCase();

    if (userId != null && userId.isNotEmpty) {
      for (final w in _box.values.where((w) => w.userId == userId)) {
        if (w.name.trim().toLowerCase() == needle) return w;
      }
      return null;
    }

    // Fallback: scan all wallets
    for (final w in _box.values) {
      if (w.name.trim().toLowerCase() == needle) return w;
    }
    return null;
  }

  /// Get the default wallet, preferably for the given [userId] if provided.
  Future<Wallet?> getDefaultWallet({String? userId}) async {
    await init();
    if (userId != null && userId.isNotEmpty) {
      final userWallets = _box.values.where((w) => w.userId == userId).toList();

      // 1) prefer user-set default
      try {
        return userWallets.firstWhere((w) => w.isDefault);
      } catch (_) {}

      // 2) prefer canonical cash id for user
      final cashWallet = _box.get('wallet_cash_$userId');
      if (cashWallet != null) return cashWallet;

      // 3) fallback to any user's wallet
      if (userWallets.isNotEmpty) return userWallets.first;
    }

    if (_box.isEmpty) return null;

    // fallback to any global cash id
    final cash = _box.get('wallet_cash');
    if (cash != null) return cash;
    return _box.values.first;
  }

  Future<void> updateBalance(String walletId, double delta) async {
    await init();
    final wallet = _box.get(walletId);
    if (wallet == null) return;
    wallet.balance = wallet.balance + delta;
    await wallet.save();
  }

  Future<void> applyTransaction(dynamic transaction) async {
    // transaction is model.Transaction from models/transaction.dart
    await init();
    final String? wid = transaction.walletId;
    if (wid == null || wid.isEmpty) {
      throw ArgumentError('Cannot apply transaction without a walletId');
    }

    final wallet = _box.get(wid);
    if (wallet == null) {
      throw StateError(
        'Wallet with id "$wid" not found when applying transaction',
      );
    }

    double delta = 0.0;

    if (transaction.type == TransactionType.income) {
      delta = transaction.amount;
    } else if (transaction.type == TransactionType.expense) {
      delta = -transaction.amount;
    } else {
      // Loan type: determine sign by category semantics.
      final cat = (transaction.category ?? '').trim().toLowerCase();

      // Categories treated as incoming (you receive money): "vay", "thu hồi"/"thu hồi nợ"
      final incoming = ['vay', 'thu hồi', 'thu'];
      // Categories treated as outgoing (you give money / lend / repay): "cho vay", "nợ"
      final outgoing = ['cho vay', 'cho vay ', 'nợ', 'no'];

      bool matched = false;
      for (final k in incoming) {
        if (cat.contains(k)) {
          delta = transaction.amount;
          matched = true;
          break;
        }
      }
      if (!matched) {
        for (final k in outgoing) {
          if (cat.contains(k)) {
            delta = -transaction.amount;
            matched = true;
            break;
          }
        }
      }

      // Default: treat loan as neutral (no wallet change) if unsure
      if (!matched) delta = 0.0;
    }

    await updateBalance(wallet.id, delta);
  }

  Future<void> revertTransaction(dynamic transaction) async {
    await init();
    final String? wid = transaction.walletId;
    if (wid == null || wid.isEmpty) return;
    final wallet = _box.get(wid);
    if (wallet == null) return;

    double delta = 0.0;

    if (transaction.type == TransactionType.income) {
      delta = -transaction.amount;
    } else if (transaction.type == TransactionType.expense) {
      delta = transaction.amount;
    } else {
      // Reverse loan semantics same as applyTransaction but inverted
      final cat = (transaction.category ?? '').trim().toLowerCase();
      final incoming = ['vay', 'thu hồi', 'thu'];
      final outgoing = ['cho vay', 'cho vay ', 'nợ', 'no'];

      bool matched = false;
      for (final k in incoming) {
        if (cat.contains(k)) {
          delta = -transaction.amount;
          matched = true;
          break;
        }
      }
      if (!matched) {
        for (final k in outgoing) {
          if (cat.contains(k)) {
            delta = transaction.amount;
            matched = true;
            break;
          }
        }
      }

      if (!matched) delta = 0.0;
    }

    await updateBalance(wallet.id, delta);
  }

  Future<void> recomputeAllBalances(List<dynamic> transactions) async {
    await init();

    // Sort transactions chronologically
    final txs = List.from(transactions);
    txs.sort((a, b) => a.date.compareTo(b.date));

    // Compute balances in-memory first to minimize Hive writes and reduce blocking.
    final Map<String, double> balances = {};

    for (var i = 0; i < txs.length; i++) {
      final tx = txs[i];
      if (tx.walletId == null || tx.walletId!.isEmpty) continue;
      balances[tx.walletId!] = balances[tx.walletId!] ?? 0.0;

      if (tx.type == TransactionType.income) {
        balances[tx.walletId!] = balances[tx.walletId!]! + tx.amount;
      } else if (tx.type == TransactionType.expense) {
        balances[tx.walletId!] = balances[tx.walletId!]! - tx.amount;
      } else if (tx.type == TransactionType.loan) {
        final cat = (tx.category ?? '').trim().toLowerCase();
        final incoming = ['vay', 'thu hồi', 'thu'];
        final outgoing = ['cho vay', 'cho vay ', 'nợ', 'no'];

        bool matched = false;
        for (final k in incoming) {
          if (cat.contains(k)) {
            balances[tx.walletId!] = balances[tx.walletId!]! + tx.amount;
            matched = true;
            break;
          }
        }
        if (!matched) {
          for (final k in outgoing) {
            if (cat.contains(k)) {
              balances[tx.walletId!] = balances[tx.walletId!]! - tx.amount;
              matched = true;
              break;
            }
          }
        }
        // If not matched, treat as neutral (no change)
      }

      // Yield periodically to keep UI responsive when processing many transactions
      if (i % 500 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Apply computed balances with a single write per wallet
    for (final w in _box.values) {
      final newBal = balances[w.id] ?? 0.0;
      if (w.balance != newBal) {
        w.balance = newBal;
        await w.save();
      }
    }
  }

  /// Assign default wallet to transactions that don't have one and recompute balances
  Future<void> assignDefaultWalletToTransactions(
    TransactionService txService,
  ) async {
    await init();
    final all = await txService.getAllTransactionsAdmin();
    if (all.isEmpty) return;

    // assign per-user default wallet (cache def wallets and batch updates)
    final Map<String, Wallet> cache = {};
    final List<dynamic> toUpdate = [];

    for (var i = 0; i < all.length; i++) {
      final tx = all[i];
      if (tx.walletId == null || tx.walletId!.isEmpty) {
        final uid = tx.userId;
        final userKey = uid.isNotEmpty ? uid : '';
        if (!cache.containsKey(userKey)) {
          final def = await getDefaultWallet(
            userId: uid.isNotEmpty ? uid : null,
          );
          if (def != null) cache[userKey] = def;
        }
        final defWallet = cache[userKey];
        if (defWallet != null) {
          tx.walletId = defWallet.id;
          toUpdate.add(tx);
        }
      }

      // Yield periodically to avoid long-running synchronous loops
      if (i % 200 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    // Perform updates in batches, yielding between batches
    for (var i = 0; i < toUpdate.length; i++) {
      await txService.updateTransaction(toUpdate[i]);
      if (i % 200 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    final updated = await txService.getAllTransactionsAdmin();
    await recomputeAllBalances(updated);
  }

  // helper to create a new wallet with generated id
  Wallet createNew({
    required String name,
    required WalletType type,
    required String userId,
    double balance = 0,
    bool isDefault = false,
  }) {
    final id = const Uuid().v4();
    return Wallet(
      id: id,
      userId: userId,
      name: name,
      type: type,
      balance: balance,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
  }

  /// Set the provided wallet as the default for its user, unsetting any others.
  Future<void> setDefaultWallet(String id) async {
    await init();
    final wallet = _box.get(id);
    if (wallet == null) return;
    final uid = wallet.userId;

    for (final w in _box.values.where(
      (w) => w.userId == uid && w.id != id && w.isDefault,
    )) {
      w.isDefault = false;
      await w.save();
    }

    if (!wallet.isDefault) {
      wallet.isDefault = true;
      await wallet.save();
    }
  }
}
