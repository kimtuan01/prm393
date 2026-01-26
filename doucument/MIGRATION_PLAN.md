# 🔄 Migration Plan: Custom Auth → Firebase Auth

## 🎯 Mục tiêu
- ✅ Giữ nguyên Hive cho expense data (local, fast)
- ✅ Chuyển Auth sang Firebase (secure, có OTP email)
- ✅ Không mất data hiện tại

---

## 📋 Checklist

### **Bước 1: Setup Firebase Project**
```bash
# 1. Tạo Firebase project tại: https://console.firebase.google.com
# 2. Add Android app
# 3. Download google-services.json → android/app/
# 4. Add iOS app (nếu cần)
```

### **Bước 2: Add Firebase packages**
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_functions: ^4.5.0
  cloud_firestore: ^4.13.0  # Optional: cho backup
```

### **Bước 3: Initialize Firebase**
```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive (giữ nguyên)
  await Hive.initFlutter();
  await Hive.openBox('expenses');  // Local expense data
  await Hive.openBox('preferences');
  
  runApp(MyApp());
}
```

### **Bước 4: Create Hybrid Auth Service**
```dart
// lib/services/auth_service_v2.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:hive/hive.dart';

class AuthServiceV2 extends ChangeNotifier {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final Box _prefsBox = Hive.box('preferences');
  
  // Current user
  firebase.User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;
  
  // Register với Firebase Auth
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // 1. Create Firebase user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 2. Update display name
      await credential.user?.updateDisplayName('$firstName $lastName');
      
      // 3. Send email verification (OTP alternative)
      await credential.user?.sendEmailVerification();
      
      // 4. Save user info to Hive (local cache)
      await _prefsBox.put('firstName', firstName);
      await _prefsBox.put('lastName', lastName);
      await _prefsBox.put('email', email);
      
      return true;
    } catch (e) {
      print('❌ Register error: $e');
      return false;
    }
  }
  
  // Login với Firebase Auth
  Future<bool> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print('❌ Login error: $e');
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    notifyListeners();
  }
  
  // Send OTP (Firebase handles this)
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
```

### **Bước 5: Keep Expense Data in Hive**
```dart
// lib/services/expense_service.dart
class ExpenseService {
  final Box<Expense> _box = Hive.box<Expense>('expenses');
  
  // All expense operations stay with Hive
  Future<void> addExpense(Expense expense) async {
    await _box.add(expense);
  }
  
  List<Expense> getExpenses() {
    return _box.values.toList();
  }
  
  // Optional: Backup to Firestore
  Future<void> syncToCloud() async {
    if (FirebaseAuth.instance.currentUser != null) {
      final firestore = FirebaseFirestore.instance;
      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      for (var expense in _box.values) {
        if (!expense.isSynced) {
          await firestore
              .collection('users')
              .doc(userId)
              .collection('expenses')
              .add(expense.toJson());
          
          expense.isSynced = true;
          await expense.save();
        }
      }
    }
  }
}
```

### **Bước 6: Setup Firebase Functions cho OTP Email**
```javascript
// functions/index.js
const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.pass
  }
});

// Cloud Function: Send custom OTP
exports.sendOTP = functions.https.onCall(async (data, context) => {
  const { email, otp } = data;
  
  await transporter.sendMail({
    from: 'FinTracker <noreply@fintracker.com>',
    to: email,
    subject: 'Mã OTP Xác Thực - FinTracker',
    html: `
      <h2>Mã OTP: ${otp}</h2>
      <p>Có hiệu lực trong 5 phút.</p>
    `
  });
  
  return { success: true };
});

// Set config
// firebase functions:config:set email.user="hkkhanhpro@gmail.com" email.pass="mhjw ppzf mmxp cerc"
```

---

## 🔄 So sánh Before/After

### **Before (Hiện tại)**
```
Auth: Custom (Hive) → Tự code OTP, hash password
Data: Hive → Local only
Email: Mock (dev mode)
```

### **After (Đề xuất)**
```
Auth: Firebase Auth → Secure, built-in OTP
Data: Hive → Local (fast, offline)
Backup: Firebase Firestore (optional) → Multi-device
Email: Firebase Functions → Real email via Cloud
```

---

## ⚠️ Important Notes

### **Không cần migrate ngay!**
- ✅ Hiện tại dùng Hive + Mock OTP để dev
- ✅ Khi cần email thật → Add Firebase Functions only
- ✅ Khi cần multi-device → Add Firestore backup

### **Phân chia trách nhiệm rõ ràng:**
```dart
Firebase Auth → Login/Register/OTP
Hive → Expenses/Transactions (local)
Firebase Functions → Send emails
Firebase Firestore → Backup (optional)
```

### **Chi phí:**
- Firebase Auth: MIỄN PHÍ (unlimited)
- Firebase Functions: MIỄN PHÍ (2M invocations/month)
- Firestore: MIỄN PHÍ (50K reads/day, 20K writes/day)
- **→ Đủ xài cho cả ngàn users!**

---

## 🎯 Kết luận

### **Recommendation: HYBRID**
```
✅ Firebase: Authentication + Email
✅ Hive: Expense data (local, fast)
✅ Firestore: Backup (optional, enable sau)
```

### **Tại sao không Firebase-only?**
1. Expense tracker cần **offline-first** (record chi tiêu bất cứ lúc nào)
2. Hive **nhanh hơn** Firestore rất nhiều cho local data
3. Không tốn quota Firebase cho operations thường xuyên
4. Tránh lag khi không có mạng

### **Tại sao không Hive-only?**
1. Auth tự code **không an toàn** bằng Firebase
2. Gửi OTP email **không thể** từ mobile app
3. Multi-device sync **rất khó** tự implement
4. Mất data khi mất máy

---

## 🚀 Next Steps

### **Option A: Giữ nguyên (Development)**
```
→ Continue với Hive + Mock OTP
→ Focus vào core features
→ Migrate sau khi hoàn thiện UI/UX
```

### **Option B: Hybrid ngay (Recommended)**
```
→ Add Firebase Auth cho register/login
→ Add Firebase Functions cho OTP email
→ Giữ Hive cho expense data
→ Production-ready
```

### **Option C: Full Firebase (Không khuyên)**
```
→ Migrate toàn bộ sang Firebase
→ Mất offline capability
→ Slow performance
→ Tốn quota
```

---

## 💡 Tôi vote cho Option B!

**Lý do:**
- Best of both worlds
- Production-ready auth
- Fast local data
- Có thể scale sau
- Chi phí = $0

Bạn nghĩ sao? 🤔
