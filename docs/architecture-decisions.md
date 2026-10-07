# QUYẾT ĐỊNH KIẾN TRÚC SMART CV MAKER MOBILE

- Trạng thái: Đã chấp thuận
- Ngày quyết định: 06/10/2026
- Phạm vi: MVP

## ADR 001 Flutter cho ứng dụng di động

**Quyết định:** Dùng Flutter và Dart để chia sẻ phần lớn mã nguồn giữa Android và iOS.

**Lý do:** Dự án cần hai nền tảng, có nhiều form, preview và xử lý PDF. Android là nền tảng kiểm thử chính; khả năng tương thích iOS vẫn được duy trì trong cấu trúc mã nguồn.

**Hệ quả:** Không viết hai ứng dụng Kotlin và Swift riêng. Những chức năng liên quan file, chia sẻ và permission phải được kiểm tra theo từng hệ điều hành.

## ADR 002 Riverpod và GoRouter

**Quyết định:** Riverpod quản lý trạng thái; GoRouter quản lý điều hướng.

**Lý do:** Trạng thái form và dữ liệu CV cần tách khỏi Widget, còn Editor/Preview phải nhận đúng `cvId`.

**Hệ quả:** Widget không truy cập database hoặc Supabase trực tiếp. Logic thay đổi dữ liệu nằm sau provider/notifier và repository.

## ADR 003 Drift và SQLite cho dữ liệu local

**Quyết định:** Drift + SQLite là nguồn dữ liệu runtime chính.

**Lý do:** Dữ liệu CV có cấu trúc, cần truy vấn, migration, kiểm thử và hoạt động offline ổn định.

**Hệ quả:** Mọi chỉnh sửa được ghi local trước. Hive không được dùng song song cho cùng dữ liệu CV. Thay đổi schema phải có version và migration.

## ADR 004 Supabase cho backend

**Quyết định:** Dùng Supabase Auth, PostgreSQL, Row-Level Security và Storage thay cho Firebase.

**Lý do:** Dữ liệu CV phù hợp với PostgreSQL và JSONB; RLS cho phép đặt quy tắc sở hữu dữ liệu ngay tại database. Supabase cũng cung cấp Auth và Storage trong cùng nền tảng.

**Hệ quả:** Mọi bảng của người dùng phải bật RLS. Ứng dụng chỉ chứa publishable/anon key; service-role key và bí mật backend không được đưa vào mobile hoặc Git.

## ADR 005 Local first và đồng bộ sau

**Quyết định:** Hoàn thiện luồng local trước khi xây sync engine.

**Lý do:** Guest Mode và chỉnh sửa offline là yêu cầu cốt lõi. Cloud không được trở thành điều kiện để người dùng tạo CV.

**Hệ quả:** Giao diện đọc từ repository local. Bản ghi chỉnh sửa có `isSynced = false`; chỉ chuyển thành đã đồng bộ khi Supabase xác nhận. Xóa offline của tài khoản được giữ trong hàng đợi xóa.

## ADR 006 Hai template và hoãn AI

**Quyết định:** MVP chỉ có Harvard ATS và Modern Minimalist. Gemini AI được hoãn đến sau khi luồng cốt lõi ổn định.

**Lý do:** Form, local storage, preview và PDF tạo nên giá trị sử dụng chính. Thêm AI hoặc nhiều template sớm làm tăng rủi ro trễ tiến độ.

**Hệ quả:** Không thêm AI SDK, prompt, quota hoặc provider fallback trong giai đoạn cốt lõi. Thiết kế repository và model không được phụ thuộc vào AI.
