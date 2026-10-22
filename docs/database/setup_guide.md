# Smart CV Maker - database setup

Tài liệu này mô tả backend Supabase và cơ chế SQLite offline-first của ứng dụng.
Schema tập trung vào tài khoản, CV, nội dung CV và danh mục template. AI và
Storage chưa nằm trong phạm vi hiện tại.

## 1. Tạo project Supabase

Project phát triển hiện tại là `smart-cv-maker-dev`. Không đưa `service_role`
key vào ứng dụng Flutter.

## 2. Chạy schema

1. Mở **SQL Editor** của project.
2. Với project trống, mở file `supabase/schema.sql`. Với project đã có schema,
   chạy migration mới nhất trong `supabase/migrations/`.
3. Dán toàn bộ nội dung vào một query mới.
4. Chạy query một lần.
5. Kiểm tra trong **Table Editor** có các bảng:
   `profiles`, `cvs`, `cv_sections`, `cv_items`, `templates`.

Migration `20261021000100_enable_offline_cloud_sync.sql` hỗ trợ cả project mới
và schema cũ, đồng thời bật RLS cho toàn bộ dữ liệu người dùng.

## 3. Cấu hình Flutter

Tạo file `.env` từ `.env.example` trong thư mục project:

```env
SUPABASE_PRIMARY_URL=https://<primary-project-ref>.supabase.co
SUPABASE_PRIMARY_ANON_KEY=<primary-publishable-or-anon-key>
SUPABASE_SECONDARY_URL=https://<secondary-project-ref>.supabase.co
SUPABASE_SECONDARY_ANON_KEY=<secondary-publishable-or-anon-key>
SUPABASE_ACTIVE_PROFILE=secondary
```

Ứng dụng chỉ kết nối **một** profile trong mỗi lần chạy. Không trộn session hoặc
user ID giữa hai project Supabase.

Chỉ sử dụng publishable/anon key trong app. Không commit `.env` và không dùng
service-role key ở phía client.

Sau đó chạy:

```powershell
Set-Location D:\Project_CV\cv-maker-mobile
flutter pub get
flutter analyze
```

`lib/main.dart` đã gọi `SupabaseService.initialize()` lúc khởi động. Khi `.env`
chưa có key hợp lệ, app vẫn có thể chạy chế độ local/guest nhưng các hàm remote
sẽ báo lỗi cấu hình thay vì âm thầm ghi dữ liệu.

## 4. Đăng nhập và lưu CV

Luồng tài khoản dùng Supabase Auth với email/mật khẩu và Google:

- Mở **Tạo tài khoản** để đăng ký bằng họ tên, email và mật khẩu.
- Nếu project yêu cầu xác nhận email, mở email xác nhận trước khi đăng nhập.
- Sau khi đăng nhập, Home chỉ hiển thị CV khách trên thiết bị và CV thuộc user
  hiện tại.
- Nút **Đồng bộ ngay** tải các bản local chưa đồng bộ lên cloud, sau đó tải CV
  của tài khoản hiện tại về SQLite.
- Lưu trong Editor luôn ghi SQLite trước. Mất mạng không làm mất CV; bản local
  được giữ ở trạng thái chờ đồng bộ.
- RLS bảo đảm user chỉ đọc, sửa và xoá CV có `user_id = auth.uid()`.

## 5. Đăng nhập Google trên Android

Code Flutter đã có nút **Tiếp tục với Google** và dùng deep link:

```text
com.example.cvmakermobile://login-callback
```

Để bật provider, trong Google Cloud Console tạo OAuth Client ID loại **Web
application**. Thêm callback URL được hiển thị tại trang Google Provider của
Supabase vào **Authorized redirect URIs**, sau đó bật
**Authentication -> Providers -> Google** trong project và nhập Client ID cùng
Client Secret. Không đưa Google Client Secret vào app Flutter.

Trong **Authentication -> URL Configuration -> Additional Redirect URLs** của
Supabase, thêm deep link ở trên. Android đã được cấu hình intent filter trong
`android/app/src/main/AndroidManifest.xml`; `supabase_flutter` sẽ nhận deep link
và khôi phục session sau khi Google xác thực thành công.

## 6. Đăng nhập Google trên Flutter Web (localhost)

Project đã bật Flutter Web. Khi chạy local, phải để web server chạy liên tục
trong terminal trong suốt quá trình đăng nhập:

```powershell
Set-Location D:\Project_CV\cv-maker-mobile
flutter run -d chrome
```

Nếu terminal của VS Code đã hiển thị thư mục project
`PS D:\Project_CV\cv-maker-mobile>`, chỉ cần chạy dòng thứ hai. Flutter sẽ tự
mở Chrome ở cổng local đang trống.

Nếu cần dùng cố định cổng `3000` để khớp Site URL hiện tại, dùng lệnh tùy chọn:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 3000
```

Mở địa chỉ local mà Flutter in ra trong terminal. Với lệnh cố định ở trên, địa
chỉ là:

```text
http://localhost:3000
```

Không mở URL có `?code=...` cũ sau một lần đăng nhập lỗi; hãy quay lại trang
gốc rồi bấm **Tiếp tục với Google** lại. Web app hiện gửi redirect theo
`Uri.base.origin`, nên khi chạy ở cổng khác cần thêm origin đó vào
**Authentication -> URL Configuration -> Redirect URLs** của đúng project
Singapore. Site URL local nên là `http://localhost:3000`.

Nếu thấy `localhost refused to connect`, kiểm tra terminal còn tiến trình
`flutter run` hay không. Lỗi này có nghĩa là không có web server lắng nghe cổng
3000, không phải lỗi Client ID hoặc Google Provider.

## 7. Phạm vi dữ liệu local và cloud

- SQLite/Drift là nguồn dữ liệu chính khi người dùng chỉnh sửa CV.
- Khách chưa đăng nhập vẫn tạo, sửa, xem trước và xuất PDF bằng dữ liệu local.
- Supabase lưu bản sao theo tài khoản: `personal_info`, summary, template và các
  mục education/experience/skills/projects/certifications.
- `CvSyncRepository` điều phối local và remote; widget không gọi Supabase trực
  tiếp.
- Năm template trong tab **Mẫu CV** là thiết kế, không được tính là năm CV đã
  lưu. Chỉ các dòng trong bảng SQLite `local_cvs` mới xuất hiện ở bộ đếm đồng bộ.

## 8. Kiểm tra RLS tối thiểu

Tạo hai user thử nghiệm trong Authentication, đăng nhập lần lượt bằng từng
user, rồi xác nhận:

- User A chỉ thấy và sửa được CV có `user_id = A`.
- User B không đọc, cập nhật hoặc xoá được CV của A.
- `cv_sections` và `cv_items` chỉ truy cập được thông qua CV thuộc user hiện tại.
- `templates` chỉ đọc được các template đang active.

Nếu cần thao tác quản trị hoặc seed dữ liệu, thực hiện trong Dashboard bằng
quyền admin; không đưa service-role key vào mã Flutter.
