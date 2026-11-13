# THIẾT KẾ LƯU TRỮ LOCAL — DRIFT + SQLITE

## 1. Mục tiêu

Ứng dụng dùng Drift + SQLite làm nguồn dữ liệu khi chạy. Người dùng có thể tạo, sửa, sao chép và xóa CV khi không có mạng. Supabase là backend để xác thực, sao lưu và đồng bộ giữa các thiết bị; giao diện không gọi Supabase trực tiếp.

Nguyên tắc chính:

1. Ghi dữ liệu xuống local trước.
2. Thay đổi local của tài khoản được đánh dấu `isSynced = false`.
3. Lớp đồng bộ sẽ đẩy các bản ghi đang chờ lên Supabase khi đủ điều kiện.
4. Chỉ đánh dấu `isSynced = true` sau khi Supabase xác nhận thành công.

## 2. Cấu trúc dữ liệu

### `local_cvs`

Mỗi hàng chứa:

- `id`: UUID duy nhất của CV.
- `userId`: tài khoản sở hữu; để trống đối với Guest.
- `title`, `templateId`: metadata thường dùng để hiển thị và sắp xếp.
- `payloadJson`: toàn bộ nội dung CV ở dạng JSON.
- `isSynced`: trạng thái đã được cloud xác nhận hay chưa.
- `createdAt`, `updatedAt`: thời gian UTC.

Cách lưu kết hợp metadata và JSON giúp Dashboard truy vấn nhanh, đồng thời tránh phải tạo quá nhiều bảng con khi cấu trúc CV còn tiếp tục phát triển. Khi đọc dữ liệu, metadata trong cột là nguồn chính cho các trường tương ứng.

### `pending_cv_deletions`

Bảng này là hàng đợi xóa trên cloud, gồm `cvId`, `userId` và `deletedAt`.

- Xóa CV của tài khoản: tạo một bản ghi chờ xóa rồi xóa CV local trong cùng transaction.
- Xóa CV Guest: chỉ xóa local vì CV chưa tồn tại trên Supabase.
- Sau khi Supabase xác nhận đã xóa, lớp đồng bộ gọi `confirmDeletionSynced` để bỏ bản ghi khỏi hàng đợi.

Cơ chế này tránh trường hợp người dùng xóa CV khi offline nhưng ứng dụng không còn thông tin để xóa bản cloud khi có mạng trở lại.

## 3. Repository

Giao diện ứng dụng sử dụng `CvRepository`, không phụ thuộc trực tiếp vào Drift. `LocalCvRepository` hiện hỗ trợ:

- Theo dõi hoặc lấy danh sách CV theo thời gian cập nhật mới nhất.
- Lấy một CV theo ID.
- Lưu thay đổi local và tự động đặt trạng thái chưa đồng bộ.
- Lưu snapshot từ cloud mà không biến nó thành thay đổi local mới.
- Sao chép CV với ID mới.
- Lấy các CV và yêu cầu xóa đang chờ đồng bộ của một tài khoản.
- Đánh dấu CV đã đồng bộ hoặc xác nhận xóa cloud đã hoàn tất.

Khi nhận dữ liệu từ Supabase, phải gọi:

```dart
repository.save(
  cloudCv,
  markAsLocalChange: false,
);
```

Nếu không truyền tùy chọn này, thao tác lưu được xem là chỉnh sửa của người dùng và CV sẽ quay về trạng thái chưa đồng bộ.

## 4. Vòng đời cơ sở dữ liệu

- Tên file cơ sở dữ liệu: `smart_cv_maker.sqlite` do `drift_flutter` quản lý.
- Phiên bản schema hiện tại: `2`; migration từ v1 bổ sung bảng hàng đợi xóa mà không làm mất CV.
- `appDatabaseProvider` tạo một database cho ứng dụng và đóng kết nối khi provider bị hủy.
- Mọi thay đổi schema sau này phải tăng `schemaVersion` và thêm migration; không xóa dữ liệu người dùng để xử lý lỗi migration.

## 5. Phạm vi đã và chưa hoàn thành

Đã hoàn thành:

- Schema Drift và mã sinh tự động.
- Repository local-first.
- Lưu bền vững sau khi đóng và mở lại SQLite.
- Lọc thay đổi theo tài khoản.
- Hàng đợi xóa cloud.
- Dashboard và Editor đọc/ghi qua repository.
- Đồng bộ hai chiều với Supabase theo `updatedAt` UTC.
- Xử lý hàng đợi xóa và xung đột theo quy tắc bản mới hơn thắng.
- Kiểm thử cho các hành vi trên.

Chưa hoàn thành:

- Chưa có debounce để tự động lưu khi nhập liệu.
- Chưa có background retry worker tự chạy khi mạng trở lại.
- Chưa xử lý merge chi tiết theo từng section; MVP dùng toàn bộ snapshot mới hơn.

## 6. Bước tiếp theo

1. Thêm auto-save có debounce; luôn chờ thao tác ghi local hoàn tất.
2. Theo dõi trạng thái kết nối để tự thử lại khi mạng trở lại.
3. Kiểm thử đồng bộ giữa hai thiết bị thật với thời gian UTC.
4. Bổ sung telemetry/log chẩn đoán không chứa nội dung CV nhạy cảm.
