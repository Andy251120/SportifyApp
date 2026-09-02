# UI_SPEC.md — Đặc tả chi tiết Phase 1 (Hồ sơ & Show-off)

Đặc tả bằng chữ, thay cho ảnh mockup — dùng đúng token màu/bo góc đã định nghĩa sẵn trong `lib/core/theme/app_theme.dart`. Claude Code implement đúng theo đây, không cần xem ảnh.

Phase 0 (Login, Onboarding chọn môn) đã verify ổn ở vòng review trước, giữ nguyên theo code hiện có, không nằm trong phạm vi file này.


---

## Màn hình: Hồ sơ (Profile screen chính)

File: `lib/features/profile/presentation/profile_screen.dart`

### Cấu trúc tổng thể (từ trên xuống)

Toàn màn hình nền `AppTheme` scaffold background (`#FAFAF7`), padding ngang 24px, padding trên 28px.

**1. Header hồ sơ**
- Row: avatar tròn 52x52, bo `50%`, nền `AppTheme.tennisBallOrange`, chữ initials (2 ký tự đầu tên) màu trắng, font-weight 500, size 16.
- Cách avatar 12px: cột gồm 2 dòng — tên đầy đủ (size 17, weight 500, màu `#1C1C1A`), bên dưới là khu vực (`location_district` từ bảng `profiles`, size 13, màu `#6B6A63`).
- Margin dưới cùng khối này: 20px.

**2. Tab switcher Tennis/Pickleball**

Widget riêng: `lib/features/profile/presentation/sport_tab_switcher.dart` — tái sử dụng được ở nơi khác nếu cần.
- Container: nền `#EFEDE4`, bo góc 16px, padding 4px, layout `Row` 2 phần bằng nhau.
- Tab đang chọn: nền = màu theo môn (`AppTheme.sportColor(sport)` — xanh `courtGreen` cho tennis, xanh dương `pickleballBlue` cho pickleball), chữ trắng, weight 500, bo góc trong 12px, padding dọc 10px.
- Tab không chọn: nền trong suốt, chữ màu `#6B6A63`, cùng weight/padding.
- Chuyển tab cập nhật `profiles.current_mode` (không phải chỉ local state UI — đây là field lưu trên server, xem `SCHEMA.md`).
- Margin dưới: 20px.

**3. Khối điểm trình**
- Row baseline: số điểm trình lớn (`sport_stats.rating`, size 26, weight 500, màu `#1C1C1A`) + text phụ ngay cạnh (size 13, màu `#9C9A8F`): `"điểm trình · chưa xác thực"` nếu `profiles.is_verified == false`, ngược lại bỏ phần "chưa xác thực".
- Dòng dưới (size 12, màu `#9C9A8F`, margin dưới 16px): `"{matches_played} trận đã đấu"` — lấy từ `sport_stats.matches_played`.

**4. Radar chart Show-off**

File: `lib/features/profile/presentation/show_off_radar_chart.dart`, dùng `fl_chart` (`RadarChart`).

- Chiều cao cố định 220px, margin dưới 16px.
- **6 trục, đúng theo field thật trong `sport_stats.skill_matrix`** (không phải 5 trục như bản mockup ban đầu — bản đó chỉ minh họa, số trục thật lấy theo `SCHEMA.md`):
  | Field trong DB | Nhãn hiển thị (tiếng Việt) |
  |---|---|
  | `spin` | Xoáy bóng |
  | `power` | Lực đánh |
  | `speed` | Tốc độ |
  | `mental` | Tinh thần |
  | `stamina` | Thể lực |
  | `technique` | Kỹ thuật |
- Thang giá trị: 0-100 (giá trị đã lưu sẵn dạng số nguyên trong `skill_matrix`, ví dụ `{"spin":72,"power":58,...}`).
- Màu vùng tô: `AppTheme.tennisBallOrange` ở alpha 20% (`rgba(255,122,0,0.2)`), viền đường màu `AppTheme.tennisBallOrange` đặc, độ dày viền 2.
- Khi đang xem tab Pickleball: đổi màu tô/viền sang `AppTheme.pickleballBlue` tương ứng — màu radar chart luôn khớp màu môn đang chọn.
- Nhãn trục: size 11, màu `#6B6A63`. Ẩn số trên trục (`ticks` không hiện), chỉ hiện lưới nhạt màu `#E3E1D6`.
- Không hiện legend (chỉ 1 dataset, không cần).

**5. Nút chia sẻ hồ sơ**
- Full width, cao 48px, bo 16px, nền trắng, viền 1px `#E3E1D6`, chữ `#1C1C1A` size 14 weight 500.
- Icon `share` bên trái chữ, cách 6px.
- Text: `"Chia sẻ hồ sơ"`.
- Hành động (Phase 1 chưa cần làm thật — chỉ dựng UI, `onPressed` để trống hoặc TODO): xuất card hồ sơ dạng ảnh (avatar + radar chart + điểm trình) để chia sẻ ra ngoài — đúng tinh thần "khoảnh khắc chia sẻ" ở SRS mục 5.5, làm thật ở Phase sau khi có moment ăn mừng sau trận.

### Trạng thái rỗng / chưa có dữ liệu

Nếu `sport_stats` chưa có row cho môn đang chọn (user chưa tự đánh giá điểm trình môn đó — có thể xảy ra nếu ban đầu chỉ chọn 1 môn ở onboarding rồi sau bật thêm tab kia): thay toàn bộ khối 3-4 bằng empty state theo đúng giọng văn CLAUDE.md, ví dụ:

> "Bạn chưa có điểm trình {tên môn} — tự đánh giá ngay để bắt đầu leo hạng nhé!"

kèm nút `"Tự đánh giá ngay"` dẫn tới luồng tự đánh giá (dùng lại UI đã có ở onboarding Phase 0, không viết lại từ đầu).

---

## Quy ước dùng lại (áp dụng cho mọi màn Phase 1 trở đi)

- Card/khối bo góc dùng `lib/core/widgets/rounded_card.dart` khi có, không tự viết `Container` bo góc rời rạc lặp lại nhiều nơi.
- Nút chính (primary action) dùng `lib/core/widgets/primary_button.dart` đã có theme sẵn từ `AppTheme` — không tự style `ElevatedButton` riêng trong từng screen.
- Màu không hard-code hex lặp lại trong widget — luôn tham chiếu qua `AppTheme.courtGreen`, `AppTheme.tennisBallOrange`, `AppTheme.pickleballBlue`, `AppTheme.sportColor(sport)`.
