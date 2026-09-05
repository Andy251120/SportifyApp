# Kiến trúc & quy ước code

## Feature-first, 3 lớp

```
lib/
  main.dart
  core/            # hạ tầng dùng chung: config, supabase, router, theme, widgets, navigation, constants
  features/<tên>/
    data/          # *_model.dart + *_repository.dart (gọi Supabase)
    application/   # Riverpod provider / state
    presentation/  # screen + widget riêng của feature
```

- Feature hiện có: `auth`, `profile`, `matches`, `matchmaking`, `feed`, `clubs`, `courts`. Feature chưa tới lượt để **khung rỗng**, code thật theo đúng thứ tự Phase (xem `@.claude/rules/workflow.md`).
- Cây thư mục chi tiết từng file: xem `PROJECT_STRUCTURE.md`.

## Quy tắc lệ thuộc

- **Chỉ `*_repository.dart` được gọi `Supabase.instance.client` / `supabaseClientProvider` trực tiếp.** `application/` và `presentation/` luôn đi qua repository.
- `application/` không import `presentation/`. `presentation/` không gọi thẳng `data/` bỏ qua provider (trừ khi provider chỉ là passthrough repo).
- Widget dùng chung nhiều feature → `lib/core/widgets/`. Widget chỉ 1 feature dùng → `features/<tên>/presentation/`.

## Đặt tên

- File: `snake_case.dart`. Class: `PascalCase`. Provider: `camelCaseProvider` (vd `authStateChangesProvider`, `myProfileProvider`).
- Model (`*_model.dart`) map **1-1 với bảng/RPC trong `SCHEMA.md`**: field JSON giữ nguyên tên cột snake_case; expose getter `camelCase` trong class nếu cần.
- Enum map DB: có `fromDb(String)` + `dbValue` khớp đúng chuỗi Postgres.

## Pattern đã thiết lập (theo cho nhất quán)

- Provider hồ sơ/danh sách: `AsyncNotifierProvider` với `build()` fetch + method mutate rồi refetch (xem `MyProfileNotifier`, `MyMatchesNotifier`).
- Form nhiều bước: `AutoDisposeNotifier` giữ state + `submit()` (xem `ReportMatchController`, `LoginController`).
- Repository nhận `SupabaseClient` qua constructor; provider dựng từ `supabaseClientProvider`.
