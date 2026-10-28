# AI Polish Summary

## Kiến trúc và bảo mật

- Flutter chỉ gọi Supabase Edge Function `polish-summary` qua session của người dùng.
- Gemini/Groq key chỉ được lưu bằng Supabase Secrets và đọc bằng `Deno.env.get`.
- Edge Function xác thực người dùng lần hai bằng `auth.getUser()` trước khi gọi AI.
- Dữ liệu đầu vào có giới hạn độ dài, giới hạn sáu yêu cầu/phút trên mỗi instance và không được ghi vào log.
- AI chỉ trả về bản đề xuất. CV chỉ thay đổi sau khi người dùng bấm **Áp dụng đề xuất**.
- **Thử lại** tạo một đề xuất mới từ cùng dữ liệu gốc; **Giữ bản gốc** không ghi dữ liệu.
- Nội dung được lưu SQLite trước; quá trình đồng bộ cloud tiếp tục theo cơ chế offline-first hiện có.
- Google OAuth chỉ thoát Guest Mode sau khi Supabase xác nhận phiên đăng nhập, không phải ngay khi mở trình duyệt.

## Cấu hình Supabase

Không đặt AI key trong `.env` của Flutter. Thiết lập secret ở backend:

```powershell
supabase link --project-ref <project-ref>
supabase secrets set GEMINI_API_KEY=<key>
supabase secrets set GEMINI_MODEL=gemini-3.5-flash-lite
supabase secrets set GROQ_API_KEY=<key>
supabase secrets set GROQ_MODEL=llama-3.3-70b-versatile
supabase functions deploy polish-summary
```

Có thể chỉ cấu hình một provider; Gemini được gọi trước và Groq là fallback.

## Checklist nghiệm thu

- Người chưa đăng nhập không gọi được AI.
- Tóm tắt dưới 40 ký tự hoặc thiếu vị trí ứng tuyển bị chặn tại ứng dụng và backend.
- Khi AI lỗi, nội dung hiện tại không thay đổi.
- Đóng preview hoặc chọn **Giữ bản gốc** không ghi dữ liệu.
- Chọn **Thử lại** gọi AI lần nữa và chỉ lưu kết quả cuối cùng được xác nhận.
- Chọn **Áp dụng đề xuất** lưu local ngay và đánh dấu CV chờ đồng bộ.
- HTTP 401, 422, 429, lỗi 5xx và timeout được ánh xạ thành thông báo an toàn cho người dùng.
- APK/repository không chứa Gemini/Groq key.
