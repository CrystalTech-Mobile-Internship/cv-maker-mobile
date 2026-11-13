# Supabase Authentication

## Phạm vi

Module Auth thuộc trách nhiệm của Nguyễn Tuấn Anh và tách biệt với migration,
RLS cùng Sync Engine CV do Nguyễn Hoàng Phong phụ trách.

Ứng dụng hỗ trợ:

- đăng ký và đăng nhập email/mật khẩu;
- xác nhận email theo cấu hình Supabase;
- đăng nhập Google OAuth;
- gửi email quên mật khẩu;
- nhận deep link và đặt mật khẩu mới;
- khôi phục phiên Supabase khi mở lại ứng dụng;
- cập nhật tên hiển thị trong Auth user metadata;
- đăng xuất mà không xóa dữ liệu CV trong Drift SQLite;
- tiếp tục sử dụng Guest Mode khi cloud chưa cấu hình hoặc mất mạng.

## Redirect URL cần cấu hình

Trong Supabase Dashboard, mở **Authentication → URL Configuration** và thêm:

```text
com.example.cvmakermobile://login-callback
```

Redirect này được dùng chung cho Android/iOS OAuth và Password Recovery. Android
đã khai báo intent filter trong `AndroidManifest.xml`; iOS đã khai báo URL scheme
trong `Info.plist`.

Với Flutter Web, thêm origin thực tế của môi trường chạy, ví dụ:

```text
http://localhost:5000
https://cv.example.com
```

Không thêm URL giả hoặc wildcard rộng vào môi trường production.

## Cấu hình Google OAuth

Google Login thuộc module Auth của Nguyễn Tuấn Anh. Phần này không phụ thuộc
vào migration, RLS hoặc Sync Engine CV.

1. Trong Google Cloud Console, tạo OAuth consent screen cho ứng dụng.
2. Tạo OAuth Client ID loại **Web application**. Supabase sẽ xử lý trao đổi mã
   OAuth ở backend nên không đặt Google Client Secret trong Flutter.
3. Trong Supabase Dashboard, mở **Authentication → Providers → Google**, bật
   provider và nhập Google Client ID cùng Client Secret.
4. Sao chép **Callback URL** mà Supabase hiển thị trong trang Google provider
   và thêm chính xác URL đó vào **Authorized redirect URIs** của OAuth client
   trên Google Cloud Console. URL thường có dạng:

   ```text
   https://<project-ref>.supabase.co/auth/v1/callback
   ```

5. Trong **Authentication → URL Configuration → Redirect URLs**, giữ redirect
   về ứng dụng:

   ```text
   com.example.cvmakermobile://login-callback
   ```

6. Kiểm tra `SUPABASE_URL` trong `.env` mở được trên DNS trước khi test. Nếu
   Chrome báo `ERR_NAME_NOT_RESOLVED`, hãy sao chép lại Project URL từ
   **Project Settings → Data API**; lỗi này xảy ra trước Google OAuth và không
   liên quan đến callback trong Flutter.
7. Trên Android, bấm **Tiếp tục với Google**, chọn tài khoản thử nghiệm, xác
   nhận trình duyệt quay lại ứng dụng và màn hình Home hiển thị trạng thái đã
   đăng nhập. Không dùng tài khoản cá nhân thật trong ảnh chụp hoặc log test.

Các bí mật cần đặt ở phía dashboard/provider, không đặt trong repo:

- Google OAuth Client Secret;
- Supabase service-role key;
- database password.

Flutter chỉ giữ URL và publishable/anon key của từng profile trong `.env` cục
bộ.

## Hai Supabase project

Ứng dụng hỗ trợ khai báo hai project nhưng chỉ chọn **một project cho toàn bộ
vòng đời của process**:

```dotenv
SUPABASE_ACTIVE_PROFILE=secondary
SUPABASE_PRIMARY_URL=https://<primary-ref>.supabase.co
SUPABASE_PRIMARY_ANON_KEY=sb_publishable_...
SUPABASE_SECONDARY_URL=https://<secondary-ref>.supabase.co
SUPABASE_SECONDARY_ANON_KEY=sb_publishable_...
```

Đổi `SUPABASE_ACTIVE_PROFILE` giữa `primary` và `secondary`, sau đó build/chạy
lại ứng dụng. Không tự động chuyển project giữa phiên vì:

- cùng một email có thể ánh xạ đến hai user ID khác nhau;
- JWT của project A không hợp lệ với project B;
- schema, RLS, Storage và dữ liệu CV không tự đồng bộ giữa hai project;
- đổi project âm thầm có thể khiến người dùng tưởng dữ liệu bị mất.

Project secondary phù hợp làm môi trường phát triển tạm thời. Nếu cần chuyển
sang primary về sau, phải có kế hoạch migration dữ liệu và yêu cầu người dùng
đăng nhập lại.

## Luồng Password Recovery

```text
Nhập email
→ Supabase gửi recovery email
→ người dùng mở liên kết
→ Supabase khôi phục recovery session
→ app nhận AuthChangeEvent.passwordRecovery
→ router mở /reset-password
→ cập nhật mật khẩu
→ đăng xuất và quay lại Login
```

CV local không bị đọc, sửa hoặc xóa trong luồng này.

## Ranh giới với Cloud Sync

Auth chỉ cung cấp danh tính người dùng hiện tại. Module này không:

- gán quyền sở hữu CV Guest;
- push hoặc pull CV;
- xử lý pending deletion;
- giải quyết xung đột nhiều thiết bị;
- thay đổi migration hoặc chính sách RLS.

Các thao tác trên phải đi qua Sync Engine và migration thuộc phần backend dữ
liệu. Khi tích hợp hai module, UI phải hỏi người dùng trước khi chuyển CV Guest
sang tài khoản.

## Bảo mật

- Flutter chỉ sử dụng Supabase publishable/anon key.
- Không đưa service-role key, database password hoặc OAuth client secret vào
  `.env` của ứng dụng.
- Trạng thái `Đã cấu hình` chỉ xác nhận SDK có URL/key; không được dùng như bằng
  chứng migration, RLS hay Sync Engine đã hoạt động.
