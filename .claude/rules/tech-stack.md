# Tech stack

- **Flutter (Dart)** — mobile only (iOS + Android), không cần responsive web.
- **State management: `flutter_riverpod`.** Không thêm bất kỳ giải pháp state khác (BLoC, Provider, GetX, MobX...).
- **Routing: `go_router`.**
- **Backend: Supabase** qua package `supabase_flutter` (database + RLS + trigger + RPC đã dựng — xem `SCHEMA.md`).
- **Biểu đồ: `fl_chart`** — radar chart "Show-off" và biểu đồ tiến bộ điểm trình.
- **Bản đồ: `google_maps_flutter`** — cho tính năng Sân (Phase 5).
- Không tự nâng/hạ phiên bản package hay thêm dependency mới khi chưa được yêu cầu; các ràng buộc version nằm trong `pubspec.yaml`.
- Chỉ **light mode** cho beta.
