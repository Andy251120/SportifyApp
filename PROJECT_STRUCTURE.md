# PROJECT_STRUCTURE.md — Cây thư mục đầy đủ

Đây là khung thư mục Claude Code cần dựng cho toàn bộ project (không chỉ Phase 0). Ở Phase 0, chỉ cần tạo các file đã có sẵn nội dung (main.dart, core/*) và **tạo rỗng phần khung `features/`** (mỗi feature có 3 thư mục con `data/`, `application/`, `presentation/`, chưa cần code bên trong — trừ `auth/` cần code thật ở Phase 0). Các Phase sau lần lượt lấp đầy từng feature theo đúng thứ tự trong CLAUDE.md.
- note: tạo khung project trước, nội dung các file tôi sẽ copy vào sau khi xây xong cấu trúc project

```
SportifyVN/
├── CLAUDE.md
├── SCHEMA.md
├── PROJECT_STRUCTURE.md
├── pubspec.yaml
├── .env                          # không commit — đã có trong .gitignore
├── .gitignore
├── analysis_options.yaml
└── lib/
    ├── main.dart                  # ĐÃ CÓ SẴN — entry point
    │
    ├── core/                      # hạ tầng dùng chung, không thuộc feature nào
    │   ├── config/
    │   │   └── app_config.dart    # ĐÃ CÓ SẴN — đọc .env
    │   ├── supabase/
    │   │   └── supabase_client.dart   # ĐÃ CÓ SẴN — init + Riverpod provider
    │   ├── router/
    │   │   └── app_router.dart    # ĐÃ CÓ SẴN (placeholder) — Phase 0 thay bằng route thật
    │   ├── theme/
    │   │   └── app_theme.dart     # ĐÃ CÓ SẴN — màu, bo tròn, font theo Design direction
    │   └── widgets/                # TẠO MỚI Ở PHASE 0
    │       ├── rounded_card.dart          # card bo tròn dùng chung toàn app
    │       ├── primary_button.dart         # nút to, dễ chạm 1 tay (theo Design direction)
    │       ├── friendly_empty_state.dart   # empty state với giọng văn vui vẻ
    │       └── score_stepper.dart          # bộ đếm +/- nhập tỷ số (dùng ở Phase 2)
    │
    └── features/
        ├── auth/                  # PHASE 0 — code thật ngay
        │   ├── data/
        │   │   └── auth_repository.dart       # gọi Supabase Auth (OTP số điện thoại)
        │   ├── application/
        │   │   └── auth_provider.dart          # Riverpod state cho luồng đăng nhập
        │   └── presentation/
        │       ├── login_screen.dart           # nhập số điện thoại + xác nhận OTP
        │       └── onboarding_screen.dart       # chọn môn + tự đánh giá điểm trình ban đầu
        │
        ├── profile/                # PHASE 1 — chỉ tạo khung rỗng ở Phase 0
        │   ├── data/
        │   │   ├── profile_repository.dart
        │   │   └── profile_model.dart
        │   ├── application/
        │   │   └── profile_provider.dart
        │   └── presentation/
        │       ├── profile_screen.dart
        │       ├── sport_tab_switcher.dart      # switch tab Tennis/Pickleball
        │       └── show_off_radar_chart.dart    # radar chart bằng fl_chart
        │
        ├── matches/                # PHASE 2 — khung rỗng ở Phase 0
        │   ├── data/
        │   │   ├── match_repository.dart        # gọi RPC create_match
        │   │   └── match_model.dart
        │   ├── application/
        │   │   └── match_provider.dart
        │   └── presentation/
        │       ├── report_result_screen.dart     # nhập kết quả (dùng score_stepper)
        │       └── confirm_result_screen.dart    # xác nhận/từ chối, gán trọng tài/HLV
        │
        ├── matchmaking/             # PHASE 3 — khung rỗng ở Phase 0
        │   ├── data/
        │   │   └── match_request_repository.dart  # gọi RPC accept_match_request_response
        │   ├── application/
        │   │   └── match_request_provider.dart
        │   └── presentation/
        │       ├── match_request_list_screen.dart
        │       └── create_match_request_screen.dart
        │
        ├── feed/                    # PHASE 4 — khung rỗng ở Phase 0
        │   ├── data/
        │   │   └── post_repository.dart
        │   ├── application/
        │   │   └── feed_provider.dart
        │   └── presentation/
        │       └── feed_screen.dart
        │
        ├── clubs/                   # PHASE 4 — khung rỗng ở Phase 0
        │   ├── data/
        │   │   └── club_repository.dart
        │   ├── application/
        │   │   └── club_provider.dart
        │   └── presentation/
        │       └── club_screen.dart
        │
        └── courts/                  # PHASE 5 — khung rỗng ở Phase 0
            ├── data/
            │   └── court_repository.dart
            ├── application/
            │   └── court_provider.dart
            └── presentation/
                └── court_list_screen.dart
```

## Quy ước đặt tên & kiến trúc

Xem `.claude/rules/architecture.md` (feature-first, 3 lớp, chỉ `*_repository.dart` gọi Supabase, đặt tên `snake_case.dart` / `PascalCase` / `camelCaseProvider`, model map 1-1 với `SCHEMA.md`).
