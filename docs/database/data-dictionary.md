# TỪ ĐIỂN DỮ LIỆU SUPABASE

- Trạng thái: Bản thiết kế MVP
- Ngày cập nhật: 06/10/2026
- Migration: `supabase/migrations/20261021000100_enable_offline_cloud_sync.sql`

## 1. Nguyên tắc

Guest Mode không ghi dữ liệu lên cloud. CV Guest chỉ nằm trong Drift với `userId = null`. Sau khi đăng nhập và được người dùng đồng ý, ứng dụng gắn `userId` rồi mới đồng bộ.

Cloud giữ một bản JSON đầy đủ của CV để mapping trực tiếp với `CvModel`. Các metadata thường truy vấn được tách thành cột. Cách này giữ schema MVP nhỏ, tránh phải đồng bộ nhiều bảng con trước khi form và cấu trúc CV ổn định.

## 2. Bảng profiles

### id

- Kiểu: `uuid`.
- Khóa chính và khóa ngoại tới `auth.users.id`.
- Xóa tài khoản sẽ xóa profile theo `on delete cascade`.
- RLS chỉ cho người dùng hiện tại đọc và cập nhật profile của mình.

### display_name

- Kiểu: `text`, cho phép null.
- Sau khi trim, độ dài từ 1 đến 100 ký tự nếu có giá trị.
- Giá trị ban đầu có thể lấy từ metadata lúc đăng ký.

### avatar_path

- Kiểu: `text`, cho phép null.
- Chỉ lưu đường dẫn object trong Supabase Storage, không lưu URL có chữ ký.
- Storage bucket chưa được tạo trong migration đầu tiên.

### created_at và updated_at

- Kiểu: `timestamptz`.
- Lưu thời gian UTC do PostgreSQL quản lý.

## 3. Bảng cvs

### id

- Kiểu: `uuid`, khóa chính.
- UUID được tạo ở Flutter trước khi lưu local.
- Cùng một ID được dùng trong Drift, route, Supabase và PDF workflow.

### user_id

- Kiểu: `uuid`, bắt buộc.
- Khóa ngoại tới `auth.users.id`, `on delete cascade`.
- Mặc định lấy từ `auth.uid()`.
- Có index riêng vì mọi policy và truy vấn danh sách đều lọc theo cột này.

### title

- Kiểu: `text`, bắt buộc.
- Sau khi trim, độ dài từ 1 đến 160 ký tự.

### template_id

- Kiểu: `text`, bắt buộc.
- Nhận một trong bốn giá trị MVP: `harvard_ats`, `modern_minimalist`, `minimalist_clean` hoặc `creative_tech`.

### payload

- Kiểu: `jsonb`, bắt buộc và phải là JSON object.
- Chứa toàn bộ dữ liệu do `CvModel.toJson()` tạo ra.
- Không dùng `isSynced` trên cloud để quyết định trạng thái local.

### created_at và updated_at

- Kiểu: `timestamptz`, bắt buộc.
- Nhận thời gian UTC từ dữ liệu local.
- `updated_at` dùng cho chiến lược xung đột MVP: bản cập nhật mới hơn thắng.
- `created_at` không được sau `updated_at`.

### server_updated_at

- Kiểu: `timestamptz`, bắt buộc.
- PostgreSQL tự cập nhật khi một hàng cloud thay đổi.
- Dùng cho quan sát/debug đồng bộ; không thay thế `updated_at` của nội dung.

## 4. Phân quyền

- `anon`: không có quyền bảng `profiles` hoặc `cvs`.
- `authenticated`: chỉ có các quyền cần thiết và vẫn bị lọc bởi RLS.
- `profiles`: người dùng được đọc/cập nhật hàng có `id = auth.uid()`.
- `cvs`: người dùng được đọc/thêm/sửa/xóa hàng có `user_id = auth.uid()`.
- `service_role` hoặc secret key không được đưa vào Flutter hay Git.

## 5. Chưa thuộc migration này

- Storage bucket cho avatar hoặc PDF.
- Bảng AI hoặc quota AI.
- Chia sẻ CV công khai.
- Lịch sử phiên bản CV.
