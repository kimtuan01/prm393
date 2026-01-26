# 🚀 Hướng dẫn Setup OCR cho Expense Tracker App

## 📋 Yêu cầu hệ thống

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Git

## 🔧 Các bước cài đặt

### 1. Clone repository

```bash
git clone https://github.com/khanhhtapcode/FinTrack-App.git
cd FinTrack-App
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

**Lưu ý**: Lệnh này sẽ tự động tải và cài đặt tất cả các packages cần thiết, bao gồm:
- `onnxruntime: ^1.4.1` - Chạy model OCR
- `image: ^4.0.0` - Xử lý ảnh
- `image_picker` - Chụp/chọn ảnh

### 3. Kiểm tra model OCR

Đảm bảo file model đã có trong project:

```bash
# Windows
dir assets\models\vietnamese_ocr_model.onnx

# macOS/Linux
ls -la assets/models/vietnamese_ocr_model.onnx
```

**Kích thước file**: ~20-50MB

✅ **Nếu file tồn tại** → Bỏ qua bước 4  
❌ **Nếu không có file** → Làm theo bước 4

### 4. Download model OCR (nếu thiếu)

Model OCR được train sẵn trên dataset MC-OCR 2021 (hóa đơn tiếng Việt).

**Option 1: Lấy từ release**
```bash
# Tải từ GitHub releases (nếu có)
# Link: https://github.com/khanhhtapcode/FinTrack-App/releases
```

**Option 2: Lấy từ Google Drive**
```
1. Mở link: [Link Google Drive sẽ được cung cấp]
2. Tải file vietnamese_ocr_model.onnx
3. Copy vào thư mục: assets/models/
```

**Option 3: Train lại model**
```
1. Mở file vietnamese_receipt_ocr_training.ipynb trong Google Colab
2. Chạy tất cả các cells (Ctrl+F9)
3. Download model từ Cell 22
4. Copy vào assets/models/
```

### 5. Cấu hình Android permissions (nếu chạy trên Android)

File `android/app/src/main/AndroidManifest.xml` đã có sẵn các permissions:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

Không cần sửa gì thêm!

### 6. Chạy app

```bash
# Kiểm tra devices
flutter devices

# Chạy trên device/emulator
flutter run

# Hoặc chạy release mode (nhanh hơn)
flutter run --release
```

## ✅ Kiểm tra OCR hoạt động

### Test OCR trên app:

1. Mở app → Nhấn nút **"+"** ở góc phải
2. Nhấn **icon camera** trên app bar
3. Chọn **"Chụp ảnh"** hoặc **"Chọn từ thư viện"**
4. Chụp/chọn ảnh hóa đơn tiếng Việt
5. Chờ xử lý (loading dialog hiện ra)
6. Kiểm tra xem số tiền, ngày tháng có tự động điền không

### Logs để debug:

Trong terminal sẽ thấy các log:
```
✅ Custom OCR model loaded        → Model load thành công
❌ Error loading OCR model: ...   → Có lỗi (kiểm tra lại model file)
```

## 🐛 Xử lý lỗi thường gặp

### Lỗi 1: "Error loading OCR model"

**Nguyên nhân**: File model không tồn tại hoặc đường dẫn sai

**Giải pháp**:
```bash
# Kiểm tra file có tồn tại không
ls -la assets/models/vietnamese_ocr_model.onnx

# Nếu không có → Download lại model (xem bước 4)
```

### Lỗi 2: "MissingPluginException"

**Nguyên nhân**: Plugins chưa được cài đúng

**Giải pháp**:
```bash
flutter clean
flutter pub get
flutter run
```

### Lỗi 3: "Permission denied" khi chụp ảnh

**Nguyên nhân**: Chưa cấp quyền camera/storage

**Giải pháp**:
- Vào **Settings** → **Apps** → **Expense Tracker**
- Cấp quyền **Camera** và **Storage**

### Lỗi 4: App chạy chậm khi quét OCR

**Nguyên nhân**: Chạy debug mode

**Giải pháp**:
```bash
# Chạy release mode để tối ưu performance
flutter run --release
```

### Lỗi 5: "Undefined name 'OCRResult'"

**Nguyên nhân**: Thiếu import hoặc file bị sửa

**Giải pháp**:
```bash
# Re-generate code nếu cần
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📱 Test trên các platform

### Android
```bash
flutter run -d <android-device-id>
```

### iOS (macOS only)
```bash
flutter run -d <ios-device-id>
```

### Web (OCR có thể không hoạt động tốt)
```bash
flutter run -d chrome
```

## 📦 Dependencies chính

| Package | Version | Mục đích |
|---------|---------|----------|
| onnxruntime | ^1.4.1 | Chạy model ONNX |
| image | ^4.0.0 | Xử lý ảnh |
| image_picker | latest | Chụp/chọn ảnh |
| flutter | SDK | Framework |

## 📂 Cấu trúc thư mục quan trọng

```
expense_tracker_app/
├── lib/
│   ├── services/
│   │   └── custom_ocr_service.dart          ← Service OCR chính
│   └── screens/
│       └── transaction/
│           └── add_transaction_screen.dart  ← UI tích hợp OCR
├── assets/
│   └── models/
│       └── vietnamese_ocr_model.onnx        ← Model đã train (20-50MB)
├── pubspec.yaml                             ← Config dependencies
├── vietnamese_receipt_ocr_training.ipynb    ← Notebook train model
└── OCR_TRAINING_GUIDE.md                    ← Hướng dẫn train model
```

## 🎯 Tính năng OCR

✅ Nhận diện text tiếng Việt trên hóa đơn  
✅ Tự động trích xuất số tiền  
✅ Tự động phát hiện ngày tháng  
✅ Gợi ý danh mục chi tiêu  
✅ Hỗ trợ 200+ ký tự tiếng Việt có dấu  

## 📖 Tài liệu tham khảo

- **Training Guide**: `OCR_TRAINING_GUIDE.md` - Hướng dẫn train model từ đầu
- **Integration Guide**: `FLUTTER_OCR_INTEGRATION_COMPLETE.md` - Chi tiết tích hợp
- **Jupyter Notebook**: `vietnamese_receipt_ocr_training.ipynb` - Code train model

## 💡 Tips

1. **Ảnh hóa đơn tốt nhất**:
   - Ánh sáng đủ, không bị mờ
   - Text nằm ngang (không nghiêng quá 15°)
   - Độ phân giải tối thiểu: 64px chiều cao

2. **Tối ưu performance**:
   - Chạy release mode: `flutter run --release`
   - Test trên thiết bị thật, không phải emulator
   - Model inference time: ~1-2 giây trên device

3. **Nếu muốn train lại model**:
   - Mở `vietnamese_receipt_ocr_training.ipynb` trong Google Colab
   - Chạy tất cả cells
   - Download model mới từ Cell 22
   - Thay thế file trong `assets/models/`

## 🆘 Hỗ trợ

Nếu gặp vấn đề:

1. Kiểm tra log trong terminal khi chạy `flutter run`
2. Chạy `flutter doctor` để kiểm tra môi trường
3. Xem issues trên GitHub: [Link repository issues]
4. Liên hệ maintainer

---

**Tóm tắt**: Chỉ cần chạy `flutter pub get` là xong! Model OCR đã có sẵn trong repo. 🚀
