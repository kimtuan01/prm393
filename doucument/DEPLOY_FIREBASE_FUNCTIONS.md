# 🚀 Deploy Firebase Cloud Functions

## ⚠️ Yêu cầu trước khi deploy

1. **Node.js đã cài đặt** (v18 trở lên)
2. **Firebase CLI đã cài đặt**
3. **Firebase Project đã tạo** (có trong google-services.json)
4. **Billing enabled** (Spark plan FREE không đủ cho Cloud Functions v2)

---

## 📦 Bước 1: Cài đặt Firebase CLI

```powershell
# Cài Firebase CLI (nếu chưa có)
npm install -g firebase-tools

# Kiểm tra version
firebase --version
```

---

## 🔑 Bước 2: Đăng nhập Firebase

```powershell
# Login vào Firebase (mở browser)
firebase login

# Kiểm tra đã login chưa
firebase projects:list
```

---

## 🏗️ Bước 3: Khởi tạo Firebase trong project

```powershell
# CD vào thư mục project
cd C:\Users\KHANH\expense_tracker_app

# Init Firebase (chọn Functions)
firebase init functions

# Chọn:
# - Use existing project → Chọn project của bạn
# - Language: JavaScript
# - ESLint: No (hoặc Yes tùy ý)
# - Install dependencies: Yes
```

**LƯU Ý:** Nếu đã có folder `functions/`, có thể skip bước init.

---

## 📝 Bước 4: Cài dependencies trong functions

```powershell
# CD vào functions folder
cd functions

# Cài nodemailer (nếu chưa có)
npm install nodemailer

# Kiểm tra package.json
cat package.json
```

**Đảm bảo có:**
```json
{
  "dependencies": {
    "firebase-functions": "^5.0.0",
    "nodemailer": "^6.9.0"
  }
}
```

---

## 🚀 Bước 5: Deploy Cloud Function

```powershell
# Quay lại root project
cd ..

# Deploy tất cả functions
firebase deploy --only functions

# Hoặc deploy chỉ sendOTP
firebase deploy --only functions:sendOTP
```

**Đợi deployment hoàn tất (~2-3 phút)**

---

## ✅ Bước 6: Kiểm tra deployment

### Xem Functions đã deploy:
```powershell
firebase functions:list
```

### Kiểm tra trong Firebase Console:
1. Vào: https://console.firebase.google.com/
2. Chọn project
3. Click **Functions** → Xem function `sendOTP`

### Test function:
```powershell
# Test sendOTP function
firebase functions:shell

# Trong shell:
sendOTP({data: {email: 'test@example.com', otp: '1234'}})
```

---

## 🔧 Bước 7: Cập nhật App

Sau khi deploy xong:

1. **Tắt Dev Mode:**
   ```dart
   // lib/services/email_service.dart
   static const bool _isDevelopmentMode = false; // ✅ TẮT DEV MODE
   ```

2. **Rebuild app:**
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Test đăng ký:**
   - Đăng ký với email thật
   - Kiểm tra inbox (hoặc spam folder)
   - OTP sẽ được gửi qua email ✅

---

## ⚠️ Troubleshooting

### ❌ "Billing account not configured"
**Vấn đề:** Cloud Functions v2 cần Blaze plan (pay-as-you-go)

**Giải pháp:**
1. Firebase Console → ⚙️ → Usage and billing
2. Click **Upgrade to Blaze plan**
3. Thêm credit card (free tier vẫn FREE, chỉ charge khi vượt quota)

**FREE TIER LIMITS:**
- 2 million invocations/month
- 400,000 GB-seconds, 200,000 GHz-seconds compute time

---

### ❌ "Permission denied" khi deploy
**Vấn đề:** Tài khoản không có quyền

**Giải pháp:**
```powershell
# Logout và login lại
firebase logout
firebase login

# Kiểm tra project
firebase use --add
```

---

### ❌ Email không gửi được (Gmail block)
**Vấn đề:** Gmail security block app password

**Giải pháp:**
1. Vào: https://myaccount.google.com/security
2. Bật **2-Step Verification**
3. Tạo **App Password**:
   - Security → 2-Step Verification → App passwords
   - Generate new password
   - Copy password vào `functions/index.js`:
     ```javascript
     auth: {
       user: "hkkhanhpro@gmail.com",
       pass: "xxxx xxxx xxxx xxxx", // ← Paste App Password
     }
     ```
4. Deploy lại: `firebase deploy --only functions`

---

### ❌ "CORS error" khi gọi từ app
**Vấn đề:** Firebase Functions v2 cần config CORS

**Giải pháp:** Đã config sẵn trong `index.js`:
```javascript
exports.sendOTP = onCall(async (request) => {
  // onCall tự động handle CORS
});
```

---

## 📊 Monitoring

### Xem logs:
```powershell
# Real-time logs
firebase functions:log

# Hoặc xem trong Console:
Firebase Console → Functions → Logs
```

### Xem usage:
```
Firebase Console → Functions → Usage
```

---

## 💰 Chi phí (Blaze Plan)

### FREE Tier (mỗi tháng):
- ✅ 2,000,000 invocations
- ✅ 400,000 GB-seconds
- ✅ 200,000 GHz-seconds

### Ước tính cho app này:
- **1 OTP email = 1 invocation**
- **10,000 users đăng ký/tháng = 10,000 invocations**
- **Chi phí: $0** (trong FREE tier)

**→ Hoàn toàn FREE cho app nhỏ!**

---

## 🎯 Tóm tắt

### Development (hiện tại):
```dart
_isDevelopmentMode = true; // ✅ Không cần deploy
```

### Production (sau khi deploy):
```dart
_isDevelopmentMode = false; // ✅ Gửi email thật
```

### Deploy commands:
```powershell
cd functions
npm install
cd ..
firebase deploy --only functions
```

**Done! 🚀**
