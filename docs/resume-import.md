# Nhập CV cũ và dùng lại hồ sơ

## Phạm vi hiện tại

- Chọn một tệp `.docx` hoặc `.pdf` có dung lượng tối đa 8 MB.
- Toàn bộ quá trình đọc tệp diễn ra trên thiết bị/trình duyệt; tệp gốc không tự
  động tải lên Supabase hay dịch vụ AI.
- DOCX được đọc trực tiếp từ `word/document.xml`.
- PDF có lớp chữ được đọc bằng PDFium. PDF scan/chỉ chứa ảnh chưa hỗ trợ OCR.
- Ứng dụng nhận diện có kiểm soát: họ tên, vị trí, email, điện thoại, tóm tắt,
  kỹ năng, học vấn, kinh nghiệm, dự án và chứng chỉ.
- Các mục có cấu trúc được nhận diện dựa trên tiêu đề tiếng Việt/tiếng Anh,
  khoảng thời gian, dấu phân cách, URL và nhãn công nghệ; không dùng AI và không
  tự bịa dữ liệu còn thiếu.
- Người dùng phải kiểm tra và có thể sửa kết quả trước khi lưu vào SQLite.
- Màn hình kiểm tra hiển thị số mục đã nhận diện. Sau khi lưu, CV được mở trong
  Editor để người dùng kiểm tra từng tab, bổ sung nội dung và đổi template.

## Dùng lại dữ liệu đã có

Khi tạo CV mới, mục **Dữ liệu ban đầu** cho phép chọn một CV đã lưu. Ứng dụng
tạo bản CV độc lập với template/ngôn ngữ mới; chỉnh sửa bản mới không làm thay
đổi CV nguồn.

Trang **Tài khoản** hiển thị phần **Hồ sơ dùng lại** lấy từ CV được cập nhật gần
nhất có thông tin cá nhân. Đây là dữ liệu local-first và chỉ lên cloud khi người
dùng chủ động đồng bộ CV.

## Giới hạn an toàn

- Không suy đoán trường học, công ty, ngày tháng hoặc chứng chỉ khi cấu trúc tệp
  không đủ rõ.
- Không OCR CV scan ở phiên bản này để tránh tăng APK và tránh nhận diện sai.
- Không đọc định dạng `.doc` cũ; người dùng cần lưu lại thành `.docx`.
- Tệp có mật khẩu hoặc PDF cấm sao chép có thể không đọc được.

## Hướng phát triển

- Cho phép sửa chi tiết từng mục có cấu trúc ngay tại màn hình kiểm tra import.
- OCR tùy chọn chạy phía server, yêu cầu đăng nhập và xác nhận quyền riêng tư.
- Hồ sơ chuẩn hóa riêng trên Supabase để dùng lại giữa nhiều thiết bị.
