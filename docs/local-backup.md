# Sao lưu và khôi phục CV trên thiết bị

## Mục đích

- Xuất toàn bộ CV đang hiển thị thành một tệp JSON có phiên bản.
- Khôi phục dữ liệu khi đổi máy, cài lại ứng dụng hoặc cần một bản dự phòng.
- Không phụ thuộc Supabase, Internet hoặc tài khoản đăng nhập.

## Nguyên tắc an toàn

- Tệp có trường nhận diện `Smart CV Maker` và phiên bản định dạng.
- Chỉ nhận tệp `.json` tối đa 8 MB.
- Tệp sai định dạng, rỗng hoặc hỏng sẽ bị từ chối.
- Khôi phục không ghi đè CV đang có. Mỗi CV được tạo với ID mới, thêm hậu tố
  “Khôi phục” và được đánh dấu chưa đồng bộ.
- Khi người dùng đang đăng nhập, bản khôi phục được gắn với tài khoản hiện tại;
  khách vãng lai vẫn lưu được bản khôi phục hoàn toàn ở local.

## Quyền riêng tư

Tệp sao lưu chứa dữ liệu CV cá nhân ở dạng JSON đọc được. Ứng dụng không tự tải
tệp lên Internet; người dùng cần tự bảo quản và không chia sẻ tệp công khai.
