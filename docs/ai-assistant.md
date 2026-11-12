# Trợ lý AI tạo CV

Tất cả chức năng AI đi qua **một** Supabase Edge Function `cv-assistant`, gọi OpenRouter bằng key lưu trong Function Secrets. Ứng dụng Flutter không bao giờ chứa key AI.

```
Widget → Riverpod controller → AiAssistantRepository
  → functions.invoke('cv-assistant', {action, input})  (JWT người dùng)
    → kiểm tra JWT → kiểm tra input → trừ lượt (consume_ai_credits)
      → OpenRouter (danh sách model dự phòng) → làm sạch JSON → trả kết quả + quota
```

## Chức năng

| Action | Màn hình | Lượt | Kết quả |
| --- | --- | --- | --- |
| `interview` | Trò chuyện tạo CV (`/ai-interview`) | 1 | Câu trả lời + tiến độ |
| `generate_cv` | Nút "Tạo CV từ cuộc trò chuyện" | 3 | Bản nháp CV → hộp xem lại |
| `parse_resume` | Tải CV PDF/Word → "Bóc tách bằng AI" | 2 | Bản nháp CV → hộp xem lại |
| `improve_bullets` | Tab Kinh nghiệm → "AI viết lại gạch đầu dòng" | 1 | Gạch đầu dòng mới + gợi ý |
| `polish_summary` | Tab Thông tin → nút AI của Tóm tắt | 1 | Tóm tắt mới |
| `cover_letter` | Chấm điểm ATS → "AI viết thư xin việc" | 2 | Thư xin việc |
| `tailor_cv` | Chấm điểm ATS → "AI tối ưu CV theo JD" | 3 | Bản CV mới đã tối ưu (CV gốc giữ nguyên) |
| `interview_questions` | Luyện phỏng vấn (`/interview-practice`) | 1 | 6 câu hỏi dựa trên CV/JD |
| `answer_feedback` | Luyện phỏng vấn → "Nhận xét" | 1 | Điểm, điểm mạnh, cần cải thiện, câu trả lời mẫu |
| `quota` | — | 0 | Hạn mức hiện tại |

Kết quả AI luôn là **gợi ý**: người dùng xem lại/chỉnh sửa trước khi lưu. Khi AI lỗi, lượt đã trừ được hoàn lại; nhập CV tự động chuyển sang bộ bóc tách trên máy.

## Hạn mức Free / Pro

- Khách (chưa đăng nhập): không dùng được AI.
- Free: **15 lượt/ngày** (UTC). Pro: **200 lượt/ngày**.
- Giới hạn nằm trong `public.ai_daily_credit_limit()` (migration `20261112000200_ai_credits_and_entitlements.sql`). Client chỉ hiển thị, không tự quyết định.
- Gói Pro đọc từ `public.user_entitlements` — người dùng chỉ được đọc, không được ghi.
- Người dùng gửi yêu cầu Pro trong màn **Nâng cấp Pro** với mã chuyển khoản riêng (`CVPRO-<GÓI>-<8 ký tự đầu user id>`). Quản trị viên đối soát sao kê rồi duyệt trong SQL Editor:

```sql
select id, user_id, plan, transfer_code, created_at
from public.pro_upgrade_requests where status = 'pending' order by created_at;

select public.approve_pro_request('<request-id>');            -- monthly: +30 ngày, lifetime: vĩnh viễn
select public.reject_pro_request('<request-id>', 'Chưa nhận được chuyển khoản');
```

- Kích hoạt Pro thủ công (không qua yêu cầu):

```sql
insert into public.user_entitlements (user_id, plan, pro_until)
values ('<user-uuid>', 'pro', now() + interval '30 days')
on conflict (user_id) do update set plan = excluded.plan, pro_until = excluded.pro_until;
```

## Bảo mật & quyền riêng tư

- Key OpenRouter chỉ nằm ở `supabase secrets` (production) hoặc `supabase/functions/.env` (chạy local, đã gitignore).
- Function xác thực JWT (`verify_jwt = true` + `auth.getUser()`), giới hạn body 64 KB, giới hạn độ dài từng trường, lịch sử chat tối đa 24 lượt.
- Nội dung người dùng được bọc trong thẻ `<cv_data>`/`<user_message>` và khai báo là dữ liệu không tin cậy (chống prompt injection).
- Function chỉ log `action`, `status`, `model`, thời gian — không log nội dung CV hay token.
- Văn bản gửi đi để viết thư không kèm email/số điện thoại/địa chỉ.
- Lần đầu dùng AI, ứng dụng hiện thông báo quyền riêng tư và lưu lựa chọn trên máy.

## Mã lỗi

| HTTP | `code` | Ý nghĩa |
| --- | --- | --- |
| 401 | `unauthenticated` | Chưa đăng nhập / token sai |
| 402 | `quota_exceeded` | Hết lượt trong ngày (kèm `quota`) |
| 400/413/422 | `invalid_input` | Thiếu dữ liệu hoặc quá dài |
| 503 | `provider_unavailable` | Mọi model đều lỗi; lượt đã hoàn |
| 503 | `quota_unavailable` | Chưa áp dụng migration quota |

## Triển khai

Yêu cầu: Node.js (dùng `npx supabase`), quyền quản trị project.

```bash
npx supabase login
npx supabase link --project-ref <project-ref>
npx supabase db push                      # áp dụng migrations
npx supabase secrets set --env-file supabase/functions/.env
npx supabase functions deploy cv-assistant
```

Hoặc chạy một lệnh (sau `npx supabase login`): `./scripts/deploy_supabase.ps1 -Target secondary` — tự áp dụng migration qua Management API, đặt secret, deploy và kiểm tra.

## Kiểm thử

```bash
flutter test test/features/ai_tools
npx -y deno test supabase/functions/cv-assistant/handler_test.ts
```

Các test dùng quota và model giả, không tốn lượt OpenRouter.
