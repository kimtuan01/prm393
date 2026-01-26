# 📧 Hướng dẫn Setup Backend để gửi Email thật

## ⚠️ Vấn đề
Mobile apps (Android/iOS) **KHÔNG CHO PHÉP** kết nối SMTP trực tiếp vì lý do bảo mật.
- ❌ Direct SMTP → Connection timeout
- ✅ Backend API → Success

## 🎯 3 Giải pháp để gửi Email thật

---

## **Giải pháp 1: Firebase Functions (Khuyên dùng - Miễn phí)**

### Bước 1: Setup Firebase Project
```bash
# Cài Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Init project
firebase init functions
# Chọn: JavaScript hoặc TypeScript
# Chọn: Yes để cài dependencies
```

### Bước 2: Cài packages
```bash
cd functions
npm install nodemailer
```

### Bước 3: Tạo file `functions/index.js`
```javascript
const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

// Configure email transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'hkkhanhpro@gmail.com',
    pass: 'mhjw ppzf mmxp cerc' // Gmail App Password
  }
});

// Cloud Function để gửi OTP
exports.sendOTP = functions.https.onCall(async (data, context) => {
  const { email, otp } = data;
  
  try {
    const mailOptions = {
      from: 'FinTracker <hkkhanhpro@gmail.com>',
      to: email,
      subject: 'Mã OTP Xác Thực - FinTracker',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #4ECDC4;">Mã OTP Của Bạn</h2>
          <p>Xin chào,</p>
          <p>Mã OTP để xác thực tài khoản FinTracker của bạn là:</p>
          <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 8px;">
            <h1 style="color: #4ECDC4; font-size: 36px; letter-spacing: 8px; margin: 0;">${otp}</h1>
          </div>
          <p style="color: #666; margin-top: 20px;">Mã này có hiệu lực trong <strong>5 phút</strong>.</p>
          <p style="color: #999; font-size: 12px;">Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
          <p style="color: #999; font-size: 12px;">Trân trọng,<br><strong>FinTracker Team</strong></p>
        </div>
      `
    };
    
    await transporter.sendMail(mailOptions);
    console.log('✅ OTP sent to:', email);
    
    return { success: true, message: 'Email sent successfully' };
  } catch (error) {
    console.error('❌ Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email');
  }
});
```

### Bước 4: Deploy
```bash
firebase deploy --only functions
```

### Bước 5: Update Flutter code
```dart
// pubspec.yaml - Thêm package
dependencies:
  cloud_functions: ^4.5.0

// email_service.dart - Update code
import 'package:cloud_functions/cloud_functions.dart';

static Future<bool> _sendViaFirebase(String email, String otp) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('sendOTP');
    final result = await callable.call({
      'email': email,
      'otp': otp,
    });
    
    print('✅ Email sent via Firebase: ${result.data}');
    return result.data['success'] == true;
  } catch (e) {
    print('❌ Firebase Error: $e');
    return false;
  }
}

// Trong sendOTP(), thay đổi:
if (!_isDevelopmentMode) {
  return await _sendViaFirebase(recipientEmail, otp);
}
```

### Bước 6: Bật mode production
```dart
// email_service.dart
static const bool _isDevelopmentMode = false; // Đổi thành false
```

---

## **Giải pháp 2: Node.js Backend (Tự host)**

### Bước 1: Tạo Node.js API
```bash
mkdir fintracker-backend
cd fintracker-backend
npm init -y
npm install express nodemailer cors
```

### Bước 2: Tạo file `server.js`
```javascript
const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// Configure email
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'hkkhanhpro@gmail.com',
    pass: 'mhjw ppzf mmxp cerc'
  }
});

// API endpoint
app.post('/send-otp', async (req, res) => {
  const { email, otp } = req.body;
  
  try {
    await transporter.sendMail({
      from: 'FinTracker <hkkhanhpro@gmail.com>',
      to: email,
      subject: 'Mã OTP Xác Thực - FinTracker',
      html: `
        <h2>Mã OTP Của Bạn</h2>
        <h1 style="color: #4ECDC4; font-size: 36px;">${otp}</h1>
        <p>Mã có hiệu lực trong 5 phút.</p>
      `
    });
    
    res.json({ success: true, message: 'Email sent' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.listen(3000, () => {
  console.log('🚀 Server running on http://localhost:3000');
});
```

### Bước 3: Chạy server
```bash
node server.js
```

### Bước 4: Deploy lên server
- **Heroku**: `git push heroku main`
- **Railway**: Connect GitHub repo
- **DigitalOcean**: Deploy Node.js app
- **Vercel**: Deploy serverless function

### Bước 5: Update Flutter
```dart
// email_service.dart
static const String _apiEndpoint = 'https://your-api.herokuapp.com/send-otp';
static const bool _isDevelopmentMode = false;
```

---

## **Giải pháp 3: PHP Backend (Shared hosting)**

### Tạo file `send-otp.php`
```php
<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$data = json_decode(file_get_contents('php://input'), true);
$email = $data['email'];
$otp = $data['otp'];

$to = $email;
$subject = 'Mã OTP Xác Thực - FinTracker';
$message = "
<html>
<body>
  <h2>Mã OTP Của Bạn</h2>
  <h1 style='color: #4ECDC4;'>$otp</h1>
  <p>Mã có hiệu lực trong 5 phút.</p>
</body>
</html>
";

$headers = "MIME-Version: 1.0\r\n";
$headers .= "Content-type:text/html;charset=UTF-8\r\n";
$headers .= "From: FinTracker <hkkhanhpro@gmail.com>\r\n";

if(mail($to, $subject, $message, $headers)) {
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false]);
}
?>
```

Upload lên hosting và update URL trong Flutter.

---

## 🎯 So sánh các giải pháp

| Giải pháp | Chi phí | Độ khó | Reliability |
|-----------|---------|--------|-------------|
| **Firebase Functions** | Miễn phí (125K calls/tháng) | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Node.js (Railway)** | Miễn phí/$5/tháng | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **PHP Shared Hosting** | $2-5/tháng | ⭐ | ⭐⭐⭐ |

---

## 🚀 Khuyến nghị

**Dùng Firebase Functions** vì:
- ✅ Miễn phí (125,000 requests/tháng)
- ✅ Auto-scaling
- ✅ Secure
- ✅ Easy setup
- ✅ Integrated với Firebase Auth nếu cần

---

## 📝 Checklist

### Development Mode (hiện tại)
- [x] OTP hiển thị trong console
- [x] Test được flow đăng ký
- [x] Không cần backend

### Production Mode (khi deploy)
- [ ] Chọn 1 trong 3 giải pháp trên
- [ ] Setup backend API
- [ ] Deploy backend
- [ ] Update `_apiEndpoint` trong `email_service.dart`
- [ ] Đổi `_isDevelopmentMode = false`
- [ ] Test email thật
- [ ] Build APK/IPA

---

## 🔒 Bảo mật

**⚠️ QUAN TRỌNG:**
- ❌ Không bao giờ để Gmail password trong Flutter code
- ✅ Luôn để credentials trong backend
- ✅ Dùng environment variables cho password
- ✅ Enable 2FA và App Password cho Gmail

```javascript
// Good practice: Use environment variables
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD
  }
});
```

---

## 💡 Tips

1. **Test nhanh với ngrok:**
```bash
npm install -g ngrok
node server.js &
ngrok http 3000
# Copy URL ngrok vào Flutter
```

2. **Dùng SendGrid/Mailgun cho production:**
- Reliable hơn Gmail
- Không bị rate limit
- Tracking & analytics

3. **Alternative services:**
- AWS SES
- SendGrid (100 emails/day miễn phí)
- Mailgun (5,000 emails/month miễn phí)
- Twilio SendGrid

---

## 🆘 Troubleshooting

**Gmail chặn email?**
- Enable "Less secure app access" (nếu chưa dùng App Password)
- Tạo Gmail App Password: https://myaccount.google.com/apppasswords
- Check spam folder

**Firebase Functions lỗi?**
- Check logs: `firebase functions:log`
- Verify project ID trong Flutter
- Enable billing (cần credit card, nhưng free tier đủ xài)

**Node.js connection timeout?**
- Check CORS settings
- Verify URL đúng
- Test với Postman trước

---

Có câu hỏi? Ping me! 🚀
