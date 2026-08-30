# CLAUDE.md — Context cho Claude Code

Đây là project **app cộng đồng Tennis & Pickleball**, bản Beta cho Đà Nẵng. Đọc file này trước khi code bất cứ gì. Xem thêm `SCHEMA.md` để biết chi tiết cấu trúc database.

## Tổng quan sản phẩm

App dạng mạng xã hội cho người chơi tennis/pickleball nghiệp dư: điểm trình minh bạch (có xác nhận chéo), ghép kèo nhanh, feed cộng đồng, danh sách sân. Chiến lược: free hoàn toàn ở beta, tập trung kéo user thật tại Đà Nẵng qua các club quen biết nhau trước, thương mại hóa sau khi đủ user.

**Tinh thần thiết kế bắt buộc:** app phải cảm giác như một **sân chơi thân thiện**, giống mạng xã hội vui vẻ — KHÔNG phải công cụ quản lý điểm số nghiêm túc. Xem mục "Design direction" bên dưới trước khi viết bất kỳ UI nào.

## Tech stack

- **Flutter (Dart)** — mobile only (iOS + Android), không cần responsive web.
- **State management:** `flutter_riverpod`.
- **Routing:** `go_router`.
- **Backend:** Supabase (đã dựng xong database, RLS, trigger, RPC — xem `SCHEMA.md`). Dùng package `supabase_flutter`.
- **Biểu đồ:** `fl_chart` — dùng cho radar chart "Show-off" (mục 3.1c) và biểu đồ tiến bộ điểm trình.
- **Bản đồ:** `google_maps_flutter` — cho tính năng Sân (Phase 5, chưa cần ngay).

## Supabase project

- URL và anon key đã có sẵn trong `.env` ở root project (đã tạo sẵn, đừng commit file này lên git — đã có trong `.gitignore`).
- **Quan trọng:** RLS đã bật nghiêm ngặt trên toàn bộ bảng. Một số cột **chỉ hệ thống (service_role) mới sửa được, client KHÔNG thể ghi trực tiếp**: `sport_stats.rating`, `sport_stats.matches_played`, `profiles.trust_score`, `profiles.is_verified`. Nếu code cố UPDATE các cột này từ client sẽ bị Postgres từ chối (exception) — đây là chủ đích, không phải bug.
- **Không tạo `matches` bằng INSERT trực tiếp** — luôn gọi RPC `create_match` (xem chữ ký trong `SCHEMA.md`) vì nó tạo `matches` + `match_participants` atomic trong 1 transaction.
- **Accept lời mời ghép kèo** cũng luôn gọi RPC `accept_match_request_response`, không tự update `match_request_responses.status` trực tiếp cho hành động accept (vì cần atomic decline các response khác + đóng request).
- Rating engine (tính điểm Elo khi trận confirmed) **chưa tồn tại** ở tầng Supabase — sẽ làm ở Phase 2, không phải việc của Phase 0.

## Design direction (bắt buộc tuân theo khi viết UI)

- **Tinh thần chủ đạo:** thân thiện, đúng chất "sân chơi" — vui, gần gũi, cộng đồng. Không dùng bố cục dashboard/quản trị dày đặc.
- **Hình khối:** bo tròn (rounded corner), card mềm mại.
- **Giọng văn UI copy:** xưng "bạn", câu chữ vui vẻ, hài hước nhẹ. Ví dụ empty state nên viết kiểu "Chưa có ai rủ chơi hôm nay, đăng lời mời đi bạn ơi!" chứ không phải "Không có dữ liệu".
- **Đọc được ngoài trời:** tương phản cao, chữ/nút đủ lớn (app dùng ngay tại sân dưới nắng).
- **Thao tác 1 tay, ít chạm:** hành động lặp lại nhiều (nhập kết quả, xác nhận ghép kèo) tối đa 2-3 chạm. Nhập tỷ số bằng bộ đếm +/-, không gõ số.
- **Màu:** tông tươi sáng, năng lượng (gợi ý xanh sân/cam bóng tennis), có màu riêng phân biệt tab Tennis/Pickleball.
- Chỉ cần light mode cho beta, không cần dark mode.
- Micro-interaction vui (confetti/bounce nhẹ) khi có hành động tích cực (like, lên điểm, accept ghép kèo).

## Cấu trúc project (feature-first)

Xem **`PROJECT_STRUCTURE.md`** để có cây thư mục đầy đủ, chi tiết từng file (bao gồm cả các Phase sau, không chỉ Phase 0) và quy ước đặt tên. Tóm tắt nhanh:

```
lib/
  main.dart
  core/            # config, supabase, router, theme, widgets — hạ tầng dùng chung
  features/
    auth/          # OTP đăng nhập, onboarding chọn môn + tự đánh giá điểm trình
    profile/       # hồ sơ, tab Tennis/Pickleball, radar chart Show-off
    matches/       # nhập/xác nhận kết quả trận, trọng tài/HLV
    matchmaking/   # ghép kèo, match_requests, availability
    feed/          # posts, likes, comments
    clubs/         # club, club_members
    courts/        # danh sách sân, review (Phase 5, chưa cần ngay)
```

Mỗi feature folder có cấu trúc con: `data/` (model + repository gọi Supabase), `application/` (Riverpod provider/state), `presentation/` (screen + widget). Ở Phase 0 chỉ cần tạo khung rỗng cho các feature chưa tới lượt — code thật theo đúng thứ tự Phase bên dưới.

## Kế hoạch Phase (làm đúng thứ tự, đừng nhảy cóc)

1. **Phase 0 — Setup** (đang làm bây giờ): khởi tạo project, kết nối Supabase, auth OTP số điện thoại, CI cơ bản.
2. **Phase 1 — Hồ sơ & Show-off:** tab Tennis/Pickleball, tự đánh giá điểm trình, radar chart, upload avatar.
3. **Phase 2 — Trận đấu & Rating engine:** cần xây thêm rating engine ở Supabase trước/song song.
4. **Phase 3 — Ghép kèo.**
5. **Phase 4 — Feed cộng đồng.**
6. **Phase 5 — Danh sách sân.**
7. **Phase 6 — Push notification thật.**
8. **Phase 7 — Beta hardening & launch nội bộ.**

**Nguyên tắc:** làm xong 1 Phase, dừng lại để review/test trước khi sang Phase tiếp theo — không code dồn nhiều Phase cùng lúc.

## Việc CHƯA làm được ở Phase 0 (cần người dùng tự cấu hình trên Supabase Dashboard)

- Bật Auth provider số điện thoại (OTP) trong Supabase Dashboard — Claude Code không tự làm được qua code, cần người dùng bật thủ công trước khi luồng đăng nhập chạy được thật.
- Storage buckets (avatars, post-images...) chưa tạo — nếu Phase 0 cần test upload avatar, nhắc người dùng tạo bucket trước, hoặc bỏ qua bước đó ở Phase 0 và làm ở Phase 1.