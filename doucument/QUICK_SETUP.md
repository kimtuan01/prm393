# ✅ Quick Setup - Cho bạn pull code từ GitHub

## 🚀 Chỉ cần 3 bước!

### 1️⃣ Clone & Install
```bash
git clone https://github.com/khanhhtapcode/FinTrack-App.git
cd FinTrack-App
flutter pub get
```

### 2️⃣ Generate Code (BẮT BUỘC!)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
> ⚠️ **Lý do:** Các file `.g.dart` không được push lên Git, phải generate lại

### 3️⃣ Chạy App
```bash
flutter run
```

---

## ✅ OCR đã sẵn sàng!

**Model OCR đã có trong repo** → Không cần tải gì thêm!

File: `assets/models/vietnamese_ocr_model.onnx` (đã push lên Git)

### Test OCR:
1. Mở app → Nhấn nút **"+"** 
2. Nhấn **icon camera** trên app bar
3. Chọn **"Chụp ảnh"** hoặc **"Chọn từ thư viện"**
4. Chụp/chọn ảnh hóa đơn tiếng Việt
5. ✅ Số tiền, ngày, danh mục tự động điền!

---

## 🐛 Nếu gặp lỗi

### Lỗi 1: "Cannot find UserAdapter"
```bash
# Chưa chạy build_runner
flutter pub run build_runner build --delete-conflicting-outputs
```

### Lỗi 2: "MissingPluginException"
```bash
flutter clean
flutter pub get
flutter run
```

### Lỗi 3: "Error loading OCR model"
```bash
# Kiểm tra file model có tồn tại
ls -la assets/models/vietnamese_ocr_model.onnx

# Nếu không có → Tải lại từ Git
git pull origin main
```

### Lỗi 4: App chạy chậm khi quét OCR
```bash
# Chạy release mode thay vì debug
flutter run --release
```

---

## 📄 Dependencies quan trọng

Tất cả đã được config trong `pubspec.yaml`, chỉ cần chạy `flutter pub get`:

- ✅ `onnxruntime ^1.4.1` - Chạy model OCR
- ✅ `image ^4.0.0` - Xử lý ảnh
- ✅ `image_picker` - Chụp/chọn ảnh
- ✅ `hive` - Database local
- ✅ `provider` - State management
- ✅ `firebase_core` - Backend

---

## 📖 Đọc thêm

Chi tiết hơn xem file:
- **SETUP_OCR.md** - Hướng dẫn OCR đầy đủ
- **README.md** - Hướng dẫn tổng quan
- **OCR_TRAINING_GUIDE.md** - Nếu muốn train lại model

---

## 🎯 TL;DR (Too Long; Didn't Read)

```bash
# Chỉ cần chạy 3 lệnh này:
git clone https://github.com/khanhhtapcode/FinTrack-App.git
cd FinTrack-App
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

**Xong!** OCR đã hoạt động sẵn, model đã có trong repo. 🎉
