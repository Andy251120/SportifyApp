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
| rating | float8, default 0 | **chỉ service_role sửa được (rating engine, chưa tồn tại)** |
| skill_matrix | jsonb, default `{"spin":0,"power":0,"speed":0,"mental":0,"stamina":0,"technique":0}` | dữ liệu cho radar chart Show-off — client TỰ SỬA ĐƯỢC (đây là chỉ số cá nhân hóa, khác rating) |
| titles | text[] | |
| matches_played | int, default 0 | **chỉ service_role sửa được** |

RLS: SELECT public (authenticated). INSERT/UPDATE chỉ chính chủ — nhưng cột `rating`/`matches_played` bị chặn ở tầng trigger dù có quyền UPDATE bảng.

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

## match_participants
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | uuid PK | |
| match_id | uuid FK → matches | |
| profile_id | uuid FK → profiles | |
| side | text | `a` \| `b` |
| rating_before | float8 | snapshot lúc tạo match |
| rating_after | float8 | ghi bởi rating engine (chưa tồn tại) |

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