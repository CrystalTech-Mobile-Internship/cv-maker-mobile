# HƯỚNG DẪN SUPABASE DEVELOPMENT

## 1. Trạng thái hiện tại

Repository đã có migration và test RLS dạng SQL. Máy phát triển đã có Project URL và anon/publishable key trong `.env`; file này bị loại khỏi Git. Chưa có bằng chứng kiểm thử trong repository để khẳng định migration và RLS đã chạy thành công trên project cloud.

Không chạy migration trên project dùng chung hoặc production trước khi hai thành viên review schema và có phương án sao lưu.

## 2. File quan trọng

- Migration: `supabase/migrations/20261006000100_create_profiles_and_cvs.sql`.
- Test RLS: `supabase/tests/cvs_rls.test.sql`.
- Data dictionary: `docs/database/data-dictionary.md`.
- Mapping local/cloud: `docs/database/local-cloud-mapping.md`.

## 3. Cách kiểm thử bằng Supabase local sau này

Supabase local cần Supabase CLI và Docker-compatible runtime. Chỉ cài khi nhóm quyết định sử dụng môi trường local.

```bash
supabase init
supabase start
supabase db reset
supabase test db
```

Kết quả bắt buộc trước khi kết nối Flutter:

- Migration chạy lại được từ database rỗng.
- Test RLS pass toàn bộ.
- User A đọc/thêm/sửa/xóa CV của User A.
- User B không đọc hoặc thay đổi CV của User A.
- Request không đăng nhập không có quyền truy cập bảng cloud.

## 4. Cấu hình project cloud sau này

1. Tạo Supabase development project, ưu tiên region gần nhóm kiểm thử.
2. Review migration trong Pull Request.
3. Liên kết CLI với đúng development project hoặc chạy migration đã review trong SQL Editor.
4. Lấy Project URL và publishable/anon client key.
5. Copy `.env.example` thành `.env` và điền hai giá trị local.
6. Không đưa database password, secret key hoặc service-role key vào `.env` của Flutter.

## 5. Trạng thái xác minh

- Kiểm tra tĩnh SQL: đã review cấu trúc, grants, RLS và policy ownership.
- Cấu hình client local: đã có URL và anon/publishable key trong `.env`; `.env` không được Git theo dõi.
- Chạy migration trên cloud: chưa được xác minh bằng log hoặc kết quả kiểm thử lưu trong repository.
- Chạy `supabase test db`: chưa thực hiện vì máy chưa có Supabase local project/runtime được xác nhận.
- Kết nối cơ bản tới Supabase Auth: đạt HTTP 200 khi gọi read-only `/auth/v1/settings` bằng URL và anon/publishable key trong `.env` ngày 09/10/2026.
- Kết nối Flutter và thao tác database: chưa có integration test xác nhận; kết quả HTTP 200 ở trên không chứng minh migration hoặc RLS đã hoạt động.

Không được ghi báo cáo rằng RLS đã hoạt động trên cloud cho đến khi test hai người dùng chạy thành công.
