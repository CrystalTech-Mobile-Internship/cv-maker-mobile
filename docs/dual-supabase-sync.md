# Đồng bộ dữ liệu giữa 2 Supabase project

Ứng dụng cấu hình hai project (`primary`, `secondary`). Mỗi lần chạy app chỉ dùng **một** project (Auth/JWT/user id khác nhau giữa hai project), nhưng dữ liệu CV được giữ đồng bộ ở cả hai theo ba lớp:

```
            ┌──────────── mirror-sync (pg_cron, 5 phút) ────────────┐
            ▼                                                       │
   Project PRIMARY  ◄──── mirror-sync (pg_cron, 5 phút) ────  Project SECONDARY
            ▲                                                       ▲
            │ sync khi đăng nhập                                    │ sync khi đăng nhập
            └──────────────  SQLite trên thiết bị (nguồn chính)  ───┘
```

## 1. Thiết bị là trung tâm (đã có)

Drift/SQLite là nguồn dữ liệu chính. CV dùng UUID ổn định nên khi đẩy lên project nào cũng giữ nguyên id.

## 2. Chọn project và chuyển dự phòng khi khởi động

- `SUPABASE_ACTIVE_PROFILE` chọn project ưu tiên.
- Lúc khởi động, app gọi `/auth/v1/health` (timeout 3 giây). Nếu project ưu tiên không phản hồi và project còn lại phản hồi, app dùng project còn lại cho **cả phiên** và hiển thị nhãn "(dự phòng)".
- Nếu cả hai đều không phản hồi (mất mạng), app giữ project ưu tiên để phiên đăng nhập cũ vẫn hợp lệ khi có mạng lại.
- Tắt bằng `SUPABASE_FAILOVER=off`.

Mã: `lib/core/network/supabase_profile_resolver.dart`.

## 3. Nhận lại CV khi đổi project

Cùng một email có user id khác nhau ở hai project. Khi đăng nhập, `LinkedAccountCvAdopter` ghi nhớ (user id → email) trên thiết bị và chuyển các CV local thuộc user id cũ **cùng email** sang tài khoản hiện tại (giữ nguyên `updated_at`, đánh dấu chưa đồng bộ). CV Guest không bị đụng tới.

## 4. Mirror phía server (`mirror-sync`)

Edge Function triển khai trên **mỗi** project, trỏ tới project kia:

1. Đọc CV có `updated_at` > checkpoint (100 bản ghi/lần, cũ trước).
2. Ghép người dùng theo **email đã xác thực**; nếu project đích chưa có tài khoản, tạo tài khoản không mật khẩu (người dùng đăng nhập Google hoặc "Quên mật khẩu").
3. Bỏ qua nếu nội dung giống hệt bản đích (chống ghi qua lại vô hạn); bỏ qua nếu bản đích mới hơn (Last-Write-Wins).
4. Đồng bộ lệnh xóa qua bảng `cv_deletions` (trigger); không xóa nếu bản đích được sửa sau thời điểm xóa.
5. Lỗi ở một bản ghi → dừng, giữ checkpoint để chạy lại lần sau (idempotent).

Migration: `supabase/migrations/20261112000300_dual_project_mirror.sql`. Test: `npx -y deno test supabase/functions/mirror-sync/mirror_test.ts`.

### Secrets (mỗi project)

| Secret | Giá trị |
| --- | --- |
| `MIRROR_SUPABASE_URL` | URL của project **kia** |
| `MIRROR_SERVICE_ROLE_KEY` | service-role / secret key của project **kia** |
| `MIRROR_CRON_SECRET` | chuỗi ngẫu nhiên dài, chỉ dùng cho cron |
| `MIRROR_TARGET_NAME` | `primary` hoặc `secondary` (tên project đích) |

Service-role key **chỉ** được đặt trong Function Secrets, không bao giờ trong `.env` của Flutter.

```bash
npx supabase secrets set --project-ref <ref> MIRROR_SUPABASE_URL=... MIRROR_SERVICE_ROLE_KEY=... MIRROR_CRON_SECRET=... MIRROR_TARGET_NAME=secondary
npx supabase functions deploy mirror-sync --project-ref <ref> --no-verify-jwt
```

### Lịch chạy (SQL Editor của mỗi project)

```sql
create extension if not exists pg_cron;
create extension if not exists pg_net;

select vault.create_secret('<MIRROR_CRON_SECRET>', 'mirror_cron_secret');

select cron.schedule(
  'mirror-sync-every-5-min',
  '*/5 * * * *',
  $$
  select net.http_post(
    url := 'https://<this-project-ref>.supabase.co/functions/v1/mirror-sync',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-mirror-secret',
      (select decrypted_secret from vault.decrypted_secrets
       where name = 'mirror_cron_secret')
    ),
    body := '{}'::jsonb
  );
  $$
);
```

## Giới hạn đã biết

- Mirror đồng bộ CV và lệnh xóa; hạn mức AI và bài đăng cộng đồng thuộc project đang chạy (không cần mirror).
- Xung đột sửa cùng lúc trên hai project trong cùng chu kỳ 5 phút được giải bằng Last-Write-Wins.
- Hiện project primary trong `.env` không phân giải được DNS (có thể đã bị xóa/tạm dừng): app sẽ dùng secondary. Cần khôi phục hoặc tạo lại primary trước khi bật mirror hai chiều.
