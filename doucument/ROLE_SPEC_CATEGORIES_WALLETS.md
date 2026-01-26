# Roles & Responsibilities — Categories and Wallets (Admin vs User)

This document defines the responsibilities and constraints around Categories (CategoryGroup) and Wallets in FinTrack.

## Summary — short
- Admin: Seeds and manages *system templates* (CategoryGroup system entries). Admins must never access or modify user-owned financial data (user Wallets, balances, transactions). Admin actions are limited to seeding, updating system templates, and initiating global maintenance tasks (e.g., re-seeding defaults).
- User: Owns Wallets and Transactions and can create custom CategoryGroups (non-system). Users' wallets & balances are private and immutable by Admin.

---

## Principles & Constraints (EN) ✅

1. Separation of concerns
   - System templates (category seeds) are managed by Admin only.
   - User financial data (Wallets, Transactions, balances) belongs to individual users and is private.

2. Admin capabilities (allowed)
   - Seed or update "system" CategoryGroup templates (idempotent seeding).
   - Provide canonical category names/metadata (iconKey, colorValue, type).
   - Trigger global maintenance tasks (re-seed missing system categories, run migrations) but not directly modify user wallets/transactions.
   - View aggregated telemetry (non-sensitive) for debugging (only if implemented).

3. Admin constraints (forbidden)
   - **Cannot** read or modify user Wallet objects (including name, balance, walletId in transactions).
   - **Cannot** read, create, or delete user Transactions for the purpose of changing user balances (admin UI may show read-only lists for debugging only if explicitly allowed and the data is treated as read-only).
   - **Cannot** set or override a user's default wallet.

4. User capabilities
   - Create, edit, delete their own Wallets (subject to business rules: one default, cannot delete last wallet, safe reassignment on delete).
   - Create custom CategoryGroup entries (isSystem == false); these are private to user scope or visible as personal categories.
   - Use seeded system categories when creating budgets, transactions, etc.

5. Seeding & Lifecycle
   - System category seeding runs idempotently (e.g., at app startup or via Admin action).
   - Per-user Wallet seeding (default wallets) runs at post-registration / first-login (idempotent) and is executed by WalletService.seedDefaultWallets(userId).
   - Migrations that transform or assign data (e.g., assign default wallet to existing transactions) must be run in a controlled fashion (dev/test environment or with explicit admin confirmation) and must be idempotent and reversible if possible.

6. Auditing & Safety
   - Any global maintenance or migration should be logged clearly and provide reversible steps where feasible.
   - Deletion safeguards: the system should prevent accidental destructive actions (e.g., prevent the deletion of system CategoryGroups without confirmation).

---

## Ngắn gọn (Tiếng Việt) 🇻🇳

1. Tách bạch trách nhiệm
   - Admin chỉ quản lý **mẫu hệ thống** (CategoryGroup có isSystem=true). Người dùng quản lý ví và giao dịch của riêng họ.

2. Admin được phép
   - Seed / cập nhật danh mục hệ thống (idempotent).
   - Cung cấp tên danh mục chuẩn, icon, màu sắc.
   - Khởi chạy các tác vụ bảo trì toàn cục (re-seed, migration) nhưng **không** thao tác dữ liệu tài chính của user.

3. Admin bị giới hạn (không được)
   - **Không** đọc hoặc sửa Wallet của user (tên, số dư, walletId trong giao dịch).
   - **Không** thay đổi giao dịch của user nhằm chỉnh sửa số dư (được phép xem read-only để debug nếu có).
   - **Không** đặt/ghi đè ví mặc định của user.

4. Người dùng được phép
   - Tạo, sửa, xóa Wallet của họ (theo luật nghiệp vụ: 1 ví mặc định, không xóa ví cuối cùng, tái phân bổ giao dịch khi xóa).
   - Tạo nhóm danh mục riêng (isSystem=false).
   - Sử dụng danh mục hệ thống khi tạo ngân sách/giao dịch.

5. Vòng đời & Seeding
   - Seeding danh mục hệ thống chạy idempotently (ở startup hoặc khi admin trigger).
   - Seeding ví mặc định cho mỗi user chạy sau khi user đăng ký / đăng nhập lần đầu (WalletService.seedDefaultWallets(userId)).
   - Migration cần chạy có kiểm soát và có logging / rollback nếu khả thi.

6. Audit & An toàn
   - Ghi log các tác vụ global/migration.
   - Bảo vệ hành động xóa và yêu cầu xác nhận rõ ràng khi xóa mục hệ thống.

---

If you'd like, I can add checks in code (assertions) that block admin UI paths from calling user-scoped APIs, and a small integration test that verifies Admin cannot mutate a user wallet or transaction. ✅
