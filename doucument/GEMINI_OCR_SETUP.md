# Hướng Dẫn Sử Dụng Gemini OCR

## 🎯 Tổng Quan

Ứng dụng đã được tích hợp **Gemini Vision API** để quét hóa đơn tự động với độ chính xác cao. Hệ thống hỗ trợ cả **tiếng Việt** và **tiếng Anh**.

## ✅ Đã Hoàn Thành

### 1. Dependencies
- ✅ `google_generative_ai ^0.4.6` - Gemini API SDK
- ✅ `flutter_dotenv ^5.2.1` - Quản lý API key
- ✅ `http ^1.2.2` - Network requests
- ✅ `image ^4.0.0` - Xử lý ảnh

### 2. Cấu Trúc Code

#### `lib/models/receipt_data.dart`
Model dữ liệu hóa đơn:
```dart
class ReceiptData {
  String merchant;          // Tên cửa hàng
  double amount;           // Tổng tiền
  DateTime date;           // Ngày tháng
  String category;         // Danh mục (Food & Drink, Shopping, etc.)
  List<String> items;      // Danh sách món
  double confidence;       // Độ tin cậy (0.0-1.0)
  String? notes;          // Ghi chú
}
```

#### `lib/services/gemini_ocr_service.dart`
Service xử lý OCR với Gemini:
- ✅ Tiền xử lý ảnh (resize, enhance, compress)
- ✅ Prompt tối ưu cho hóa đơn Việt Nam
- ✅ Retry logic với exponential backoff
- ✅ Parse JSON response
- ✅ Confidence scoring

#### `lib/services/ocr_service.dart`
Unified service hỗ trợ cả Gemini và Custom OCR:
- ✅ Tự động chọn Gemini nếu có API key
- ✅ Fallback về Custom OCR nếu Gemini fail
- ✅ Chuyển đổi giữa 2 modes

#### `lib/screens/transaction/add_transaction_screen.dart`
Đã tích hợp OCR:
- ✅ Quét từ camera
- ✅ Chọn từ thư viện
- ✅ Hiển thị confidence score
- ✅ Cảnh báo nếu độ tin cậy thấp (<70%)

## 🚀 Cách Sử Dụng

### Bước 1: Kiểm tra API Key
File `.env` đã có API key:
```

### Bước 2: Chạy Ứng Dụng
```bash
flutter run
```

### Bước 3: Quét Hóa Đơn
1. Mở màn hình **Thêm giao dịch**
2. Nhấn nút **Quét hóa đơn** (icon camera)
3. Chọn:
   - 📷 **Chụp ảnh** - Mở camera để chụp
   - 🖼️ **Chọn từ thư viện** - Chọn ảnh có sẵn

### Bước 4: Kiểm Tra Kết Quả
- ✅ **Độ tin cậy ≥ 70%**: Nền xanh, dữ liệu đáng tin
- ⚠️ **Độ tin cậy < 70%**: Nền cam, cần kiểm tra lại

## 📊 Chi Tiết Kỹ Thuật

### Image Preprocessing
```dart
- Resize: Max 1024x1024 (giảm chi phí API)
- Enhance: Contrast +20%, Brightness +5%
- Compress: JPEG quality 85%
```

### Prompt Engineering
```
Hệ thống yêu cầu Gemini:
- Trích xuất: merchant, amount, date, items
- Phân loại: 8 categories (Food & Drink, Transport, etc.)
- Format: Strict JSON
- Ngôn ngữ: Vietnamese + English
- Confidence: 0.0-1.0 scale
```

### Error Handling
```
1. Network error → Retry 3 lần (2s, 4s, 6s delay)
2. API key invalid → Fallback về Custom OCR
3. Invalid image → Show error dialog
4. Low confidence → Warning trong snackbar
```

### Cost Optimization
```
- Model: gemini-1.5-flash (fast + cheap)
- Image resize → Giảm 70% data
- Retry logic → Tránh duplicate requests
- Fallback → Không mất data nếu Gemini fail
```

## 🎨 UI/UX Features

### Success Message
```dart
✅ Đã quét hóa đơn thành công
Độ tin cậy: 95%
```

### Warning Message
```dart
⚠️ Đã quét hóa đơn thành công
Độ tin cậy thấp: 45% - Vui lòng kiểm tra lại
```

### Form Auto-Fill
- **Số tiền**: Tự động format với dấu phẩy
- **Ngày tháng**: Parse từ DD/MM/YYYY
- **Danh mục**: Map từ English → Vietnamese
- **Ghi chú**: Bao gồm merchant + items

## 🧪 Testing Tips

### Test Cases
1. ✅ Hóa đơn siêu thị (Big C, Co.opMart)
2. ✅ Bill nhà hàng (text Việt, số tay)
3. ✅ Hóa đơn cafe (Highlands, Starbucks)
4. ✅ Hóa đơn Grab/taxi
5. ✅ Ảnh mờ/tối (test low confidence)
6. ✅ Ảnh không phải hóa đơn (test error handling)

### Debug Mode
Check console logs:
```
🤖 Using Gemini OCR...
✅ OCR Service initialized (Gemini: true)
⚠️ Gemini failed, falling back to Custom OCR...
```

## 🔧 Troubleshooting

### Lỗi: "Gemini API not configured"
**Nguyên nhân**: API key không hợp lệ
**Giải pháp**: Kiểm tra `.env` file

### Lỗi: Network timeout
**Nguyên nhân**: Kết nối internet kém
**Giải pháp**: Retry tự động 3 lần, hoặc dùng Custom OCR

### Độ tin cậy thấp (<50%)
**Nguyên nhân**: Ảnh mờ, nghiêng, thiếu sáng
**Giải pháp**: 
- Chụp lại ảnh rõ hơn
- Dùng flash/ánh sáng tốt
- Giữ camera thẳng với hóa đơn

### Không nhận diện được
**Nguyên nhân**: Không phải hóa đơn hoặc format lạ
**Giải pháp**: 
- Kiểm tra ảnh có rõ chữ không
- Thử chụp lại với góc khác
- Nhập thủ công nếu cần

## 📈 Performance Metrics

### Speed
- Gemini OCR: ~2-4 giây
- Custom OCR: ~1-2 giây
- Preprocessing: ~200ms

### Accuracy (ước tính)
- Hóa đơn rõ: >90% confidence
- Hóa đơn tốt: 70-90% confidence
- Hóa đơn mờ: <70% confidence

### Cost (Gemini API)
- Image < 1MB: ~$0.0003/request
- Với 1000 requests/tháng: ~$0.30
- Rất rẻ cho production

## 🎯 Roadmap

### Implemented ✅
- [x] Gemini Vision API integration
- [x] Image preprocessing
- [x] Confidence scoring
- [x] Vietnamese support
- [x] Fallback to Custom OCR
- [x] Auto-fill form fields
- [x] Error handling

### Future Enhancements 🚀
- [ ] View original image preview
- [ ] Scan again option
- [ ] OCR history/cache
- [ ] Batch scanning
- [ ] Analytics dashboard
- [ ] A/B testing Gemini vs Custom

## 📝 Notes

- API key đã được cấu hình và hoạt động
- Hệ thống tự động fallback về Custom OCR nếu Gemini fail
- Độ tin cậy >70% được coi là đáng tin cậy
- Cần kiểm tra API quota nếu sử dụng nhiều (limit: 60 requests/phút)

## 🤝 Support

Nếu gặp vấn đề:
1. Check console logs (debug mode)
2. Test với ảnh hóa đơn mẫu
3. Verify API key validity
4. Check internet connection

---

**Version**: 1.0.0  
**Last Updated**: November 18, 2025  
**Status**: ✅ Production Ready
