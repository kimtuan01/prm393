# 🔄 Git Workflow - Hướng dẫn Push/Pull

## 📤 Trước khi Push lên Main

### ✅ Checklist:
- [ ] Code đã test kỹ, không có bug
- [ ] Đã format code: `flutter format lib/`
- [ ] Đã analyze: `flutter analyze`
- [ ] **KHÔNG push file `.g.dart`** (đã có trong .gitignore)
- [ ] Commit message rõ ràng

### 📝 Commit message nên viết như thế nào:

**Format:**
```
<type>: <description>

[optional body]
```

**Types:**
- `feat:` - Tính năng mới
- `fix:` - Sửa bug
- `docs:` - Cập nhật documentation
- `style:` - Format code, không ảnh hưởng logic
- `refactor:` - Refactor code
- `test:` - Thêm tests
- `chore:` - Update dependencies, config

**Examples:**
```bash
git commit -m "feat: Add OCR receipt scanning feature"
git commit -m "fix: Fix transaction date picker crash"
git commit -m "docs: Update README with setup instructions"
```

---

## 🚫 Files đã được ignore

Các file sau **KHÔNG** được push lên Git:
```
# Generated files
**/*.g.dart
**/*.freezed.dart

# Build files
/build/
.dart_tool/

# Plugins
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.idea/
*.iml
```

---

## 🔄 Workflow Push Code

### 1. Check status:
```bash
git status
```

### 2. Add files:
```bash
# Add tất cả (recommended)
git add .

# Hoặc add từng file
git add lib/screens/home/home_screen.dart
```

### 3. Check lại xem có file `.g.dart` không:
```bash
git status | Select-String "\.g\.dart"
```
→ **Nếu có**, đừng commit! File này không nên push.

### 4. Commit:
```bash
git commit -m "feat: Your feature description"
```

### 5. Pull trước khi push (tránh conflict):
```bash
git pull origin main
```

### 6. Resolve conflicts (nếu có):
```bash
# Xem files bị conflict
git status

# Edit files, sau đó:
git add .
git commit -m "merge: Resolve conflicts"
```

### 7. Push:
```bash
git push origin main
```

---

## 📥 Workflow Pull Code từ Team

### 1. Stash changes hiện tại (nếu đang code dở):
```bash
git stash
```

### 2. Pull code mới:
```bash
git pull origin main
```

### 3. Get dependencies (nếu có thay đổi):
```bash
flutter pub get
```

### 4. **⚠️ QUAN TRỌNG** - Generate code lại:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Apply stash lại (nếu có):
```bash
git stash pop
```

### 6. Run app để test:
```bash
flutter run
```

---

## ⚠️ Xử lý Conflicts với `.g.dart` files

Nếu gặp conflict với file `.g.dart`:

```bash
# Xóa file conflict
git checkout --theirs lib/models/*.g.dart

# Hoặc xóa hết generated files
flutter pub run build_runner clean

# Generate lại
flutter pub run build_runner build --delete-conflicting-outputs
```

**Lý do:** File `.g.dart` được generate tự động, không nên resolve conflict manually.

---

## 🧹 Clean Git (Xóa file .g.dart đã được track)

Nếu file `.g.dart` đã bị push lên trước đó:

```bash
# Remove from Git tracking (không xóa file local)
git rm --cached lib/models/user.g.dart
git rm --cached lib/models/transaction.g.dart
git rm --cached **/*.g.dart

# Commit
git commit -m "chore: Remove generated files from Git"

# Push
git push origin main
```

Sau đó, mọi người trong team cần:
```bash
git pull origin main
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📋 Daily Workflow

### Sáng đến:
```bash
git pull origin main
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Cuối ngày:
```bash
git add .
git commit -m "feat: What you did today"
git pull origin main  # Check conflicts
git push origin main
```

---

## 🆘 Common Issues

### Issue 1: "File already tracked"
```bash
# Remove from tracking
git rm --cached <file>

# Update .gitignore
# Commit
git commit -m "chore: Update .gitignore"
```

### Issue 2: "Merge conflict in .g.dart"
```bash
# Accept theirs
git checkout --theirs lib/models/*.g.dart

# Or regenerate
flutter pub run build_runner build --delete-conflicting-outputs

# Continue merge
git add .
git commit -m "merge: Resolve conflicts"
```

### Issue 3: "Push rejected"
```bash
# Pull first
git pull origin main

# Resolve conflicts if any
# Then push
git push origin main
```

---

## 🎯 Best Practices

1. **Pull trước, Push sau**: Luôn `git pull` trước khi `push`
2. **Commit thường xuyên**: Đừng để code dồn lại
3. **Message rõ ràng**: Viết commit message có ý nghĩa
4. **Test trước khi push**: Chạy app, test kỹ
5. **Không push generated files**: Check `.gitignore`
6. **Regenerate sau pull**: Luôn chạy `build_runner` sau khi pull
7. **Stash khi pull**: Dùng `git stash` nếu đang code dở
8. **Branch cho feature lớn**: Tạo branch riêng, merge sau

---

## 📖 Useful Commands

```bash
# Check status
git status

# View changes
git diff

# View commit history
git log --oneline

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# View remote URL
git remote -v

# Create branch
git checkout -b feature/new-feature

# Switch branch
git checkout main

# Merge branch
git merge feature/new-feature

# Delete branch
git branch -d feature/new-feature
```

---

**Remember:** Generated files (`.g.dart`) should NEVER be in Git! 🚫

Last updated: 16/11/2025
