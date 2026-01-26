# 💾 Hướng dẫn Lưu trữ Giao dịch (Transaction Storage)

## 📍 Giao dịch được lưu ở đâu?

Giao dịch được lưu vào **Hive Database** trên thiết bị của người dùng.

### 🗄️ Vị trí lưu trữ:
```
Hive Box: "transactions"
TypeId: 1 (Transaction)
Storage: Local device (offline-first)
```

---

## 🏗️ Kiến trúc Lưu trữ

### 1. **Model - Transaction** (`lib/models/transaction.dart`)
Định nghĩa cấu trúc dữ liệu:

```dart
@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0) String id;              // UUID unique
  @HiveField(1) double amount;          // Số tiền
  @HiveField(2) String category;        // Danh mục
  @HiveField(3) String? note;           // Ghi chú (optional)
  @HiveField(4) DateTime date;          // Ngày giao dịch
  @HiveField(5) TransactionType type;   // Loại: expense/income/loan
  @HiveField(6) String? paymentMethod;  // Phương thức thanh toán
  @HiveField(7) DateTime createdAt;     // Ngày tạo
}
```

**Các loại giao dịch:**
```dart
@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0) expense,  // Chi tiêu
  @HiveField(1) income,   // Thu nhập
  @HiveField(2) loan,     // Vay/Nợ
}
```

---

### 2. **Service - TransactionService** (`lib/services/transaction_service.dart`)

Service quản lý tất cả thao tác CRUD với giao dịch.

#### 📦 Khởi tạo:
```dart
static const String _boxName = 'transactions';
Box<Transaction>? _box;

// Singleton pattern - chỉ có 1 instance duy nhất
static final TransactionService _instance = TransactionService._internal();
factory TransactionService() => _instance;
```

#### 🔧 Các chức năng chính:

##### ➕ **Thêm giao dịch:**
```dart
Future<void> addTransaction(Transaction transaction) async {
  await init();
  await _box!.put(transaction.id, transaction);
}
```

##### 📋 **Lấy tất cả giao dịch:**
```dart
Future<List<Transaction>> getAllTransactions() async {
  await init();
  return _box!.values.toList();
}
```

##### 🔍 **Lọc theo loại:**
```dart
Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
  await init();
  return _box!.values.where((t) => t.type == type).toList();
}
```

##### 📅 **Lọc theo khoảng thời gian:**
```dart
Future<List<Transaction>> getTransactionsByDateRange(
  DateTime start,
  DateTime end,
) async {
  await init();
  return _box!.values.where((t) {
    return t.date.isAfter(start.subtract(Duration(days: 1))) &&
        t.date.isBefore(end.add(Duration(days: 1)));
  }).toList();
}
```

##### 📊 **Thống kê tháng hiện tại:**
```dart
// Tổng chi tiêu tháng này
Future<double> getCurrentMonthExpense() async {
  final transactions = await getCurrentMonthTransactions();
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold<double>(0, (sum, t) => sum + t.amount);
}

// Tổng thu nhập tháng này
Future<double> getCurrentMonthIncome() async {
  final transactions = await getCurrentMonthTransactions();
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold<double>(0, (sum, t) => sum + t.amount);
}
```

##### ✏️ **Cập nhật giao dịch:**
```dart
Future<void> updateTransaction(Transaction transaction) async {
  await init();
  await _box!.put(transaction.id, transaction);
}
```

##### 🗑️ **Xóa giao dịch:**
```dart
Future<void> deleteTransaction(String id) async {
  await init();
  await _box!.delete(id);
}
```

##### 🧹 **Xóa tất cả (Debug):**
```dart
Future<void> clearAll() async {
  await init();
  await _box!.clear();
}
```

---

### 3. **UI - AddTransactionScreen** (`lib/screens/transaction/add_transaction_screen.dart`)

Màn hình thêm giao dịch, nơi gọi service để lưu.

#### 📝 Code lưu giao dịch (dòng 520-550):

```dart
// Xác định loại giao dịch
TransactionType type;
if (_selectedTab == 0) {
  type = TransactionType.expense;
} else if (_selectedTab == 1) {
  type = TransactionType.income;
} else {
  type = TransactionType.loan;
}

// Tạo object Transaction
final transaction = Transaction(
  id: Uuid().v4(),                          // Generate UUID
  amount: amountValue,                       // Từ _amountController
  category: _selectedCategory,               // Danh mục đã chọn
  note: _noteController.text.isEmpty 
      ? null 
      : _noteController.text,                // Ghi chú (optional)
  date: _selectedDate,                       // Ngày đã chọn
  type: type,                                // Loại giao dịch
  paymentMethod: _selectedCategory,          // Phương thức
  createdAt: DateTime.now(),                 // Thời gian tạo
);

// 💾 LƯU VÀO HIVE
await _transactionService.addTransaction(transaction);

// Thông báo thành công
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Đã lưu giao dịch thành công!')),
);

// Quay lại màn hình trước
Navigator.pop(context, true);
```

---

## 🔄 Luồng hoạt động (Flow)

```
1. User nhập thông tin trong AddTransactionScreen
   ↓
2. User nhấn nút "Lưu"
   ↓
3. _saveTransaction() được gọi (dòng 505)
   ↓
4. Validate dữ liệu (amount, category)
   ↓
5. Tạo Transaction object với UUID
   ↓
6. Gọi _transactionService.addTransaction()
   ↓
7. TransactionService.addTransaction() lưu vào Hive Box
   ↓
8. Hiển thị SnackBar thành công
   ↓
9. Navigator.pop() - Quay lại màn hình trước
```

---

## 🚀 Khởi tạo Hive (`lib/main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  // 1️⃣ Initialize Hive
  await Hive.initFlutter();

  // 2️⃣ Register Adapters
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(TransactionAdapter());        // 👈 Transaction
  Hive.registerAdapter(TransactionTypeAdapter());    // 👈 TransactionType enum

  // 3️⃣ Open boxes
  await Hive.openBox<User>('users');
  await Hive.openBox('session');
  await Hive.openBox('preferences');
  // Box 'transactions' được mở tự động khi gọi TransactionService.init()

  runApp(MyApp());
}
```

---

## 📂 Cấu trúc File

```
lib/
├── models/
│   ├── transaction.dart              # Model & TypeAdapter
│   └── transaction.g.dart            # Generated by Hive
│
├── services/
│   └── transaction_service.dart      # CRUD operations
│
├── screens/
│   └── transaction/
│       └── add_transaction_screen.dart  # UI thêm giao dịch
│
└── main.dart                         # Khởi tạo Hive
```

---

## 🔍 Xem dữ liệu đã lưu

### Cách 1: Debug Screen (Admin Panel)
1. Login với admin: `admin@fintracker.com` / `Admin@123`
2. Vào **Admin Panel**
3. Click **"Quản lý Database"**
4. Tab **"Transactions"** sẽ hiển thị:
   - 5 giao dịch gần nhất
   - Tổng số giao dịch
   - Thông tin: Category, Amount, Type, Date

### Cách 2: Code (Console Debug)
```dart
import 'package:expense_tracker_app/services/transaction_service.dart';

void debugTransactions() async {
  final service = TransactionService();
  
  // Lấy tất cả
  final all = await service.getAllTransactions();
  print('Total transactions: ${all.length}');
  
  // Lọc theo loại
  final expenses = await service.getTransactionsByType(TransactionType.expense);
  print('Expenses: ${expenses.length}');
  
  // Tổng chi tháng này
  final monthExpense = await service.getCurrentMonthExpense();
  print('This month expense: $monthExpense VNĐ');
}
```

### Cách 3: Hive Box Inspector
```dart
// Trong code bất kỳ
final box = await Hive.openBox<Transaction>('transactions');
print('Total items: ${box.length}');
box.values.forEach((t) => print(t.toJson()));
```

---

## 💡 Ưu điểm của cách lưu trữ này

✅ **Offline-first**: Không cần internet, dữ liệu lưu local  
✅ **Nhanh**: Hive là NoSQL database rất nhanh  
✅ **Type-safe**: Sử dụng TypeAdapter, tránh lỗi runtime  
✅ **Singleton Service**: Đảm bảo dữ liệu đồng bộ  
✅ **Query linh hoạt**: Lọc theo type, date range, tháng hiện tại  
✅ **CRUD đầy đủ**: Create, Read, Update, Delete  

---

## 📊 Ví dụ sử dụng trong Home Screen

```dart
import 'package:expense_tracker_app/services/transaction_service.dart';
import 'package:expense_tracker_app/models/transaction.dart';

class HomeScreen extends StatefulWidget {
  // ...
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionService _transactionService = TransactionService();
  List<Transaction> _transactions = [];
  double _totalExpense = 0;
  double _totalIncome = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Lấy giao dịch tháng này
    final transactions = await _transactionService.getCurrentMonthTransactions();
    
    // Tính tổng
    final expense = await _transactionService.getCurrentMonthExpense();
    final income = await _transactionService.getCurrentMonthIncome();
    
    setState(() {
      _transactions = transactions;
      _totalExpense = expense;
      _totalIncome = income;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Hiển thị tổng
          Text('Chi tiêu: ${_totalExpense.toStringAsFixed(0)} VNĐ'),
          Text('Thu nhập: ${_totalIncome.toStringAsFixed(0)} VNĐ'),
          
          // Danh sách giao dịch
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return ListTile(
                  title: Text(transaction.category),
                  subtitle: Text(transaction.note ?? ''),
                  trailing: Text('${transaction.amount} VNĐ'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎯 Tóm tắt

| Thành phần | Vị trí | Chức năng |
|------------|--------|-----------|
| **Model** | `lib/models/transaction.dart` | Định nghĩa cấu trúc dữ liệu |
| **Service** | `lib/services/transaction_service.dart` | Quản lý CRUD với Hive |
| **UI** | `lib/screens/transaction/add_transaction_screen.dart` | Màn hình nhập + lưu |
| **Storage** | Hive Box `'transactions'` | Database local |
| **Init** | `lib/main.dart` | Khởi tạo Hive, register adapters |

---

## 🔐 Lưu ý quan trọng

1. **Dữ liệu lưu local**: Không sync giữa các thiết bị
2. **Xóa app = mất dữ liệu**: Hive lưu trong app sandbox
3. **TypeId phải unique**: Transaction=1, TransactionType=2, User=0
4. **Regenerate adapters**: Chạy `flutter pub run build_runner build` nếu sửa model
5. **Singleton Service**: Luôn dùng `TransactionService()` để get instance

---

**Created by:** AI Assistant  
**Last updated:** 16/11/2025
