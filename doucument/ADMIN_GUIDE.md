# 🔐 Admin Account Guide

## Tài khoản Admin

### Thông tin đăng nhập Admin:
- **Email**: `admin@fintracker.com`
- **Password**: `Admin@123`

---

## 🎯 Cách đăng nhập Admin

1. Mở app → Màn hình **Login**
2. Nhập:
   - Email: `admin@fintracker.com`
   - Password: `Admin@123`
3. Click **"ĐĂNG NHẬP"**
4. Tự động chuyển đến **Admin Panel**

---

## � Admin Panel Features

### Màn hình Admin Home:
- **Welcome Card**: Hiển thị thông tin admin
- **Quản lý Database**: Truy cập Debug Screen
- **Quản lý Users**: Xem danh sách người dùng
- **Quản lý Transactions**: Xem và quản lý giao dịch
- **Nút Đăng xuất**: Logout về màn hình login

### Debug Screen (từ Admin Panel):
- � **Users**: Xem/xóa tài khoản
- � **Transactions**: Xem/xóa giao dịch  
- � **Session Data**: Quản lý phiên đăng nhập
- 🗑️ **Các nút xóa**: Xóa toàn bộ data

---

## 🔧 Thay đổi mật khẩu Admin

Mở file: `lib/services/auth_service.dart` (dòng 18-19)

```dart
static const String ADMIN_EMAIL = 'admin@fintracker.com';
static const String ADMIN_PASSWORD = ''; // 👈 Đổi ở đây
```

**Khuyến nghị**: Dùng mật khẩu mạnh hơn cho production!

---

## � Logout

### User thường:
- Click icon **Logout (🚪)** màu đỏ ở góc phải Home Screen
- Xác nhận đăng xuất

### Admin:
- Trong **Admin Panel**, click nút **"Đăng xuất"** màu đỏ
- Hoặc click icon logout ở AppBar
- Xác nhận đăng xuất

---

## 🔒 Phân biệt User & Admin

| Tính năng | User thường | Admin |
|-----------|------------|-------|
| Email | Bất kỳ email đăng ký | `admin@fintracker.com` |
| Đăng ký | Cần đăng ký + OTP | Không cần |
| Màn hình sau login | Home Screen | Admin Panel |
| Quản lý Database | ❌ | ✅ |
| Xóa data | ❌ | ✅ |
| Logout | Icon logout | Nút trong panel |

---

## ⚠️ Lưu ý quan trọng

1. **KHÔNG** share thông tin admin với user thường
2. **Đổi mật khẩu** trước khi deploy production
3. Admin có **toàn quyền** xóa dữ liệu
4. Logout admin sẽ về màn hình login bình thường
5. Tài khoản admin **không lưu trong Hive**, chỉ hardcoded

---

## 🧪 Test Flow

### Test Admin:
```
1. Mở app
2. Login với admin@fintracker.com / Admin@123
3. Vào Admin Panel
4. Click "Quản lý Database"
5. Xem users/transactions
6. Logout
```

### Test User:
```
1. Mở app
2. Đăng ký tài khoản mới
3. Xác thực OTP
4. Chọn preferences
5. Vào Home Screen (user normal)
6. Click logout icon
```

---

## 📝 Code quan trọng

### Check if admin:
```dart
final authService = Provider.of<AuthService>(context);
if (authService.isAdmin) {
  // Admin logic
} else {
  // User logic
}
```

### Login routing:
- Admin → `AdminHomeScreen`
- User → `HomeScreen`

---

**Tài khoản Admin hiện tại:**  
📧 Email: `admin@fintracker.com`  
🔑 Password: `Admin@123`

**Tính năng:**
- ✅ Đăng nhập riêng biệt
- ✅ Admin Panel riêng
- ✅ Logout tạm thời (icon màu đỏ)
- ✅ Quản lý toàn bộ database

