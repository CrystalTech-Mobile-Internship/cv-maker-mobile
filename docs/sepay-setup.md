# Gắn SePay để bán gói Pro

Tài liệu này hướng dẫn từng bước bật thanh toán tự động bằng SePay cho Smart CV Maker. Khi xong, người dùng quét mã QR, chuyển khoản, và tài khoản tự lên Pro trong vài giây. Bạn không phải duyệt tay.

> Nếu bạn đã làm SePay cho hệ thống khác (ví dụ SmartEnglish), các bước trên trang SePay giống hệt. Chỉ khác **địa chỉ webhook**, **khóa API** và **tiền tố mã thanh toán** (`CVPRO`).

---

## 1. Cách hệ thống chạy

```
Người dùng chọn gói ──► app gọi RPC start_pro_checkout
                         └─ tạo yêu cầu "pending" + mã CVPROxXXXXXXXX + số tiền
App hiện QR (qr.sepay.vn) có sẵn số tiền + nội dung = mã
Người dùng chuyển khoản ──► ngân hàng ──► SePay
SePay gọi webhook ──► Edge Function sepay-webhook
                         ├─ kiểm tra khóa API
                         ├─ lưu giao dịch vào payment_events (không trùng)
                         ├─ tìm mã CVPRO… trong nội dung chuyển khoản
                         ├─ so số tiền ≥ giá gói
                         └─ approve_pro_request ──► user_entitlements = Pro
App đang mở màn thanh toán tự thấy Pro (realtime + kiểm tra mỗi 4 giây)
```

- **Giá gói** nằm ở hàm SQL `pro_plan_price`: 1 tháng `49.000đ`, 3 tháng `119.000đ`. Muốn đổi giá thì sửa hàm này (và `ProPlan` trong `lib/features/billing/domain/billing_models.dart` để màn hình hiện đúng).
- **Mã thanh toán** có dạng `CVPRO` + `M` (1 tháng) hoặc `Q` (3 tháng) + 8 ký tự, ví dụ `CVPROQ1A2B3C4D`. Mỗi tài khoản có mã riêng theo gói.
- Chuyển **thiếu tiền** hoặc **sai mã** thì giao dịch được lưu với trạng thái `unmatched`, không lên Pro. Bạn xử lý tay (mục 8).

## 2. Chuẩn bị

| Cần có | Ghi chú |
| --- | --- |
| Tài khoản SePay đã liên kết ngân hàng nhận tiền | Ví dụ MB Bank. Gói miễn phí của SePay đủ để bắt đầu. |
| Quyền quản trị project Supabase `woejrebdstgredslznye` | Để chạy migration, deploy function, đặt secret. |
| Node.js (để chạy `npx supabase`) | CLI đã đăng nhập: `npx supabase login`. |
| Quyền sửa biến môi trường trên Vercel | Để web hiện đúng tài khoản nhận tiền. |

## 3. Tạo bảng và hàm trong database

Migration: `supabase/migrations/20261120000100_sepay_checkout_and_support.sql`. File này thêm:

- cột `amount`, `paid_at`, `payment_ref` cho `pro_upgrade_requests`
- hàm `pro_plan_price`, `start_pro_checkout`
- bảng `payment_events` (chỉ server đọc được)
- bảng `support_messages` cho nút chat hỗ trợ
- bật realtime cho `user_entitlements` và `support_messages`

**Cách A, dùng CLI:**

```powershell
npx supabase link --project-ref woejrebdstgredslznye
```

```powershell
npx supabase db push
```

**Cách B, không dùng CLI:** mở Supabase Dashboard → SQL Editor, dán toàn bộ nội dung file migration rồi bấm **Run**.

Kiểm tra: Table Editor có bảng `payment_events` và `support_messages`.

## 4. Tạo khóa bí mật cho webhook

Khóa này do **bạn tự tạo**. SePay gửi kèm khóa này trong mỗi lần gọi, và function sẽ từ chối mọi lời gọi sai khóa.

```powershell
-join ((48..57)+(65..90)+(97..122) | Get-Random -Count 40 | ForEach-Object {[char]$_})
```

Lưu chuỗi vừa tạo vào nơi an toàn (trình quản lý mật khẩu). **Không** đưa vào code, `.env` của app hay Git.

## 5. Deploy hai Edge Function và đặt secret

```powershell
npx -y supabase@3.1.0 functions deploy sepay-webhook --project-ref woejrebdstgredslznye --use-api --yes
```

```powershell
npx -y supabase@3.1.0 functions deploy support-notify --project-ref woejrebdstgredslznye --use-api --yes
```

`supabase/config.toml` đã đặt `verify_jwt = false` cho `sepay-webhook` (SePay không có token Supabase) và `verify_jwt = true` cho `support-notify`.

Đặt secret (thay giá trị trong ngoặc):

```powershell
npx supabase secrets set SEPAY_API_KEY=<khóa ở bước 4> --project-ref woejrebdstgredslznye
```

Nếu dùng luôn chat hỗ trợ gửi về mail của bạn (cần tài khoản [Resend](https://resend.com), miễn phí 3.000 mail/tháng):

```powershell
npx supabase secrets set RESEND_API_KEY=<re_...> SUPPORT_INBOX=<mail nhận hỗ trợ> --project-ref woejrebdstgredslznye
```

> Mail nhận hỗ trợ chỉ nằm trong secret của Supabase, không xuất hiện trong code hay giao diện. Khi chưa xác minh tên miền trên Resend, chỉ gửi được tới chính mail đã đăng ký Resend, nên hãy đăng ký Resend bằng mail bạn muốn nhận.

Có thể đặt secret trên Dashboard thay cho CLI: **Edge Functions → Secrets**.

## 6. Cấu hình trên trang SePay

### 6.1 Thêm webhook

SePay → **Tích hợp WebHooks** → **Thêm webhooks**:

| Ô | Giá trị |
| --- | --- |
| Đặt tên | `Smart CV Pro` |
| Bắt sự kiện | **Có tiền vào** |
| Điều kiện | Chọn đúng tài khoản ngân hàng nhận tiền |
| Gọi đến URL | `https://woejrebdstgredslznye.supabase.co/functions/v1/sepay-webhook` |
| Là WebHooks xác thực thanh toán? | **Đúng** |
| Gọi lại khi lỗi | **Có** (function đã chống trùng, gọi lại nhiều lần không sao) |
| Kiểu chứng thực | **API Key** |
| API Key | Khóa ở bước 4 |
| Request Content type | `application/json` |
| Trạng thái | Kích hoạt |

SePay sẽ gửi header `Authorization: Apikey <khóa>`, đúng với cách function kiểm tra.

### 6.2 Cấu trúc mã thanh toán (nên làm)

SePay → **Công ty** → **Cấu hình chung** → **Cấu trúc mã thanh toán**: thêm tiền tố `CVPRO`, hậu tố **9 ký tự**, gồm chữ và số.

Không bắt buộc, vì function tự tìm mã trong nội dung chuyển khoản, kể cả khi ngân hàng chèn thêm chữ hay bỏ dấu cách. Nhưng làm bước này thì trang SePay hiện đúng mã ở cột "Code" và dễ đối soát.

> Nếu tài khoản SePay dùng chung với SmartEnglish, chỉ cần thêm tiền tố `CVPRO` bên cạnh tiền tố cũ. Mỗi hệ thống có webhook riêng và chỉ nhận mã của mình. Giao dịch mã lạ được lưu là `unmatched`, không ảnh hưởng gì.

## 7. Cho app biết tài khoản nhận tiền

Ba biến này là thông tin công khai (vốn in trên mã QR):

| Biến | Ví dụ | Ghi chú |
| --- | --- | --- |
| `PAYMENT_BANK_ID` | `MBBank` | **Tên ngắn theo SePay**, xem danh sách tại `https://qr.sepay.vn/banks.json` (trường `short_name`). |
| `PAYMENT_ACCOUNT_NUMBER` | `0123456789` | Số tài khoản đã liên kết SePay. |
| `PAYMENT_ACCOUNT_NAME` | `NGUYEN VAN A` | Tên chủ tài khoản, viết hoa không dấu. |

- **Web (Vercel):** Project → Settings → Environment Variables → thêm 3 biến cho Production → **Redeploy**. `scripts/vercel_build.sh` sẽ đưa chúng vào bản build.
- **APK / chạy máy:** điền 3 biến vào file `.env` ở thư mục gốc rồi build lại.

Thiếu biến nào thì màn Pro hiện "chưa thể thanh toán" thay vì mã QR sai.

## 8. Thử trước khi mở bán

### 8.1 Thử bằng tài khoản thật, số tiền thật

1. Đăng nhập một tài khoản thử trên web, vào **Nâng cấp Pro**, chọn **1 tháng**, bấm **Thanh toán**.
2. Quét mã bằng app ngân hàng. Số tiền và nội dung đã điền sẵn, **không sửa nội dung**.
3. Trong vài giây, màn hình chuyển sang "Bạn đang dùng Pro".

### 8.2 Thử không tốn tiền (gọi webhook bằng tay)

Lấy mã của yêu cầu đang chờ (SQL Editor):

```sql
select transfer_code, amount from pro_upgrade_requests
where status = 'pending' order by created_at desc limit 5;
```

Gọi webhook giả lập giống SePay (thay `<khóa>` và `<mã>`):

```powershell
curl.exe -X POST "https://woejrebdstgredslznye.supabase.co/functions/v1/sepay-webhook" -H "Authorization: Apikey <khóa>" -H "Content-Type: application/json" -d '{\"id\": 900001, \"transferType\": \"in\", \"transferAmount\": 49000, \"content\": \"<mã> chuyen tien\"}'
```

Kết quả `{"success":true}` và tài khoản thử lên Pro. Mỗi lần thử nhớ đổi `id` (cùng `id` sẽ bị bỏ qua vì chống trùng).

### 8.3 Xem lại giao dịch

```sql
select created_at, amount, content, status, request_id
from payment_events order by created_at desc limit 20;
```

| `status` | Nghĩa |
| --- | --- |
| `matched` | Đã khớp và lên Pro. |
| `unmatched` | Không thấy mã, hoặc chuyển thiếu tiền. Cần xử lý tay. |
| `ignored` | Tiền ra khỏi tài khoản, bỏ qua. |
| `received` | Mới nhận, chưa xử lý xong (hiếm, thường do lỗi giữa chừng). |

**Duyệt tay** khi khách chuyển sai nội dung: tìm yêu cầu `pending` của khách rồi chạy

```sql
select approve_pro_request('<id yêu cầu>', 'Duyệt tay: chuyển sai nội dung');
```

## 9. Lỗi thường gặp

| Hiện tượng | Nguyên nhân và cách sửa |
| --- | --- |
| SePay báo webhook lỗi **401** | Khóa trên SePay khác `SEPAY_API_KEY`, hoặc chọn sai kiểu chứng thực. Đặt lại cho khớp. |
| Lỗi **503** | Chưa đặt secret `SEPAY_API_KEY`. |
| Lỗi **404** | Chưa deploy `sepay-webhook` hoặc sai URL. |
| Có giao dịch nhưng không lên Pro | Xem `payment_events.status`. `unmatched` là khách sửa nội dung hoặc chuyển thiếu. Duyệt tay như mục 8.3. |
| Màn Pro không hiện QR | Thiếu `PAYMENT_*` ở Vercel/`.env`, hoặc `PAYMENT_BANK_ID` không phải tên ngắn của SePay. |
| QR quét ra sai ngân hàng | `PAYMENT_BANK_ID` sai, kiểm tra lại với `banks.json`. |
| Đã thanh toán mà app chưa đổi | Tải lại trang. App kiểm tra mỗi 4 giây khi đang ở màn thanh toán. |
| Chat hỗ trợ không gửi mail | Thiếu `RESEND_API_KEY`/`SUPPORT_INBOX`, hoặc mail nhận khác mail đăng ký Resend (khi chưa xác minh tên miền). Tin nhắn vẫn được lưu, chỉ không có mail. |

## 10. An toàn

- `SEPAY_API_KEY`, `RESEND_API_KEY`, `SUPPORT_INBOX` **chỉ** để trong Supabase Secrets.
- Không bao giờ đưa `service_role` key vào app hay `.env` gốc.
- App không tự cấp Pro. Chỉ webhook (đã kiểm tra khóa) hoặc lệnh duyệt tay của bạn mới bật Pro.
- Đổi khóa webhook định kỳ: tạo khóa mới → `secrets set` → cập nhật trên SePay.

## 11. Bán cho người dùng nước ngoài

SePay/VietQR chỉ dùng được với app ngân hàng Việt Nam. Muốn bán cho khách nước ngoài, cần thêm một cổng nhận thẻ quốc tế, ví dụ Lemon Squeezy hoặc Paddle. Hai bên này tự lo thuế và chuyển tiền về tài khoản Việt Nam hoặc PayPal. Có thể làm sau, song song với SePay.
