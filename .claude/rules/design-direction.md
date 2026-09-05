# Design direction (bắt buộc khi viết UI)

- **Tinh thần:** thân thiện, đúng chất "sân chơi" — vui, gần gũi, cộng đồng. Không dùng bố cục dashboard/quản trị dày đặc.
- **Từ Phase 1 trở đi: implement đúng `UI_SPEC.md`** khi màn hình đã được mô tả — không tự đoán layout, không tự thêm nút/thành phần ngoài spec. Việc phụ trợ không có trong spec (đăng xuất, sửa hồ sơ...) đưa vào menu/overflow, giữ thân màn hình đúng spec.
- **Hình khối:** bo tròn, card mềm. Dùng `RoundedCard`, `PrimaryButton` sẵn có — không tự style `Container`/`ElevatedButton` rời rạc lặp lại.
- **Màu:** tham chiếu qua `AppTheme` (`courtGreen`, `tennisBallOrange`, `pickleballBlue`, `sportColor`, `radarColor`, `textPrimary/Secondary/Muted`, `surfaceMuted`, `borderSubtle`) — không hard-code hex lặp lại.
- **Giọng văn UI:** xưng "bạn", vui vẻ, hài hước nhẹ. Empty state kiểu "Chưa có ai rủ chơi hôm nay, đăng lời mời đi bạn ơi!" — không viết "Không có dữ liệu". Dùng `FriendlyEmptyState`.
- **Đọc ngoài nắng:** tương phản cao, chữ/nút đủ lớn.
- **Thao tác 1 tay, ít chạm:** hành động lặp nhiều tối đa 2-3 chạm. Nhập tỷ số bằng bộ đếm `ScoreStepper` (+/-), không gõ số.
- **Chỉ light mode.** Không làm dark mode cho beta.
- Micro-interaction vui (confetti / bounce nhẹ) khi có hành động tích cực (like, lên điểm, accept ghép kèo).
