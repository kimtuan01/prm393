import 'package:hive/hive.dart';

@HiveType(typeId: 20)
class Wallet extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId; // owner user id

  @HiveField(2)
  String name;

  @HiveField(3)
  WalletType type;

  @HiveField(4)
  double balance;

  @HiveField(5)
  bool isDefault;

  @HiveField(6)
  DateTime createdAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0,
    this.isDefault = false,
    required this.createdAt,
  });

  static const walletTypeLabels = {
    WalletType.cash: 'Tiền mặt',
    WalletType.bank: 'Ngân hàng',
    WalletType.ewallet: 'Ví điện tử',
    WalletType.saving: 'Tiết kiệm',
    WalletType.investment: 'Đầu tư',
  };
}

@HiveType(typeId: 21)
enum WalletType {
  @HiveField(0)
  cash,

  @HiveField(1)
  bank,

  @HiveField(2)
  ewallet,

  @HiveField(3)
  saving,

  @HiveField(4)
  investment,
}

// Manual adapters (no build_runner required)
class WalletAdapter extends TypeAdapter<Wallet> {
  @override
  final int typeId = 20;

  @override
  Wallet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }

    // Backwards-compatible decoding of WalletType (could be stored as enum, int, or string)
    final rawType = fields[3];
    WalletType type;
    if (rawType is WalletType) {
      type = rawType;
    } else if (rawType is int) {
      switch (rawType) {
        case 0:
          type = WalletType.cash;
          break;
        case 1:
          type = WalletType.bank;
          break;
        case 2:
          type = WalletType.ewallet;
          break;
        case 3:
          type = WalletType.saving;
          break;
        case 4:
          type = WalletType.investment;
          break;
        default:
          type = WalletType.cash;
      }
    } else if (rawType is String) {
      final s = rawType.split('.').last.toLowerCase();
      switch (s) {
        case 'cash':
          type = WalletType.cash;
          break;
        case 'bank':
          type = WalletType.bank;
          break;
        case 'ewallet':
        case 'e_wallet':
          type = WalletType.ewallet;
          break;
        case 'saving':
        case 'savings':
          type = WalletType.saving;
          break;
        case 'investment':
          type = WalletType.investment;
          break;
        default:
          type = WalletType.cash;
      }
    } else {
      type = WalletType.cash;
    }

    return Wallet(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      type: type,
      balance: (fields[4] as num?)?.toDouble() ?? 0.0,
      isDefault: fields[5] as bool? ?? false,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Wallet obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.balance)
      ..writeByte(5)
      ..write(obj.isDefault)
      ..writeByte(6)
      ..write(obj.createdAt);
  }
}

class WalletTypeAdapter extends TypeAdapter<WalletType> {
  @override
  final int typeId = 21;

  @override
  WalletType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WalletType.cash;
      case 1:
        return WalletType.bank;
      case 2:
        return WalletType.ewallet;
      case 3:
        return WalletType.saving;
      case 4:
        return WalletType.investment;
      default:
        return WalletType.cash;
    }
  }

  @override
  void write(BinaryWriter writer, WalletType obj) {
    switch (obj) {
      case WalletType.cash:
        writer.writeByte(0);
        break;
      case WalletType.bank:
        writer.writeByte(1);
        break;
      case WalletType.ewallet:
        writer.writeByte(2);
        break;
      case WalletType.saving:
        writer.writeByte(3);
        break;
      case WalletType.investment:
        writer.writeByte(4);
        break;
    }
  }
}
