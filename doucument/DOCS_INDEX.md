# 📚 Tổng hợp Documentation

Dự án **FinTracker** - Expense Tracker App với Flutter

---

## 📁 Danh sách Documents

### 🚀 Cho người mới bắt đầu:

1. **README.md** - Hướng dẫn tổng quan
   - Yêu cầu hệ thống
   - Cài đặt đầy đủ
   - Cấu trúc dự án
   - Troubleshooting

2. **SETUP_GUIDE.md** - Quick setup guide
   - TL;DR commands
   - Vấn đề thường gặp
   - Checklist
   - SOS guide

3. **setup.bat** / **setup.sh** - Auto setup scripts
   - Chạy 1 lần để setup tất cả
   - Windows: `setup.bat`
   - Mac/Linux: `./setup.sh`

---

### 🔐 Cho Admin:

4. **ADMIN_GUIDE.md** - Admin Panel hướng dẫn
   - Tài khoản admin
   - Các tính năng admin
   - Cách thay đổi mật khẩu
   - Debug database

---

### 💾 Technical Docs:

5. **TRANSACTION_STORAGE_GUIDE.md** - Chi tiết về lưu trữ
   - Transaction model structure
   - TransactionService methods
   - Hive database
   - Code examples

6. **BACKEND_SETUP.md** - Firebase backend setup
   - Firebase configuration
   - Cloud Functions
   - Email service

7. **TEST_EMAIL.md** - Test OTP email
   - Cách test gửi email
   - Troubleshoot email issues

---

### 🔄 Git Workflow:

8. **GIT_WORKFLOW.md** - Git best practices
   - Push/Pull workflow
   - Commit message format
   - Xử lý conflicts
   - Daily workflow

---

## 🎯 Quick Start (Choose your path)

### Path 1: Tôi là người mới, lần đầu clone project
→ Đọc **SETUP_GUIDE.md** hoặc chạy **setup.bat**

### Path 2: Tôi muốn hiểu toàn bộ project
→ Đọc **README.md**

### Path 3: Tôi cần vào Admin Panel
→ Đọc **ADMIN_GUIDE.md**

### Path 4: Tôi muốn hiểu cách lưu trữ dữ liệu
→ Đọc **TRANSACTION_STORAGE_GUIDE.md**

### Path 5: Tôi cần push/pull code
→ Đọc **GIT_WORKFLOW.md**

### Path 6: Tôi gặp lỗi
→ Đọc phần **Troubleshooting** trong **README.md** hoặc **SETUP_GUIDE.md**

---

## ⚡ TL;DR - Chạy ngay

```bash
# Windows
setup.bat

# Mac/Linux
chmod +x setup.sh
./setup.sh

# Hoặc manual
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 🎓 Learning Path

### Week 1: Setup & Basic Understanding
1. Clone project
2. Chạy `setup.bat`
3. Đọc README.md
4. Run app và explore UI
5. Login với user thường
6. Login với admin account

### Week 2: Code Understanding
1. Đọc TRANSACTION_STORAGE_GUIDE.md
2. Đọc code trong `lib/models/`
3. Đọc code trong `lib/services/`
4. Hiểu Hive database
5. Test thêm giao dịch

### Week 3: Contributing
1. Đọc GIT_WORKFLOW.md
2. Tạo branch mới
3. Làm feature nhỏ
4. Commit và push
5. Test pull code từ main

---

## 📖 Documents Details

### README.md
- **Audience**: Everyone
- **Length**: Long (comprehensive)
- **Content**:
  - System requirements
  - Full installation steps
  - Project structure
  - Dependencies explained
  - Admin account info
  - Troubleshooting
  - Scripts reference

### SETUP_GUIDE.md
- **Audience**: New team members
- **Length**: Medium (focused)
- **Content**:
  - Quick commands
  - Common issues when pulling
  - Checklist
  - Build runner details
  - SOS section

### ADMIN_GUIDE.md
- **Audience**: Admins
- **Length**: Medium
- **Content**:
  - Admin credentials
  - Admin panel features
  - Change password guide
  - User vs Admin differences
  - Test flow

### TRANSACTION_STORAGE_GUIDE.md
- **Audience**: Developers
- **Length**: Long (technical)
- **Content**:
  - Model structure
  - Service methods
  - Storage location
  - Flow diagrams
  - Code examples
  - Usage examples

### GIT_WORKFLOW.md
- **Audience**: All developers
- **Length**: Long (comprehensive)
- **Content**:
  - Push workflow
  - Pull workflow
  - Commit message format
  - Conflict resolution
  - Best practices
  - Common issues

---

## 🔍 Find Information Fast

### "Làm sao để chạy project?"
→ SETUP_GUIDE.md → TL;DR section

### "Lỗi Cannot find 'UserAdapter'"
→ SETUP_GUIDE.md → Vấn đề thường gặp → #1

### "Tài khoản admin là gì?"
→ ADMIN_GUIDE.md → Thông tin đăng nhập

→ README.md → Tài khoản Admin

### "Giao dịch lưu ở đâu?"
→ TRANSACTION_STORAGE_GUIDE.md → Giao dịch được lưu ở đâu?

### "Làm sao push code?"
→ GIT_WORKFLOW.md → Workflow Push Code

### "File .g.dart bị conflict"
→ GIT_WORKFLOW.md → Xử lý Conflicts với .g.dart files

### "Setup Firebase"
→ BACKEND_SETUP.md

### "Test email OTP"
→ TEST_EMAIL.md

---

## 🎨 Document Structure

```
FinTrack-App/
├── README.md                        # 📘 Main documentation
├── SETUP_GUIDE.md                   # 🚀 Quick start
├── ADMIN_GUIDE.md                   # 🔐 Admin features
├── TRANSACTION_STORAGE_GUIDE.md     # 💾 Storage details
├── GIT_WORKFLOW.md                  # 🔄 Git practices
├── BACKEND_SETUP.md                 # ⚙️ Firebase setup
├── TEST_EMAIL.md                    # 📧 Email testing
├── MIGRATION_PLAN.md                # 🗺️ Migration guide
├── DOCS_INDEX.md                    # 📚 This file
├── setup.bat                        # 🪟 Windows setup
└── setup.sh                         # 🐧 Linux/Mac setup
```

---

## 💡 Tips

1. **Bookmark SETUP_GUIDE.md** - Use it every time you pull
2. **Read README.md once** - Understand the full picture
3. **Keep GIT_WORKFLOW.md handy** - Reference when pushing
4. **Use setup scripts** - Save time with automation
5. **Search in docs** - Use Ctrl+F to find info fast

---

## 🆘 Still Stuck?

1. Search in documents (Ctrl+F)
2. Check Troubleshooting sections
3. Run `setup.bat` / `setup.sh` again
4. Contact KHANH
5. Create GitHub Issue

---

## 📝 Document Maintenance

### Ai nên update documents?

- **README.md**: Khi có thay đổi lớn về project
- **SETUP_GUIDE.md**: Khi có issue mới từ team members
- **ADMIN_GUIDE.md**: Khi thêm/sửa admin features
- **TRANSACTION_STORAGE_GUIDE.md**: Khi thay đổi models/services
- **GIT_WORKFLOW.md**: Khi có best practice mới

### Khi nào update?

- Sau khi thêm dependencies mới
- Sau khi thay đổi cấu trúc project
- Sau khi team members gặp issue chung
- Sau khi thêm/xóa tính năng

---

**Happy Coding! 🚀**

Last updated: 16/11/2025
