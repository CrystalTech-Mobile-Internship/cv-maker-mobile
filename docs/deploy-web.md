# Deploy bản web lên Vercel

Bản web được build bằng `scripts/vercel_build.sh` (cấu hình trong `vercel.json`).
Vercel chỉ build khi nhánh `main` có commit mới; các nhánh khác được bỏ qua.

## 1. Kết nối lần đầu (làm một lần)

1. Đăng nhập [vercel.com](https://vercel.com) bằng tài khoản GitHub.
2. **Add New → Project → Import** repo `CrystalTech-Mobile-Internship/cv-maker-mobile`.
   Nếu không thấy repo, bấm **Adjust GitHub App Permissions** và cấp quyền cho
   tổ chức `CrystalTech-Mobile-Internship` (cần quyền quản trị tổ chức).
3. Ở màn hình cấu hình:
   - **Framework Preset:** Other (giữ nguyên, `vercel.json` đã đặt lệnh build).
   - **Root Directory:** để trống.
   - **Environment Variables** (Production): thêm các biến công khai sau, lấy
     giá trị trong file `.env` trên máy:

     | Tên | Ghi chú |
     | --- | --- |
     | `SUPABASE_ACTIVE_PROFILE` | `secondary` |
     | `SUPABASE_SECONDARY_URL` | URL project Supabase |
     | `SUPABASE_SECONDARY_ANON_KEY` | khóa publishable/anon |
     | `SUPABASE_FAILOVER` | `off` nếu project chính đang tạm dừng |
     | `PAYMENT_BANK_ID`, `PAYMENT_ACCOUNT_NUMBER`, `PAYMENT_ACCOUNT_NAME` | tùy chọn, để hiện mã VietQR |

     Không thêm khóa AI hay `service_role`: các biến này được đóng gói vào web
     nên ai cũng đọc được.
4. Bấm **Deploy**. Lần đầu mất khoảng 4–6 phút vì phải tải Flutter.
5. **Settings → Git → Production Branch:** đặt `main`.

Từ đó mỗi lần `main` có code mới, Vercel tự build và cập nhật trang.

## 2. Cho phép đăng nhập trên tên miền mới

Supabase Dashboard → **Authentication → URL Configuration**:

- **Site URL:** `https://<tên-dự-án>.vercel.app`
- **Redirect URLs:** thêm `https://<tên-dự-án>.vercel.app/**`

Thiếu bước này thì liên kết đặt lại mật khẩu và đăng nhập Google sẽ quay về
sai địa chỉ. Đăng nhập email/mật khẩu không bị ảnh hưởng.

## 3. Kiểm tra sau khi deploy

- Mở trang, đăng ký hoặc đăng nhập, tạo một CV và bấm **Lưu vào tài khoản**.
- Mở trên máy tính (giao diện thanh bên) và trên điện thoại (thanh điều hướng dưới).
- Vercel → **Deployments** để xem log nếu build lỗi.
