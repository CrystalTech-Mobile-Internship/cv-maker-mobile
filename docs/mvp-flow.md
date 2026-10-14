# LUỒNG NGƯỜI DÙNG MVP — SMART CV MAKER MOBILE

- Ngày cập nhật: 06/10/2026
- Phiên bản: MVP v1
- Nhóm thực hiện: Nguyễn Tuấn Anh và Nguyễn Hoàng Phong
- Nền tảng: Flutter (Android/iOS), local database và Supabase
- Mục tiêu: Cho phép người dùng tạo, chỉnh sửa, lưu, xem trước và xuất CV ngay cả khi không có Internet.

## 1. Phạm vi MVP

MVP phải hoàn thành được hành trình cốt lõi sau:

1. Người dùng mở ứng dụng.
2. Người dùng đăng nhập bằng Supabase hoặc tiếp tục ở chế độ Khách.
3. Người dùng xem danh sách CV đang có.
4. Người dùng tạo CV mới hoặc mở một CV để chỉnh sửa.
5. Người dùng nhập thông tin và ứng dụng tự động lưu trên thiết bị.
6. Người dùng chọn mẫu, xem trước CV và xuất PDF.
7. Nếu đã đăng nhập và có Internet, dữ liệu được đồng bộ với Supabase.

### 1.1. Chức năng bắt buộc

- Đăng nhập bằng email và mật khẩu.
- Đăng ký tài khoản và yêu cầu đặt lại mật khẩu.
- Tiếp tục không cần tài khoản ở chế độ Khách.
- Xem danh sách CV và trạng thái trống.
- Tạo, mở, đổi tên, sao chép và xóa CV.
- Nhập thông tin cá nhân, tóm tắt, học vấn, kinh nghiệm, kỹ năng và dự án.
- Tự động lưu dữ liệu trên thiết bị.
- Chỉnh sửa khi không có Internet.
- Đồng bộ dữ liệu với Supabase sau khi đăng nhập.
- Chọn giữa bốn template Free trong catalog, sau đó xem trước CV.
- Xuất PDF A4 và chia sẻ file bằng System Share Sheet.

### 1.2. Chức năng chưa bắt buộc trong MVP đầu tiên

- AI chấm điểm ATS hoàn chỉnh.
- AI viết lại Summary hoặc cải thiện bullet bằng Gemini.
- Nhiều nhà cung cấp AI và cơ chế tự động chuyển đổi nhà cung cấp.
- Đồng bộ xung đột phức tạp giữa nhiều thiết bị.
- Chia sẻ trực tiếp qua từng ứng dụng cụ thể như Zalo.
- Bốn template hoàn thiện cùng lúc.
- Lưu PDF lên Supabase Storage.
- Nhập nội dung CV từ PDF hoặc Word.
- Đa ngôn ngữ giao diện.

Các chức năng trên chỉ được triển khai sau khi luồng tạo, lưu và xuất CV hoạt động ổn định.

## 2. Vai trò và chế độ sử dụng

### 2.1. Người dùng Khách

- Không cần tài khoản.
- Có thể tạo, chỉnh sửa, xem trước và xuất PDF.
- Dữ liệu được lưu trên thiết bị.
- CV có `userId = null` và `isSynced = false`.
- Khi đăng nhập sau này, ứng dụng đề nghị đồng bộ các CV đang lưu trên máy.

### 2.2. Người dùng đã đăng nhập

- Được Supabase Auth xác thực.
- Dữ liệu luôn được lưu local trước.
- Khi có Internet, dữ liệu được đồng bộ lên Supabase.
- Chỉ được đọc và thay đổi CV thuộc tài khoản của mình.
- Khi mất mạng, người dùng vẫn chỉnh sửa bình thường và đồng bộ lại sau.

## 3. Danh sách màn hình

### S01 — Khởi động ứng dụng

Trách nhiệm:

- Nạp cấu hình môi trường.
- Khởi tạo local database.
- Khởi tạo Supabase nếu có cấu hình.
- Kiểm tra phiên đăng nhập hiện tại.
- Điều hướng đến Login hoặc Dashboard.

Trạng thái cần có: đang khởi tạo, thành công và lỗi có thể phục hồi.

### S02 — Đăng nhập

Route hiện tại: `/login`

Trách nhiệm:

- Nhập email và mật khẩu.
- Đăng nhập bằng Supabase.
- Tiếp tục ở chế độ Khách/Offline.
- Hiển thị trạng thái kết nối cloud.
- Hiển thị lỗi đăng nhập dễ hiểu.

Quy tắc:

- Đăng nhập thành công thì chuyển sang Dashboard.
- Nếu Supabase chưa được cấu hình hoặc không có mạng, người dùng vẫn có thể chọn chế độ Khách.
- Không lưu mật khẩu trong local database.

### S03 — Dashboard quản lý CV

Route hiện tại: `/home`

Trách nhiệm:

- Hiển thị danh sách CV.
- Hiển thị Empty State khi chưa có CV.
- Tạo CV mới.
- Mở hoặc xem trước một CV.
- Đổi tên, sao chép và xóa CV.
- Hiển thị trạng thái đồng bộ của từng CV.
- Đăng xuất.

Mỗi CV nên hiển thị tối thiểu:

- Tiêu đề CV.
- Tên template.
- Thời gian cập nhật gần nhất.
- Trạng thái `Đã đồng bộ`, `Chưa đồng bộ` hoặc `Đang đồng bộ`.

### S04 — Trình chỉnh sửa CV

Route đề xuất: `/editor/:cvId`

Route hiện tại: `/editor`

Trách nhiệm:

- Nhập thông tin cá nhân.
- Nhập tóm tắt nghề nghiệp.
- Quản lý danh sách học vấn.
- Quản lý danh sách kinh nghiệm.
- Quản lý kỹ năng.
- Quản lý dự án và hoạt động.
- Tự động lưu thay đổi.
- Hiển thị trạng thái lưu.
- Chuyển sang xem trước.

Các trạng thái lưu:

- `Đang lưu...`
- `Đã lưu trên thiết bị`
- `Chưa đồng bộ`
- `Đã đồng bộ`
- `Lưu thất bại — Thử lại`

### S05 — Xem trước và xuất PDF

Route đề xuất: `/preview/:cvId`

Route hiện tại: `/preview`

Trách nhiệm:

- Nhận đúng CV theo `cvId`.
- Hiển thị dữ liệu thật từ CV Editor.
- Cho phép chọn template.
- Cho phép chỉnh màu chủ đạo và kích thước chữ.
- Quay lại Editor mà không mất dữ liệu.
- Xuất PDF A4.
- Hiển thị tiến trình và kết quả xuất PDF.

## 4. Sơ đồ luồng tổng quát

```text
Mở ứng dụng
      |
      v
Khởi tạo local database và kiểm tra phiên đăng nhập
      |
      +------------------------+
      |                        |
      v                        v
Chưa đăng nhập            Đã đăng nhập
      |                        |
      v                        |
Màn hình Login                 |
      |                        |
      +-----------+------------+
                  |
                  v
        Dashboard — Danh sách CV
                  |
         +--------+--------+
         |                 |
         v                 v
     Tạo CV mới        Mở CV đã có
         |                 |
         +--------+--------+
                  |
                  v
             CV Editor
                  |
          Tự động lưu local
                  |
                  v
          Preview và chọn mẫu
                  |
                  v
              Xuất PDF

Nếu đã đăng nhập và có mạng:
Lưu local -> Đồng bộ Supabase -> Đánh dấu đã đồng bộ

Nếu mất mạng hoặc đang dùng chế độ Khách:
Lưu local -> Đánh dấu chưa đồng bộ -> Đồng bộ lại khi đủ điều kiện
```

## 5. Các luồng nghiệp vụ chính

### Flow A — Tạo CV ở chế độ Khách

1. Người dùng mở ứng dụng.
2. Người dùng chọn `Trải nghiệm Offline`.
3. Ứng dụng mở Dashboard bằng dữ liệu local.
4. Nếu chưa có CV, ứng dụng hiển thị Empty State.
5. Người dùng bấm `Tạo CV mới`.
6. Ứng dụng tạo một `cvId` dạng UUID và bản ghi local rỗng.
7. Ứng dụng mở Editor của CV vừa tạo.
8. Mỗi thay đổi hợp lệ được tự động lưu local.
9. Người dùng mở Preview, chọn template và xuất PDF.
10. CV giữ `userId = null` và `isSynced = false`.

Kết quả mong đợi: toàn bộ hành trình hoạt động khi thiết bị không có Internet.

### Flow B — Đăng nhập và tạo CV trên cloud

1. Người dùng nhập email và mật khẩu.
2. Ứng dụng kiểm tra dữ liệu đầu vào.
3. Supabase xác thực tài khoản.
4. Ứng dụng mở Dashboard và tải dữ liệu local trước.
5. Ứng dụng đồng bộ danh sách CV với Supabase.
6. Người dùng tạo hoặc chỉnh sửa CV.
7. Ứng dụng lưu local trước rồi đẩy thay đổi lên Supabase.
8. Đồng bộ thành công thì đặt `isSynced = true`.

Kết quả mong đợi: người dùng chỉ nhìn thấy và thay đổi dữ liệu thuộc tài khoản của mình.

### Flow C — Chỉnh sửa khi mất mạng

1. Người dùng mở một CV đã lưu trên thiết bị.
2. Thiết bị không có Internet.
3. Ứng dụng tải CV từ local database.
4. Người dùng chỉnh sửa bình thường.
5. Ứng dụng tự động lưu local và đặt `isSynced = false`.
6. Ứng dụng hiển thị trạng thái `Chưa đồng bộ` nhưng không chặn thao tác.
7. Khi có mạng trở lại và người dùng đã đăng nhập, ứng dụng thực hiện đồng bộ.
8. Đồng bộ thành công thì đặt `isSynced = true`.

Kết quả mong đợi: không mất dữ liệu và không bắt người dùng chờ Internet.

### Flow D — Chuyển CV Khách sang tài khoản

1. Người dùng đã có một hoặc nhiều CV local ở chế độ Khách.
2. Người dùng đăng nhập thành công.
3. Ứng dụng phát hiện các CV có `userId = null`.
4. Ứng dụng hỏi người dùng có muốn đồng bộ các CV trên thiết bị hay không.
5. Nếu đồng ý, ứng dụng gán `userId` hiện tại và đồng bộ từng CV.
6. Nếu từ chối, CV tiếp tục được giữ local và không bị xóa.

Kết quả mong đợi: đăng nhập không làm mất CV đã tạo ở chế độ Khách.

### Flow E — Xem trước và xuất PDF

1. Người dùng bấm `Xem trước CV` từ Editor hoặc Dashboard.
2. Ứng dụng lưu các thay đổi đang có trước khi điều hướng.
3. Preview đọc CV tương ứng theo `cvId`.
4. Người dùng chọn template, màu và kích thước chữ.
5. Thay đổi giao diện không làm mất nội dung CV.
6. Người dùng bấm `Xuất PDF`.
7. Ứng dụng tạo PDF A4 từ dữ liệu hiện tại.
8. Thành công thì hiển thị tùy chọn mở hoặc chia sẻ file.
9. Thất bại thì giữ nguyên dữ liệu và cho phép thử lại.

### Flow F — Xóa CV

1. Người dùng chọn `Xóa` tại Dashboard.
2. Ứng dụng hiển thị hộp thoại xác nhận với tên CV.
3. Nếu hủy, không có dữ liệu nào thay đổi.
4. Nếu xác nhận, ứng dụng xóa bản ghi local.
5. Nếu CV đã đồng bộ, ứng dụng xóa bản ghi cloud khi có mạng.
6. Nếu xóa cloud thất bại, ứng dụng lưu thao tác chờ để thử lại.

Kết quả mong đợi: không xóa nhầm và thao tác xóa hoạt động nhất quán khi offline.

## 6. Quy tắc điều hướng

- Khởi động -> Login: chưa có phiên đăng nhập hợp lệ.
- Khởi động -> Dashboard: có phiên đăng nhập hợp lệ hoặc đã chọn chế độ Khách.
- Login -> Dashboard: đăng nhập thành công hoặc chọn chế độ Khách.
- Dashboard -> Editor: tạo CV mới hoặc mở CV đã có.
- Dashboard -> Preview: xem nhanh một CV đã có.
- Editor -> Preview: lưu thay đổi rồi xem trước đúng `cvId`.
- Preview -> Editor: quay lại chỉnh sửa đúng `cvId`.
- Editor -> Dashboard: lưu thay đổi trước khi rời màn hình.
- Dashboard -> Login: đăng xuất.

### 6.1. Quy tắc nút Back

- Back tại Editor không được làm mất thay đổi vừa nhập.
- Back tại Preview quay về Editor hoặc màn hình trước đó.
- Nếu một thao tác quan trọng đang chạy, ứng dụng phải chặn bấm lặp hoặc hiển thị trạng thái xử lý.
- Không tạo nhiều bản sao CV chỉ vì người dùng bấm Back rồi mở lại.

## 7. Quy tắc dữ liệu và đồng bộ

### 7.1. Local-first

- Giao diện đọc dữ liệu từ local database.
- Thay đổi được lưu local trước khi gửi lên cloud.
- Mất kết nối Supabase không được làm ứng dụng mất khả năng chỉnh sửa.
- `updatedAt` phải thay đổi mỗi khi nội dung CV thay đổi.
- `isSynced` chuyển thành `false` khi local có thay đổi chưa được cloud xác nhận.

### 7.2. Supabase

- Chỉ người dùng đã đăng nhập mới được đồng bộ.
- Mọi bảng chứa CV phải bật Row-Level Security.
- Mỗi truy vấn cloud phải tuân theo `auth.uid() = user_id`.
- Ứng dụng Flutter chỉ dùng publishable key, không chứa secret key hoặc service-role key.

### 7.3. Quy tắc MVP khi có xung đột

Trong MVP, sử dụng quy tắc `bản cập nhật mới hơn thắng` dựa trên `updatedAt`. Trước khi triển khai đồng bộ nhiều thiết bị thực tế, quy tắc này phải được kiểm thử với thời gian hệ thống và múi giờ UTC.

## 8. Trạng thái giao diện bắt buộc

### Loading

Hiển thị khi:

- Khởi tạo ứng dụng.
- Đăng nhập.
- Tải hoặc đồng bộ danh sách CV.
- Xuất PDF.

### Empty State

Hiển thị khi người dùng chưa có CV:

- Tiêu đề: `Bạn chưa có CV nào`.
- Mô tả: `Hãy tạo CV đầu tiên để bắt đầu.`
- Nút chính: `Tạo CV mới`.

### Offline

- Hiển thị thông báo ngắn, không che nội dung.
- Cho phép tạo và chỉnh sửa CV.
- Hiển thị nhãn `Chưa đồng bộ` trên CV có thay đổi local.

### Error

Cần xử lý tối thiểu:

- Email hoặc mật khẩu không hợp lệ.
- Không kết nối được Supabase.
- Đọc hoặc lưu local thất bại.
- Đồng bộ thất bại.
- Không tìm thấy CV theo `cvId`.
- Xuất PDF thất bại.

Thông báo lỗi phải nói được chuyện gì xảy ra và người dùng có thể làm gì tiếp theo.

### Confirm Delete

Trước khi xóa phải hiển thị tên CV và hai lựa chọn rõ ràng: `Hủy` và `Xóa`.

## 9. Kiểm tra dữ liệu đầu vào

- Họ tên: bắt buộc.
- Vị trí ứng tuyển: bắt buộc.
- Email: nếu có thì phải đúng định dạng.
- Số điện thoại: nếu có thì phải đúng định dạng cho phép của ứng dụng.
- Ngày bắt đầu không được sau ngày kết thúc.
- Mục đang làm hoặc đang học không bắt buộc ngày kết thúc.
- Không thêm kỹ năng chỉ có khoảng trắng.
- Không tạo mục học vấn, kinh nghiệm hoặc dự án hoàn toàn rỗng.

Lỗi nhập liệu được hiển thị gần trường tương ứng và không được xóa nội dung người dùng đã nhập.

## 10. Khoảng cách giữa yêu cầu và code hiện tại

- [ ] Bổ sung màn hình khởi động và kiểm tra session.
- [ ] Đổi route Editor và Preview để nhận `cvId`.
- [ ] Bổ sung tab Dự án trong CV Editor.
- [ ] Bổ sung trường dữ liệu chi tiết cho Học vấn, Kinh nghiệm, Kỹ năng và Dự án.
- [x] Bổ sung Drift + SQLite và repository lưu dữ liệu local.
- [ ] Kết nối Editor với repository và cơ chế tự động lưu.
- [ ] Thay dữ liệu hard-code ở Dashboard bằng dữ liệu từ repository.
- [ ] Bổ sung Empty State.
- [ ] Bổ sung đổi tên, sao chép và xóa CV.
- [ ] Kết nối đăng nhập Supabase thật.
- [ ] Bổ sung đăng ký và quên mật khẩu nếu được đưa vào phạm vi MVP.
- [ ] Bổ sung trạng thái đồng bộ.
- [ ] Truyền dữ liệu thật từ Editor sang Preview.
- [ ] Xuất PDF thật thay cho thao tác mô phỏng.
- [ ] Viết kiểm thử cho các luồng quan trọng.

## 11. Tiêu chí nghiệm thu MVP

### AC01 — Guest Mode

Ứng dụng hoàn thành được luồng tạo, chỉnh sửa, đóng/mở lại, xem trước và xuất một CV khi thiết bị không có Internet.
Sau khi người dùng chọn Guest Mode, ứng dụng ghi nhớ lựa chọn và mở thẳng Dashboard local ở lần khởi động tiếp theo.

### AC02 — Không mất dữ liệu

Sau khi người dùng thay đổi nội dung và quay lại Dashboard hoặc đóng/mở lại ứng dụng, dữ liệu đã nhập vẫn còn.

### AC03 — Quản lý nhiều CV

Người dùng có thể tạo ít nhất hai CV và mở đúng CV đã chọn; nội dung của các CV không bị lẫn nhau.

### AC04 — Đồng bộ

Người dùng đăng nhập có thể tạo hoặc sửa CV khi offline; khi có mạng trở lại, dữ liệu được đồng bộ và trạng thái được cập nhật.

### AC05 — Cô lập dữ liệu

Hai tài khoản thử nghiệm không thể đọc, cập nhật hoặc xóa CV của nhau.

### AC06 — Preview

Preview hiển thị dữ liệu thật của CV đang chọn; đổi template không làm mất nội dung.

### AC07 — PDF

PDF được xuất đúng khổ A4, đọc được tiếng Việt, không cắt mất nội dung và có thể mở bằng ứng dụng đọc PDF trên thiết bị.

### AC08 — Trạng thái lỗi

Các lỗi mạng, đăng nhập, đồng bộ và xuất PDF không làm ứng dụng bị crash hoặc mất dữ liệu local.

## 12. Thứ tự triển khai đề xuất

1. Hoàn thiện model và repository interface.
2. Hoàn thiện local database và tự động lưu.
3. Thay dữ liệu hard-code bằng dữ liệu local.
4. Hoàn thiện Editor và truyền `cvId`.
5. Hoàn thiện Preview bằng dữ liệu thật.
6. Tích hợp Supabase Auth.
7. Tạo schema, RLS và đồng bộ cloud.
8. Hoàn thiện PDF.
9. Viết kiểm thử luồng Guest, offline, sync và RLS.
10. Chỉ sau đó mới mở rộng AI và các tính năng nâng cao.

## 13. Các quyết định đã được nhóm xác nhận

Nhóm đã chốt ngày 06/10/2026:

1. **Tài khoản:** MVP có Guest Mode, đăng ký, đăng nhập và quên mật khẩu.
2. **Dữ liệu Guest sau đăng nhập:** hỏi người dùng trước khi gắn và đồng bộ vào tài khoản.
3. **Template MVP (cập nhật 13/10/2026):** cung cấp miễn phí Harvard ATS, Modern Minimalist, Minimalist Clean và Creative Tech; cả bốn dùng chung dữ liệu CV local và phải xuất được PDF thật.
4. **PDF:** xuất A4 và chia sẻ bằng System Share Sheet là bắt buộc.
5. **Đồng bộ:** hoàn thiện local trước, sau đó mới tích hợp Supabase.
6. **AI:** Gemini được hoãn đến sau MVP cốt lõi.
7. **Import:** không nhập CV từ PDF hoặc Word trong MVP.
8. **Ngôn ngữ:** MVP dùng tiếng Việt.
9. **Nền tảng:** Android là nền tảng kiểm thử chính; mã nguồn giữ khả năng tương thích iOS nhưng chưa bắt buộc build iOS khi không có macOS.
10. **Xung đột đồng bộ:** dùng `updatedAt` và chiến lược bản mới hơn thắng trong MVP.
11. **Local database:** Drift + SQLite là nguồn dữ liệu local duy nhất cho CV.

## 14. Định nghĩa hoàn thành tài liệu

Tài liệu luồng MVP được xem là hoàn thành khi:

- Hai thành viên đã đọc và thống nhất phạm vi.
- Mỗi màn hình có trách nhiệm rõ ràng.
- Có luồng Guest, đăng nhập, offline, chuyển dữ liệu Guest, preview, PDF và xóa CV.
- Có quy tắc điều hướng và truyền `cvId`.
- Có quy tắc local-first và đồng bộ Supabase.
- Có tiêu chí nghiệm thu có thể kiểm thử.
- Các quyết định còn mở đã được xác nhận và cập nhật lại vào tài liệu.
