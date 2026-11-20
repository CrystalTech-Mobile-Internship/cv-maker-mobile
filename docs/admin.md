# Trang quản trị

Trang `/admin` (menu **Quản trị**, chỉ hiện với tài khoản admin) có:

- **Hỗ trợ**: tất cả cuộc trò chuyện từ nút Hỗ trợ, cái mới nhất lên đầu, kèm số tin đang chờ trả lời. Trả lời ở đây thì người dùng thấy ngay trong khung chat của họ.
- **Thanh toán**: các chuyển khoản SePay báo về và các yêu cầu nâng cấp Pro. Yêu cầu "Chờ thanh toán" có nút **Duyệt** / **Từ chối** cho trường hợp khách chuyển sai nội dung.
- Số liệu nhanh: số người dùng, số tài khoản đang Pro, doanh thu tháng này, số cuộc trò chuyện chờ trả lời.

## Thêm admin

Admin nằm trong bảng `admin_users`. App không thể tự thêm, chỉ thêm được trong **Supabase → SQL Editor**:

```sql
insert into public.admin_users (user_id)
select id from auth.users where email = '<email của admin>';
```

Gỡ quyền:

```sql
delete from public.admin_users
where user_id = (select id from auth.users where email = '<email>');
```

Sau khi thêm, đăng xuất rồi đăng nhập lại (hoặc tải lại trang) để menu **Quản trị** hiện ra.

## Quyền của admin

Mọi thao tác đều do database kiểm tra (`is_admin()` trong các hàm `admin_*`), không chỉ ẩn nút trên app. Admin chỉ:

- đọc và trả lời tin nhắn hỗ trợ;
- xem yêu cầu Pro, chuyển khoản SePay, duyệt hoặc từ chối yêu cầu đang chờ;
- xem số liệu tổng.

Admin **không** xem hay sửa được CV của người dùng.
