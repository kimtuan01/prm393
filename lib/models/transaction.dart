import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  String? note;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  TransactionType type;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String userId; // ID của user sở hữu transaction này

  @HiveField(9)
  String? categoryId; // 🔗 liên kết với CategoryGroup

  @HiveField(10)
  String? walletId; // 🔗 liên kết với Wallet

  @HiveField(11)
  bool isSynced; // ✅ Đã sync lên Firebase chưa

  @HiveField(12)
  DateTime updatedAt; // ✅ Last modified time

  @HiveField(13)
  String? paymentMethod; // Phương thức thanh toán (cash, card, etc.)

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    this.note,
    this.categoryId,
    this.walletId,
    required this.date,
    required this.type,
    required this.createdAt,
    required this.userId,
    bool? isSynced,
    DateTime? updatedAt,
    this.paymentMethod,
  }) : isSynced = isSynced ?? false,
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'categoryId': categoryId,
      'walletId': walletId,
      'paymentMethod': paymentMethod,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      note: json['note'],
      date: DateTime.parse(json['date']),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.expense,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'],
      walletId: json['walletId'],
      paymentMethod: json['paymentMethod'],
      isSynced: json['isSynced'] ?? false,
    );
  }
}

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  expense, // Khoản chi

  @HiveField(1)
  income, // Khoản thu

  @HiveField(2)
  loan, // Vay/Nợ
}
