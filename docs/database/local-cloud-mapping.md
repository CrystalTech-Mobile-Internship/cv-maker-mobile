# MAPPING DỮ LIỆU LOCAL VÀ CLOUD

## 1. Nguồn dữ liệu

Drift + SQLite là nguồn dữ liệu khi ứng dụng đang chạy. Supabase là bản sao cloud cho người dùng đã đăng nhập. Widget chỉ gọi repository; không gọi Supabase trực tiếp.

## 2. Mapping CV

- `local_cvs.id` ↔ `cvs.id`.
- `local_cvs.user_id` ↔ `cvs.user_id`.
- `local_cvs.title` ↔ `cvs.title`.
- `local_cvs.template_id` ↔ `cvs.template_id`.
- `local_cvs.payload_json` ↔ các cột `cvs`, `cv_sections` và `cv_items`.
- `local_cvs.created_at` ↔ `cvs.created_at`.
- `local_cvs.updated_at` ↔ `cvs.updated_at`.
- `local_cvs.is_synced` chỉ tồn tại local.
- `cvs.server_updated_at` chỉ tồn tại cloud.

Khi ghi xuống local, metadata trong các cột Drift là nguồn chính cho ID, chủ sở hữu, tiêu đề, template, trạng thái đồng bộ và thời gian. `payload_json` giữ phần dữ liệu CV đầy đủ.

Khi đẩy lên cloud, mapper tách snapshot trong `payload_json` thành metadata của
`cvs` và các item con. Không dùng giá trị `isSynced` nằm trong payload để quyết
định trạng thái cloud.

## 3. Tạo và chỉnh sửa

1. Flutter tạo UUID cho CV.
2. Repository lưu CV xuống Drift và đặt `isSynced = false`.
3. Guest dừng tại đây.
4. Người dùng đã đăng nhập được đưa vào hàng chờ đồng bộ.
5. Sync engine so sánh `updated_at` local và cloud theo UTC.
6. Bản mới hơn được giữ trong MVP.
7. Sau khi Supabase xác nhận upsert thành công, local chuyển `isSynced = true`.

`CvSyncRepository` đã triển khai quy tắc này. Danh sách cloud luôn được tải
trước khi upload để một bản local cũ không ghi đè bản mới từ thiết bị khác.

## 4. Dữ liệu Guest sau đăng nhập

Ứng dụng không tự động đổi chủ sở hữu. Sau khi người dùng đồng ý:

1. Gán `userId` hiện tại cho từng CV Guest được chọn.
2. Lưu lại local với `isSynced = false`.
3. Đồng bộ từng CV bằng cùng UUID.
4. Chỉ đánh dấu đã đồng bộ sau phản hồi thành công.

Nếu người dùng từ chối, CV Guest tiếp tục tồn tại trên thiết bị với `userId = null`.

## 5. Xóa

- Xóa CV Guest: xóa trực tiếp khỏi `local_cvs`.
- Xóa CV tài khoản: tạo hàng trong `pending_cv_deletions` và xóa CV local trong cùng transaction.
- Khi có mạng, sync engine gọi xóa `cvs.id` dưới session của người dùng.
- Lệnh xóa có tính idempotent: cloud không còn hàng vẫn được xem là hoàn thành.
- Nếu cloud được sửa sau thời điểm xóa offline, bản cloud mới hơn được phục hồi
  về máy và tombstone được xác nhận để tránh mất dữ liệu.
- Sau khi xác nhận, xóa tombstone local bằng `confirmDeletionSynced`.

## 6. Giới hạn đã biết

- Chưa kiểm thử đồng hồ hệ thống sai lệch giữa nhiều thiết bị.
- Chưa có merge theo từng section; MVP dùng bản có `updatedAt` mới hơn.
- Đã có remote datasource và sync repository nhưng chưa có background retry
  worker theo trạng thái mạng.
- RLS đã chạy trên Supabase development; vẫn cần test tự động bằng hai tài khoản.
