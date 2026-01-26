import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/wallet.dart';

// ============================================================================
// FIREBASE WALLET REPOSITORY - Cloud storage for wallets
// ============================================================================

class FirebaseWalletRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection path: users/{userId}/wallets/{walletId}
  CollectionReference<Map<String, dynamic>> _getUserWalletsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('wallets');
  }

  // ================= CREATE/UPDATE =================
  Future<void> saveWallet(Wallet wallet) async {
    try {
      final ref = _getUserWalletsRef(wallet.userId);
      await ref.doc(wallet.id).set(_walletToMap(wallet));
      print('✅ [Firebase] Saved wallet: ${wallet.id}');
    } catch (e) {
      print('❌ [Firebase] Error saving wallet: $e');
      rethrow;
    }
  }

  // ================= BATCH SAVE =================
  Future<void> saveWallets(String userId, List<Wallet> wallets) async {
    if (wallets.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final ref = _getUserWalletsRef(userId);

      for (var wallet in wallets) {
        batch.set(ref.doc(wallet.id), _walletToMap(wallet));
      }

      await batch.commit();
      print('✅ [Firebase] Saved ${wallets.length} wallets');
    } catch (e) {
      print('❌ [Firebase] Error batch saving wallets: $e');
      rethrow;
    }
  }

  // ================= READ =================
  Future<List<Wallet>> getAllWallets(String userId) async {
    try {
      final snapshot = await _getUserWalletsRef(userId).get();
      return snapshot.docs.map((doc) => _walletFromMap(doc.data())).toList();
    } catch (e) {
      print('❌ [Firebase] Error getting wallets: $e');
      return [];
    }
  }

  Future<Wallet?> getWalletById(String userId, String walletId) async {
    try {
      final doc = await _getUserWalletsRef(userId).doc(walletId).get();
      if (!doc.exists) return null;
      return _walletFromMap(doc.data()!);
    } catch (e) {
      print('❌ [Firebase] Error getting wallet: $e');
      return null;
    }
  }

  // ================= DELETE =================
  Future<void> deleteWallet(String userId, String walletId) async {
    try {
      await _getUserWalletsRef(userId).doc(walletId).delete();
      print('✅ [Firebase] Deleted wallet: $walletId');
    } catch (e) {
      print('❌ [Firebase] Error deleting wallet: $e');
      rethrow;
    }
  }

  // ================= HELPERS =================
  Map<String, dynamic> _walletToMap(Wallet wallet) {
    return {
      'id': wallet.id,
      'userId': wallet.userId,
      'name': wallet.name,
      'type': wallet.type.name,
      'balance': wallet.balance,
      'isDefault': wallet.isDefault,
      'createdAt': wallet.createdAt.toIso8601String(),
    };
  }

  Wallet _walletFromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      type: WalletType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => WalletType.cash,
      ),
      balance: (map['balance'] as num).toDouble(),
      isDefault: map['isDefault'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
