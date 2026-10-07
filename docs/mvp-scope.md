# PHẠM VI MVP SMART CV MAKER MOBILE

- Trạng thái: Đã thống nhất
- Ngày xác nhận: 06/10/2026
- Thành viên: Nguyễn Tuấn Anh và Nguyễn Hoàng Phong

## 1. Mục tiêu

MVP cho phép người dùng tạo, chỉnh sửa, lưu, xem trước, xuất và chia sẻ CV trên điện thoại. Luồng cốt lõi phải hoạt động khi không có Internet; Supabase bổ sung tài khoản và đồng bộ sau khi chức năng local đã ổn định.

## 2. Chức năng bắt buộc

### Tài khoản

- Sử dụng ứng dụng không cần đăng nhập bằng Guest Mode.
- Đăng ký và đăng nhập bằng email, mật khẩu.
- Yêu cầu đặt lại mật khẩu.
- Hỏi người dùng trước khi chuyển CV Guest sang tài khoản.

### Quản lý và chỉnh sửa CV

- Xem trạng thái trống và danh sách CV.
- Tạo, mở, đổi tên, sao chép và xóa CV.
- Nhập thông tin cá nhân, tóm tắt, học vấn, kinh nghiệm, kỹ năng và dự án.
- Tự động lưu vào Drift + SQLite.
- Tiếp tục chỉnh sửa khi mất mạng hoặc khởi động lại ứng dụng.

### Template và tài liệu

- Hai template: Harvard ATS và Modern Minimalist.
- Preview dùng dữ liệu thật của CV đang chọn.
- Xuất PDF A4 đọc được tiếng Việt và không cắt mất nội dung.
- Chia sẻ PDF qua System Share Sheet của Android/iOS.

### Cloud

- Supabase Auth, PostgreSQL và Row-Level Security.
- Đồng bộ CV của người dùng đã đăng nhập sau khi luồng local ổn định.
- Lỗi mạng hoặc lỗi Supabase không được làm mất dữ liệu local.

## 3. Ngoài phạm vi MVP

- Gemini AI viết lại Summary, Bullet Enhancer và ATS Scoring.
- Nhập CV từ PDF hoặc Word.
- Template thứ ba và thứ tư.
- Đồng bộ xung đột phức tạp giữa nhiều thiết bị.
- Đa ngôn ngữ giao diện.
- Web Admin, tuyển dụng, thanh toán hoặc mạng xã hội nghề nghiệp.

Các mục này chỉ được mở lại sau khi luồng cốt lõi vượt qua kiểm thử nghiệm thu.

## 4. Ngôn ngữ và nền tảng

- Giao diện MVP: tiếng Việt.
- Nền tảng kiểm thử chính: Android.
- Mã nguồn Flutter phải giữ khả năng tương thích iOS.
- Chưa bắt buộc build hoặc phát hành iOS nếu nhóm không có máy macOS phù hợp.

## 5. Thứ tự triển khai

1. Khảo sát, user flow, wireframe và kiến trúc.
2. UI/UX và cấu trúc dữ liệu local.
3. Form, state management và auto-save.
4. Preview, hai template và PDF.
5. Supabase Auth, schema, RLS và đồng bộ.
6. Kiểm thử, sửa lỗi và đóng gói Android.
7. Chỉ xem xét AI sau khi hoàn thành các bước trên.

## 6. Quy tắc kiểm soát phạm vi

Một tính năng ngoài tài liệu này không được đưa vào sprint chỉ vì đã có thư viện hoặc API sẵn. Trước khi mở rộng phạm vi, nhóm phải ghi rõ giá trị, chi phí, rủi ro và hạng mục cốt lõi nào đã hoàn thành.

Drift + SQLite được xây dựng trong tuần 5 được ghi nhận là PoC kiểm chứng lựa chọn công nghệ. Việc kết nối Dashboard, Editor và auto-save thuộc giai đoạn triển khai sau khi hoàn thành tài liệu kiến trúc và wireframe.
