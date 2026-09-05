# Testing & CI

- **Mỗi Phase phải kèm test**, không chỉ code tính năng.
- Đặt test theo feature: `test/<feature>/<tên>_test.dart` (vd `test/auth/login_screen_test.dart`, `test/matches/match_model_test.dart`). **Không dồn vào `widget_test.dart`.**
- Trước khi báo "xong Phase X": tự chạy `flutter analyze` **và** `flutter test`. Có lỗi / test đỏ thì sửa trước, không báo xong rồi để lỗi lại.
- Ưu tiên test logic thuần (model, controller, mapping) + widget test cho tương tác chính. Dùng fake Notifier / repo qua `ProviderScope.overrides` — không cần Supabase thật.

## CI — `.github/workflows/ci.yml`

- Chạy mọi lần push: `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build apk --debug`. Bước nào đỏ coi như commit chưa đạt.
- Cần 2 GitHub Secrets (user tự thêm ở repo Settings → Secrets): `SUPABASE_URL`, `SUPABASE_ANON_KEY`.

## Ngoài phạm vi hiện tại — KHÔNG tự dựng khi chưa được yêu cầu

- E2E trên emulator/thiết bị (integration_test, Maestro).
- Test Supabase RLS/trigger (pgTAP).
- Phân phối build cho tester (Firebase App Distribution, Codemagic...).
