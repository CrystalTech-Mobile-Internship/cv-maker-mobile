# HƯỚNG DẪN SUPABASE DEVELOPMENT

## 1. Trạng thái hiện tại

Repository đã có migration và test RLS dạng SQL nhưng chưa áp dụng vào project cloud. Không cần URL hoặc key để review các file này.

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
- Chạy migration: chưa thực hiện.
- Chạy `supabase test db`: chưa thực hiện vì máy chưa có Supabase local project/runtime được xác nhận.
- Kết nối Flutter với cloud: chưa thực hiện vì chưa có URL/key.

Không được ghi báo cáo rằng RLS đã hoạt động trên cloud cho đến khi test hai người dùng chạy thành công.
