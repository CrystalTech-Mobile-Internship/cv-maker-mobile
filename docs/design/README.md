# THIẾT KẾ GIAO DIỆN SMART CV MAKER MOBILE

- Ngày review: 07/10/2026
- Công cụ thiết kế: Google Stitch
- Nền tảng ưu tiên: Android
- Trạng thái: Wireframe đã đủ cho giai đoạn thiết kế tuần 5

## 1. Nguồn thiết kế

- Project Stitch: <https://stitch.withgoogle.com/projects/12690341350869870212>
- Wireframe giai đoạn đầu: `docs/design/wireframes/` (giao diện thật xem ảnh trong `docs/images/`)
- Đặc tả giao diện: `docs/design/ui-specification.md`

## 2. Danh sách ảnh

| File | Nội dung |
| --- | --- |
| `01-login-guest.png` | Đăng nhập và tiếp tục ở chế độ Khách |
| `02-register.png` | Đăng ký tài khoản và validation |
| `03-forgot-password.png` | Yêu cầu đặt lại mật khẩu |
| `04-dashboard-empty.png` | Dashboard khi chưa có CV |
| `05-dashboard-list.png` | Dashboard có danh sách CV |
| `06-cv-editor.png` | Editor phần thông tin cá nhân |
| `07-cv-preview.png` | Chọn template, xem trước và xuất PDF |
| `08-editor-offline.png` | Editor khi không có mạng |
| `08-ui-states.png` | Loading, error, xác nhận xóa và kết quả xuất PDF |
| `09-editor-saving.png` | Editor trong lúc tự động lưu |

## 3. Quy tắc sử dụng

- Ảnh là tài liệu tham chiếu UI/UX, không phải bằng chứng tính năng đã được triển khai.
- Không sao chép HTML/CSS do Stitch sinh vào dự án Flutter.
- Khi thiết kế và yêu cầu khác nhau, `docs/requirements.md`, `docs/mvp-scope.md` và `docs/mvp-flow.md` là nguồn quyết định.
- Flutter phải tái tạo giao diện bằng Material 3, Riverpod và GoRouter theo kiến trúc dự án.
- Mọi màn hình có dữ liệu CV phải đọc theo `cvId` và dùng local repository làm nguồn dữ liệu runtime.

