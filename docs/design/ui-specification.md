# ĐẶC TẢ GIAO DIỆN SMART CV MAKER MOBILE

- Phiên bản: Wireframe v1
- Ngày chốt: 07/10/2026
- Ngôn ngữ MVP: Tiếng Việt
- Kích thước tham chiếu: Android mobile 390 x 844 dp

## 1. Nguyên tắc trải nghiệm

1. Guest Mode luôn truy cập được khi Supabase chưa cấu hình, mất mạng hoặc đăng nhập thất bại.
2. Dữ liệu CV được lưu bằng Drift + SQLite trước khi thử đồng bộ cloud.
3. Loading, offline và lỗi cloud không được khóa thao tác chỉnh sửa local.
4. Editor và Preview luôn nhận đúng `cvId`; không sử dụng một CV mẫu toàn cục.
5. Thay đổi template không được làm thay đổi nội dung CV.
6. Thất bại khi xuất hoặc chia sẻ PDF không được làm mất dữ liệu.

## 2. Design tokens

- Primary: `#4F46E5`.
- Success: `#10B981`.
- Warning/offline: `#F59E0B`.
- Error: `#DC2626`.
- Background: `#F8FAFC` hoặc sắc tím rất nhạt tương đương.
- Main text: `#0F172A`.
- Secondary text: `#64748B`.
- Font: Inter hoặc font sans-serif hỗ trợ đầy đủ tiếng Việt.
- Spacing: bội số của 8 dp.
- Input/button radius: 12 dp.
- Card radius: 16 dp.
- Touch target tối thiểu: 48 x 48 dp.
- Nội dung phải nằm trong `SafeArea` và hỗ trợ Android gesture navigation.

## 3. Đặc tả theo màn hình

### S02 — Đăng nhập và Guest Mode

Tham chiếu: `wireframes/01-login-guest.png`.

- Nhập email và mật khẩu.
- Có liên kết đăng ký và quên mật khẩu.
- Nút `Tiếp tục không đăng nhập` luôn hiển thị.
- Lỗi xác thực hiển thị gần form và không xóa dữ liệu người dùng vừa nhập.
- Khi cloud không khả dụng, người dùng vẫn vào Dashboard bằng Guest Mode.

### S02A — Đăng ký

Tham chiếu: `wireframes/02-register.png`.

- Thu thập họ tên, email, mật khẩu và xác nhận mật khẩu.
- Validation hiển thị cạnh trường tương ứng.
- Thông báo rõ CV Guest sẽ được giữ lại và chỉ đồng bộ sau khi người dùng đồng ý.
- MVP chỉ dùng email/mật khẩu; không triển khai Google hoặc LinkedIn Sign-In.

### S02B — Quên mật khẩu

Tham chiếu: `wireframes/03-forgot-password.png`.

- Nhập email tài khoản và gửi yêu cầu đặt lại mật khẩu.
- Có trạng thái gửi thành công, gửi lại và quay lại đăng nhập.
- Không tuyên bố dữ liệu được mã hóa bằng Android Keystore nếu chưa có triển khai và kiểm thử tương ứng.

### S03 — Dashboard

Tham chiếu: `wireframes/04-dashboard-empty.png` và `wireframes/05-dashboard-list.png`.

- Trạng thái trống có CTA `Tạo CV đầu tiên`.
- Trạng thái danh sách hiển thị tên CV, thời gian cập nhật, mức hoàn thiện và trạng thái đồng bộ.
- Mỗi CV có thao tác sửa, xem trước, đổi tên, sao chép và xóa.
- `Đã lưu trên máy`, `Chưa đồng bộ` và `Đã đồng bộ` phải là ba trạng thái khác nhau.
- Không hiển thị `Đã đồng bộ` cho CV Guest.

### S04 — CV Editor

Tham chiếu: `wireframes/06-cv-editor.png`, `wireframes/08-editor-offline.png` và `wireframes/09-editor-saving.png`.

- Sáu phần: Thông tin cá nhân, Mục tiêu, Học vấn, Kinh nghiệm, Kỹ năng và Dự án.
- Thanh tiến độ chỉ mang tính hỗ trợ và không ngăn người dùng xem trước.
- Autosave có các trạng thái: `Đang lưu…`, `Đã lưu trên thiết bị`, `Chưa đồng bộ` và `Lưu thất bại`.
- Banner offline chỉ thông báo, không khóa form.
- Nút Back phải lưu thay đổi local trước khi rời màn hình.
- Ảnh chân dung chỉ nên mô tả yêu cầu tỷ lệ/kích thước; không ghi `đã định dạng khuôn mặt` nếu chưa có xử lý ảnh tương ứng.

### S05 — Preview và xuất PDF

Tham chiếu: `wireframes/07-cv-preview.png`.

- Tiêu đề tiếng Việt thống nhất là `Xem trước CV`.
- Tên template chuẩn: `Harvard ATS` và `Modern Minimalist`.
- Hiển thị trang A4, số trang, zoom và tùy chọn vừa màn hình.
- Đổi template không làm mất nội dung.
- Nút chính là `Xuất PDF`; nút phụ là `Chia sẻ` và `Chỉnh sửa`.
- Preview đọc dữ liệu thật của `cvId`, không dùng nội dung hard-code khi triển khai production.

## 4. Trạng thái dùng chung

Tham chiếu: `wireframes/08-ui-states.png`.

- Loading: skeleton giữ nguyên bố cục, tránh spinner khóa toàn màn hình.
- Empty: giải thích ngắn và có một CTA chính.
- Recoverable error: mô tả dữ liệu local vẫn an toàn, cho phép thử lại hoặc tiếp tục offline.
- Confirm delete: hiển thị đúng tên CV và hai hành động `Hủy`/`Xóa CV`.
- PDF error: giữ dữ liệu và cho phép thử lại.
- PDF success: hiển thị tên file, đóng hoặc mở System Share Sheet.

## 5. Ranh giới triển khai tuần 5

- Wireframe và tài liệu này là đầu ra thiết kế, không phải yêu cầu hoàn thiện UI production ngay trong tuần 5.
- Chưa nối Dashboard/Editor với database chỉ để làm giao diện giống ảnh.
- Chưa xây Supabase Auth, sync engine hoặc PDF engine trong lát cắt tài liệu này.
- Triển khai chức năng thật bắt đầu theo thứ tự trong `docs/mvp-flow.md` từ tuần 6.

