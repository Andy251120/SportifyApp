# Supabase

- `SCHEMA.md` là **nguồn sự thật duy nhất** về cấu trúc DB (bảng, cột, RLS, RPC, trigger, rating engine). Model Dart lệch file này thì sửa Dart theo file.
- URL + anon/publishable key nằm trong `.env` ở root. **Không commit `.env`** (đã có trong `.gitignore`).
- MCP `claude.ai Supabase` (connector theo account) dùng cho mọi thao tác DB: `list_tables`, `execute_sql` (đọc), `apply_migration` (DDL), `get_advisors`. Nếu MCP rớt: restart Claude Code, hoặc user cấp Personal Access Token tạm cho Management API.

## RLS nghiêm ngặt — cột client KHÔNG ghi được

- `sport_stats.rating`, `sport_stats.matches_played` — chỉ rating engine (trigger `apply_rating_on_match_confirmed`, chạy lồng ở `pg_trigger_depth() >= 2`) hoặc `service_role`.
- `profiles.trust_score`, `profiles.is_verified` — chỉ `service_role`.
- Cố UPDATE các cột này từ client sẽ bị trigger raise exception — **đây là chủ đích, không phải bug**.

## Bắt buộc dùng RPC (không INSERT/UPDATE trực tiếp)

- Tạo trận: **luôn** `rpc('create_match', ...)` — tạo `matches` + `match_participants` atomic.
- Accept lời mời ghép kèo: **luôn** `rpc('accept_match_request_response', ...)` — cần atomic decline các response khác + đóng request.
- Xác nhận/từ chối trận (`matches.status` → `confirmed`/`disputed`): UPDATE trực tiếp được (RLS + trigger `enforce_match_update_rules` lo phần luật: người báo cáo không tự xác nhận).

## Khi thêm migration

- Đặt tên snake_case rõ nghĩa. Hàm trigger nội bộ: `SECURITY DEFINER` + `set search_path` + **revoke execute khỏi `anon`/`authenticated`** (giống các hàm sẵn có).
- Sau `apply_migration` chạy `get_advisors(type: security)`, không để phát sinh cảnh báo mới.
- Cập nhật `SCHEMA.md` cho khớp.
