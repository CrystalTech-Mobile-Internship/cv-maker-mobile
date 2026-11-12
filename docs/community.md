# Cộng đồng & việc làm

Tab **Cộng đồng** cho người dùng đã đăng nhập:

- **Thảo luận** — kinh nghiệm học tập, phỏng vấn, nghề nghiệp.
- **Việc làm** — chia sẻ tin tuyển dụng (công ty bắt buộc; địa điểm, mức lương, link ứng tuyển tùy chọn).
- **Góp ý CV** — nhờ cộng đồng nhận xét CV.

Chức năng: lọc theo loại, tìm kiếm, phân trang cuộn vô hạn, thích (cập nhật lạc quan, tự hoàn tác khi lỗi), bình luận, xóa bài/bình luận của mình, báo cáo vi phạm.

## An toàn & kiểm duyệt

- Chỉ tài khoản đăng nhập mới đọc/đăng (RLS trên mọi bảng `community_*`).
- Người dùng chỉ sửa/xóa nội dung của chính mình; cột đếm (`like_count`, `comment_count`, `report_count`, `is_hidden`) chỉ do trigger cập nhật — client không có quyền ghi.
- Bài nhận **3 báo cáo** tự động ẩn khỏi bảng tin (tác giả vẫn thấy), chờ quản trị viên xem xét trong Dashboard.
- Giới hạn: 5 bài/giờ và 20 bình luận/10 phút mỗi người (trigger).
- Ràng buộc độ dài, tối đa 5 thẻ, link ứng tuyển phải là `http(s)://`.
- Khi nội dung có email/số điện thoại, app cảnh báo trước khi đăng.
- Link ứng tuyển không tự mở: app hiển thị tên miền và chỉ cho sao chép, giảm rủi ro lừa đảo.

Migration: `supabase/migrations/20261112000400_community.sql`. Mã: `lib/features/community/`.

## Hướng phát triển

- Đính kèm bản CV ẩn danh (ẩn liên hệ) vào bài "Góp ý CV".
- Màn quản trị duyệt báo cáo; huy hiệu nhà tuyển dụng đã xác minh.
- Thông báo khi có bình luận mới.
