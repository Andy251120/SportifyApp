# SCHEMA.md — Tham chiếu Database (Supabase project: SportSuperApp)

Nguồn sự thật duy nhất về cấu trúc DB. Nếu code Dart model không khớp file này, sửa theo file này (đây là schema thật đã deploy).

`sport_type` enum: `tennis` | `pickleball`

## profiles
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | = auth.users.id |
| full_name | text | |
| avatar_url | text | |
| cover_url | text | |
| location_district | text | |
| trust_score | int, default 100 | **chỉ service_role sửa được** |
| current_mode | sport_type, default 'tennis' | tab đang xem, KHÔNG giới hạn user chỉ chơi 1 môn |
| is_verified | bool, default false | **chỉ service_role sửa được** |
| updated_at | timestamptz | |

RLS: SELECT cho mọi user đã đăng nhập. INSERT/UPDATE chỉ chính chủ (`id = auth.uid()`).

## sport_stats
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| profile_id | uuid FK → profiles | |
| sport | sport_type | |
| rating | float8, default 0 | Elo. `0` = chưa có điểm (sentinel); rating engine coi `null`/`0` là baseline **1000** khi tính. **Client không sửa được** — chỉ rating engine (Phase 2) hoặc `service_role`. |
| skill_matrix | jsonb, default `{"spin":0,"power":0,"speed":0,"mental":0,"stamina":0,"technique":0}` | dữ liệu cho radar chart Show-off, thang 0–100 — client TỰ SỬA ĐƯỢC (chỉ số cá nhân hóa, khác rating) |
| titles | text[] | |
| matches_played | int, default 0 | **chỉ rating engine sửa được** |

- UNIQUE `(profile_id, sport)` — constraint `sport_stats_profile_id_sport_key`.
- RLS: SELECT public (authenticated). INSERT/UPDATE chỉ chính chủ — nhưng `rating`/`matches_played` bị trigger `enforce_sport_stats_update_rules` chặn trừ khi update lồng từ rating engine (`pg_trigger_depth() >= 2`) hoặc `service_role`.

## Rating engine (Phase 2)

Trigger `trg_apply_rating_on_confirm` (AFTER UPDATE `matches` WHEN `status` chuyển sang `confirmed`) → `apply_rating_on_match_confirmed()`:
- Elo. **Điểm gốc = `sport_stats.rating` HIỆN TẠI tại thời điểm xác nhận** (baseline 1000 khi `null`/`0`), KHÔNG dùng snapshot `match_participants.rating_before` lúc tạo trận — nhờ vậy nhiều trận `pending` của cùng một người cộng dồn đúng theo thứ tự được xác nhận. Phép cộng dồn nằm trong `ON CONFLICT DO UPDATE` (khoá row) → an toàn với xác nhận đồng thời.
- K thích ứng: **32** cho 10 trận đầu của mỗi người/môn, sau đó **24**.
- Đôi: kỳ vọng thắng tính theo điểm trung bình đội (avg điểm gốc), delta áp giống nhau cho 2 người cùng đội (K riêng từng người).
- Cập nhật `sport_stats.rating` + `matches_played` (upsert theo `(profile_id, sport)`); ghi `match_participants.rating_before` = điểm gốc thật sự đã dùng + `rating_after` = điểm sau trận.
- Áp cho cả xác nhận thủ công lẫn auto-confirm (pg_cron). `disputed` KHÔNG đổi rating. Score không parse được / phi số / hoà set → bỏ qua (RAISE NOTICE).

## matches
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| sport | sport_type | |
| match_type | text | `singles` \| `doubles` |
| score | jsonb | tự định dạng, ví dụ `[{"a":6,"b":4},{"a":6,"b":3}]` |
| status | text | `pending_confirmation` \| `confirmed` \| `disputed` \| `cancelled` |
| reported_by | uuid FK → profiles | |
| confirmed_by | uuid FK → profiles, nullable | |
| club_id | uuid FK → clubs, nullable | |
| played_at | timestamptz | |
| reported_at | timestamptz | mốc tính auto-confirm 24h |
| auto_confirmed | bool | true nếu hệ thống tự confirm |

**KHÔNG insert trực tiếp — dùng RPC `create_match`.**
Sửa `score`: chỉ `reported_by`, chỉ khi chưa `confirmed` (tự động reset về `pending_confirmation`). Đổi `status` → `confirmed`/`disputed`: không được là chính `reported_by`.

RLS SELECT/UPDATE `matches` + SELECT `match_participants`/`match_officials`: dùng helper `private.uid_in_match_participants(match_id)` / `private.uid_in_match_officials(match_id)` (SECURITY DEFINER, bỏ qua RLS) để tránh đệ quy vô hạn giữa policy của `matches` ↔ `match_participants`. Ai xem được trận thì xem được **toàn bộ** participant/official của trận đó.

## match_participants
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| match_id | uuid FK → matches | |
| profile_id | uuid FK → profiles | |
| side | text | `a` \| `b` |
| rating_before | float8 | `create_match` ghi tạm = `sport_stats.rating` lúc tạo trận; rating engine ghi đè = điểm gốc thật sự đã dùng khi trận `confirmed` |
| rating_after | float8 | điểm sau trận, ghi bởi rating engine khi `confirmed` |

## match_officials
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| match_id | uuid FK → matches | |
| profile_id | uuid FK → profiles | |
| role | text | `referee` \| `coach` \| `other` |

Người có mặt trong bảng này được confirm/dispute trận nhưng KHÔNG sửa được `score`.

## availability
| profile_id, sport, day_of_week (0-6), start_time, end_time |

## match_requests
| id, sport, creator_id, status (`open`\|`matched`\|`cancelled`), preferred_date, min_rating, max_rating, district, note |

## match_request_responses
| id, match_request_id, responder_id, status (`pending`\|`accepted`\|`declined`) |

**Accept dùng RPC `accept_match_request_response(p_response_id)`** — không tự update status='accepted' trực tiếp.

## posts / post_likes / post_comments
- `posts`: id, author_id, content, image_urls (text[]), sport (nullable), club_id (nullable), match_id (nullable — để gắn kết quả trận vào bài đăng)
- `post_likes`: post_id, profile_id (PK ghép)
- `post_comments`: id, post_id, author_id, content

RLS: SELECT mọi user đăng nhập. Sửa/xóa chỉ tác giả.

## clubs / club_members
- `clubs`: id, name, sport, logo_url, owner_id, description
- `club_members`: club_id, profile_id, role (`member`\|`admin`), joined_at

Tạo club → chủ club tự động thành admin trong `club_members` (trigger tự động, không cần tự insert).

## courts / court_reviews
- `courts`: id, name, address, district, latitude, longitude, sports (sport_type[]), phone, photos (text[]), added_by
- `court_reviews`: id, court_id, profile_id, rating (1-5), comment

## device_tokens
| id, profile_id, device_token, platform (`ios`\|`android`) | — riêng tư, chỉ chính chủ đọc/ghi |

## RPC Functions

```
create_match(
  p_sport sport_type,
  p_match_type text,        -- 'singles' | 'doubles'
  p_side_a_ids uuid[],       -- 1 người (singles) hoặc 2 người (doubles)
  p_side_b_ids uuid[],
  p_score jsonb default null,
  p_played_at timestamptz default now(),
  p_club_id uuid default null
) returns uuid   -- match_id

accept_match_request_response(p_response_id uuid) returns uuid   -- match_request_id
```

Cả 2 chỉ gọi được khi đã đăng nhập (`authenticated`), không gọi được ở trạng thái `anon`.

## Scheduled job

`pg_cron` job `auto_confirm_matches` chạy mỗi giờ: tự confirm các `matches` có `status='pending_confirmation'` và `reported_at` quá 24h.