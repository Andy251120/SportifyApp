# Workflow theo Phase

## Thứ tự Phase (làm đúng thứ tự, không nhảy cóc)

0. **Setup** — project, Supabase, auth OTP số điện thoại, CI. ✅ xong
1. **Hồ sơ & Show-off** — tab Tennis/Pickleball, tự đánh giá điểm trình (skill_matrix 0–100), radar chart, avatar. ✅ xong
2. **Trận đấu & Rating engine** — ghi/xác nhận kết quả + Elo engine ở Supabase. ✅ code + migration xong
3. **Ghép kèo** — `match_requests`, `availability`.
4. **Feed cộng đồng** — posts, likes, comments (+ clubs).
5. **Danh sách sân** — `google_maps_flutter`.
6. **Push notification thật.**
7. **Beta hardening & launch nội bộ.**

## Nguyên tắc

- Làm xong 1 Phase → **dừng lại**, tóm tắt việc đã làm + checklist user verify thủ công, chờ review. Không code dồn nhiều Phase.
- Blocker cần cấu hình ngoài (Supabase Dashboard: bật OTP provider, tạo Storage bucket, thêm số điện thoại test; GitHub Secrets) — **dừng và nói user làm**, không tự đoán cách bypass, không mock để lách.
- Kết thúc Phase: `flutter analyze` + `flutter test` xanh, commit, push. Nếu cần verify trên app thật thì nói rõ user cần làm gì.

## Việc user tự làm (Claude Code không có quyền)

- Bật Auth provider số điện thoại (OTP) + cấu hình số điện thoại test trong Supabase Dashboard.
- Tạo Storage bucket (avatars...) — hoặc nhờ chạy SQL qua MCP.
- Thêm GitHub Secrets, tạo repo remote.
