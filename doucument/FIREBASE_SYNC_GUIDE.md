# 🔄 HỆ THỐNG ĐỒNG BỘ FIREBASE - HƯỚNG DẪN ĐẦY ĐỦ

## 📋 TÓM TẮT

### Lần đầu setup (1 lần duy nhất):
1. ✅ Update Firebase Rules (cho phép read/write)
2. ✅ Upload Users lên Firebase (1 lần)
3. ✅ Upload ALL Data lên Firebase (1 lần)

### Sau đó - TỰ ĐỘNG 100%:
- ✅ Mỗi khi thêm/sửa/xóa transaction → **TỰ ĐỘNG sync ngay**
- ✅ Mỗi 5 phút → **TỰ ĐỘNG sync** data chưa upload
- ✅ Mỗi khi login → **TỰ ĐỘNG download** data từ Firebase về

---

## 🚀 BƯỚC 1: UPDATE FIREBASE RULES (1 LẦN)

### Cách 1: Qua Firebase Console
1. Vào: https://console.firebase.google.com/project/fintracker-1372d/firestore/rules
2. Xóa hết, paste vào:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. Click **"Xuất bản"** (Publish)
4. Đợi 10-30 giây

### Cách 2: Qua Terminal
```bash
firebase deploy --only firestore:rules
```

---

## 📤 BƯỚC 2: UPLOAD DATA LẦN ĐẦU (1 LẦN)

### Trên máy có data (máy của bạn):

1. Mở app
2. Đăng nhập
3. Vào **Profile** → **Settings**
4. Cuộn xuống **"Firebase / Cloud"**
5. Click **"Đồng bộ Users lên Firebase"**
   - Đợi thông báo: "Đã sync X users thành công"
6. Click **"Upload TẤT CẢ Data lên Firebase"**
   - Confirm
   - Đợi thông báo: "Đã upload: X giao dịch, X ngân sách..."

### Kiểm tra Firebase Console:
Vào: https://console.firebase.google.com/project/fintracker-1372d/firestore

Sẽ thấy:
- `users/{userId}` - thông tin user
- `users/{userId}/transactions/{txId}` - giao dịch
- `users/{userId}/budgets/{budgetId}` - ngân sách
- `users/{userId}/wallets/{walletId}` - ví
- `users/{userId}/categories/{catId}` - danh mục

---

## 📱 BƯỚC 3: ĐĂNG NHẬP TRÊN MÁY KHÁC

### Trên máy mới (máy của bạn):

1. Cài app
2. Mở app (phải có Internet)
3. Nhập **email** và **password**
4. Click **Đăng nhập**

### App sẽ tự động:
- ✅ Tải user từ Firebase về
- ✅ Chạy `fullSync()` - download tất cả data
- ✅ Tính toán lại số dư ví
- ✅ Hiển thị đầy đủ giao dịch, ngân sách, ví

### Logs sẽ hiện:
```
🔍 [Firebase] Searching for user with email: xxx
📊 [Firebase] Found 1 documents
✅ User found in Firebase, downloading to local...
✅ Cloud sync completed for user xxx
⬇️ Downloading all data for user xxx...
📥 Downloaded X transactions
📥 Downloaded X budgets
...
```

---

## 🔄 TỰ ĐỘNG ĐỒNG BỘ (SAU KHI SETUP)

### 1. Khi thêm/sửa/xóa transaction:
```
User thêm transaction → Save vào Hive → TỰ ĐỘNG upload Firebase ngay
```

- ✅ **Không cần bấm nút gì**
- ✅ Upload trong background (không block UI)
- ✅ Nếu lỗi network → retry sau 5 phút

### 2. Auto Sync định kỳ:
```
Mỗi 5 phút → Tự động sync các transaction chưa upload
```

- ✅ Chạy trong background
- ✅ Chỉ sync data có `isSynced = false`

### 3. Khi login:
```
Login → Download tất cả data từ Firebase
      → Upload user info lên Firebase
      → Start auto sync timer
```

---

## 🎯 KẾT QUẢ

### Trên máy 1:
- Thêm transaction → ✅ Tự động lên Firebase

### Trên máy 2:
- Mở app → ✅ Tự động tải về
- Hoặc đợi 5 phút → ✅ Tự động sync

### Sync 2 chiều:
- ✅ Machine A → Firebase → Machine B
- ✅ Machine B → Firebase → Machine A
- ✅ Conflict resolution: Newest wins (based on `updatedAt`)

---

## 🔧 TROUBLESHOOTING

### Lỗi "Permission Denied":
- Update Firebase Rules (Bước 1)
- Deploy rules: `firebase deploy --only firestore:rules`

### Data không sync:
- Check Internet connection
- Check Firebase Console → có data không?
- Check logs: `I/flutter ... [Sync]`

### Data bị duplicate:
- Xóa Hive local: Settings → Clear Data
- Login lại → Data sẽ download từ Firebase

### Conflict data:
- System tự động giữ version mới nhất
- Dựa vào `updatedAt` timestamp

---

## 📊 MONITORING

### Check sync status:
```dart
// In code
final syncService = SyncService();
await syncService.hasInternet(); // true/false

// In logs
I/flutter ... [Sync] Syncing X transactions...
I/flutter ... ✅ Cloud sync completed
```

### Firebase Console:
- Xem realtime data updates
- Check document timestamps
- Monitor read/write operations

---

## 🔐 BẢO MẬT (SAU KHI TEST)

Sau khi test xong, nên thay rules bằng:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow read for login
      allow read: if true;
      // Allow write if user is authenticated
      allow write: if request.auth != null;
      
      match /{subcollection}/{doc} {
        // Only owner can access their data
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

**LƯU Ý:** Để dùng rules này, cần setup Firebase Authentication.
