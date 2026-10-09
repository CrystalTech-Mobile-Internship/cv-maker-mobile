# Smart CV Maker - database setup

Tài liệu này dùng cho phần backend dữ liệu của tuần 5. Schema hiện tại tập trung
vào hồ sơ người dùng, CV và các mục nội dung CV. AI, Storage và seed template
chưa nằm trong phạm vi của bước này.

## 1. Tạo project Supabase

Project đang dùng cho môi trường Singapore là `smart-cv-maker-sg` trong tổ chức
Supabase `Smart CV Maker`, region `Southeast Asia (Singapore)`
(`ap-southeast-1`). Project Tokyo `smart-cv-maker` được giữ nguyên và không bị
xoá. Không đưa `service_role` key vào ứng dụng Flutter.

## 2. Chạy schema

1. Mở **SQL Editor** của project.
2. Mở file `supabase/schema.sql` trong repository.
3. Dán toàn bộ nội dung vào một query mới.
4. Chạy query một lần.
5. Kiểm tra trong **Table Editor** có các bảng:
   `profiles`, `cvs`, `cv_sections`, `cv_items`, `templates`.

File có thể chạy lại an toàn ở mức migration ban đầu: các bảng, index và trigger
được tạo theo kiểu `if not exists`; các policy được xoá trước khi tạo lại.

## 3. Cấu hình Flutter

Tạo file `.env` từ `.env.example` trong thư mục project:

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

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

Màn hình đăng nhập hiện dùng Supabase Auth với email và mật khẩu:

- Chọn **Đăng ký** lần đầu để tạo user trong `Authentication -> Users`.
- Nếu project yêu cầu xác nhận email, mở email xác nhận trước khi đăng nhập.
- Sau khi đăng nhập, màn hình Home tải các CV thuộc user hiện tại qua
  `CvRemoteDataSource.fetchUserCvs()`.
- Trong màn hình Editor, nút **Lưu lên cloud** gọi `upsertCv()`; nút xoá trên
  Home gọi `deleteRemoteCv()`.
- RLS bảo đảm user chỉ đọc, sửa và xoá CV có `user_id = auth.uid()`.

## 5. Đăng nhập Google trên Android

Code Flutter đã có nút **Tiếp tục với Google** và dùng deep link:

```text
com.example.cv_maker_mobile://login-callback
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

- Local/UI state: nội dung đang nhập dở, trạng thái loading/error, tab hiện tại
  và bản nháp chưa bấm lưu.
- Cloud/Supabase: CV đã lưu, `personal_info`, summary, template, và các mục
  education/experience/skills/projects trong `cv_sections` + `cv_items`.
- Đồng bộ: `CvRemoteDataSource.upsertCv()` ghi một CV và các section con; khi
  xoá CV, các section/item con bị xoá theo foreign key cascade.
- Bản hiện tại chưa thêm Hive/SQLite. Khi cần offline-first, thêm local data
  source và một lớp repository để đồng bộ theo `updated_at`; không gọi Supabase
  trực tiếp từ widget.

## 8. Kiểm tra RLS tối thiểu

Tạo hai user thử nghiệm trong Authentication, đăng nhập lần lượt bằng từng
user, rồi xác nhận:

- User A chỉ thấy và sửa được CV có `user_id = A`.
- User B không đọc, cập nhật hoặc xoá được CV của A.
- `cv_sections` và `cv_items` chỉ truy cập được thông qua CV thuộc user hiện tại.
- `templates` chỉ đọc được các template đang active.

Nếu cần thao tác quản trị hoặc seed dữ liệu, thực hiện trong Dashboard bằng
quyền admin; không đưa service-role key vào mã Flutter.
