# CLAUDE.md — Rally (Tennis & Pickleball, beta Đà Nẵng)

Đọc toàn bộ rule trước khi code bất cứ gì:

@.claude/rules/product-overview.md
@.claude/rules/tech-stack.md
@.claude/rules/architecture.md
@.claude/rules/supabase.md
@.claude/rules/design-direction.md
@.claude/rules/testing-and-ci.md
@.claude/rules/workflow.md

Tham chiếu chi tiết (không nhét vào rule vì dài & thay đổi liên tục):
- `SCHEMA.md` — cấu trúc database (nguồn sự thật).
- `UI_SPEC.md` — đặc tả UI từng màn đã duyệt (từ Phase 1). Implement đúng theo file, không tự đoán layout.
- `PROJECT_STRUCTURE.md` — cây thư mục đầy đủ.

## Orchestration: Implement → Review loop

Khi nhận yêu cầu code một tính năng mới hoặc sửa lỗi, LUÔN điều phối theo quy trình sau.
KHÔNG tự viết code trực tiếp — phải giao việc qua 2 subagent: `implement` và `review`.

### Quy trình
1. Xác định phạm vi task rõ ràng: file/hàm/module nào cần đụng tới.
2. Gọi subagent `implement`, giao đúng phạm vi đã xác định ở bước 1.
   Không giao mô tả mơ hồ — càng cụ thể, implement càng ít lệch phạm vi.
3. Sau khi `implement` trả kết quả, gọi subagent `review` với diff/code vừa tạo
   (chỉ truyền phần thay đổi, không truyền toàn bộ lịch sử hội thoại).
4. Đọc kết quả `review`:
   - Nếu `pass: true` → task hoàn thành, báo cáo tóm tắt cho user.
   - Nếu `pass: false` → gọi lại `implement`, kèm theo `issues` từ review làm
     ngữ cảnh sửa lỗi. Tăng biến đếm vòng lặp lên 1.
5. Lặp lại bước 3–4 tối đa **2 lần sửa** (tổng cộng tối đa 3 lần implement cho 1 task).
6. Nếu sau 2 lần sửa mà `review` vẫn trả `pass: false`:
   - DỪNG LẠI ngay, không tự ý thử thêm lần nữa.
   - Báo cáo cho user: task đang vướng gì, review đang chê lỗi gì, và hỏi
     hướng xử lý tiếp theo (đổi cách tiếp cận / cần thêm thông tin / bỏ qua lỗi này).

### Ràng buộc bắt buộc
- `implement` và `review` KHÔNG được gọi lẫn nhau trực tiếp. Mọi điều phối
  đi qua orchestrator (agent chính) — đúng nguyên tắc hub-and-spoke.
- `review` chỉ có quyền đọc và chạy test, không có quyền Edit/Write.
  Không bao giờ để `review` tự sửa code nó đang kiểm tra.
- Mỗi lần gọi `implement` sau vòng review fail, chỉ truyền phần `issues`
  liên quan + code hiện tại, không truyền lại toàn bộ lịch sử các lần thử trước
  (tránh phình context không cần thiết — xem thêm phần Context Management).
- Không tự động lặp vô hạn. Giới hạn số vòng là bắt buộc, không phải gợi ý.

### Định dạng review phải trả (khối JSON cuối câu trả lời — orchestrator parse khối này)
```json
{
  "pass": false,
  "summary": "1-2 câu: mức sẵn sàng của code.",
  "scope": "phase/feature hoặc danh sách file đã review",
  "tests": { "analyze": "pass", "test": "pass", "note": "" },
  "issues": [
    { "severity": "blocker", "file": "lib/features/rating/rating_service.dart", "line": 42,
      "problem": "Chưa xử lý rating âm", "fix": "Clamp về 0 trước khi tính." }
  ],
  "good": ["phần làm đúng, nếu có"]
}
```
- `pass = true` ⇔ không còn issue nào `severity: "blocker"` VÀ analyze/test xanh.
- `severity`: `blocker` | `should-fix` | `suggestion`. `issues[]` liệt kê cả 3 mức.
- Khi `pass: false` → truyền lại cho `implement` các issue `blocker` + `should-fix`
  (bỏ `suggestion`). Khi `pass: true` → báo user, kèm `should-fix`/`suggestion` còn tồn.
- Task đụng migration/RLS Supabase: `review` chỉ soi được `list_migrations` +
  `get_advisors`; phần `apply_migration` và kiểm định nghĩa hàm/policy là việc của
  hub, không giao `implement` (agent đó không có MCP).