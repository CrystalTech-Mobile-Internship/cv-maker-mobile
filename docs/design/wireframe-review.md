# REVIEW WIREFRAME VÀ BACKLOG THIẾT KẾ

- Ngày review: 07/10/2026
- Kết luận: Đủ phạm vi thiết kế ngày 3 tuần 5; chưa phải prototype đầy đủ để triển khai toàn bộ MVP

## 1. Phạm vi đã đạt

- Luồng đăng nhập, đăng ký, quên mật khẩu và Guest Mode.
- Dashboard ở trạng thái trống và có dữ liệu.
- Editor thông tin cá nhân với saving/offline state.
- Preview, lựa chọn hai template và hành động xuất/chia sẻ PDF.
- Loading, lỗi có thể phục hồi, xác nhận xóa và kết quả xuất PDF.
- Visual direction nhất quán, phù hợp ứng dụng Android và khả thi với Flutter Material 3.

## 2. Điểm cần sửa khi triển khai Flutter

1. Bỏ Google và LinkedIn Sign-In khỏi màn hình đăng ký vì ngoài phạm vi MVP.
2. Đổi mọi tiêu đề tiếng Anh như `CV Preview` thành tiếng Việt.
3. Dùng tên template chuẩn `Harvard ATS` và `Modern Minimalist`.
4. Không dùng các cam kết chưa được triển khai như mã hóa cục bộ 256-bit hoặc tự động nhận diện khuôn mặt.
5. Không hiển thị đồng bộ cloud cho Guest Mode.
6. Không xem nội dung CV mẫu trong ảnh là dữ liệu production.

## 3. Màn hình cần bổ sung ở tuần 6

### Ưu tiên cao

- Splash/Bootstrap: khởi tạo local database, Supabase tùy chọn và session.
- Tạo CV mới: đặt tên, tạo `cvId`, chọn template mặc định và ghi local.
- Form Mục tiêu nghề nghiệp.
- Form Học vấn dạng danh sách nhiều mục.
- Form Kinh nghiệm dạng danh sách nhiều mục.
- Form Kỹ năng dạng tag.
- Form Dự án dạng danh sách nhiều mục.
- Trạng thái không tìm thấy CV theo `cvId`.

### Cần trước khi hoàn thành MVP

- Thư viện hai template từ tab `Mẫu CV`.
- Tài khoản/cài đặt từ tab `Tài khoản`.
- Hỏi đồng bộ CV Guest sau khi đăng nhập.
- Đổi tên, sao chép và xác nhận xóa CV.
- Lỗi đăng nhập, lỗi local save và lỗi sync cụ thể.
- Trạng thái gửi email đặt lại mật khẩu thành công.

## 4. Trình tự chuyển từ thiết kế sang code

1. Chốt route và contract `cvId`.
2. Kết nối Dashboard với repository local.
3. Tạo CV mới và mở đúng Editor.
4. Xây từng section form với validation và autosave local.
5. Cho Preview đọc dữ liệu thật từ local repository.
6. Hoàn thiện hai template và PDF.
7. Sau khi local ổn định mới tích hợp Supabase Auth và đồng bộ.

## 5. Tiêu chí chấp thuận thiết kế

- [x] Có Guest Mode.
- [x] Có đăng ký và quên mật khẩu.
- [x] Có Dashboard empty/list.
- [x] Có Editor, Preview và hai lựa chọn template.
- [x] Có loading, offline, saving, error và confirm delete.
- [x] Có kết quả xuất PDF thành công/thất bại.
- [ ] Đã sửa toàn bộ nội dung ngoài phạm vi trên ảnh gốc.
- [ ] Có prototype tương tác đi qua toàn bộ luồng.
- [ ] Có thiết kế chi tiết cho năm section Editor còn lại.

