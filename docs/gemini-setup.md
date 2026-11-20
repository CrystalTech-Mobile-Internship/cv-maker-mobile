# Thêm Gemini cho trợ lý AI

Hàm `cv-assistant` thử lần lượt từng model:

1. Các model Gemini trong `GEMINI_MODELS` (nếu có `GEMINI_API_KEY`).
2. Sau đó tới các model OpenRouter trong `OPENROUTER_MODELS`.

Model nào báo hết lượt (lỗi 429) sẽ bị bỏ qua khoảng 1 phút, hoặc lâu hơn nếu Google báo thời gian chờ. Trong lúc đó hệ thống dùng model kế tiếp. Nếu tất cả model đều đang nghỉ, hệ thống vẫn thử lại hết.

## 1. Lấy key

1. Vào <https://aistudio.google.com/apikey> và đăng nhập bằng Google.
2. Bấm **Create API key** rồi copy key.

Không dán key vào file `.env` ở thư mục gốc, vì file đó được đóng gói vào app.

## 2. Xem tên model đang có

Vào <https://ai.google.dev/gemini-api/docs/models> để xem tên model và hạn mức miễn phí (mục *Rate limits*). Chọn vài model, xếp model tốt nhất lên đầu.

## 3. Lưu lên Supabase

Chạy trong thư mục `cv-maker-mobile`:

```powershell
npx supabase secrets set "GEMINI_API_KEY=key_vừa_copy" "GEMINI_MODELS=gemini-2.5-flash,gemini-2.5-flash-lite,gemini-2.0-flash" --project-ref woejrebdstgredslznye
```

Hoặc vào **Supabase → Edge Functions → Secrets** và thêm 2 dòng `GEMINI_API_KEY` và `GEMINI_MODELS`.

Không cần deploy lại: function đọc secret mới ở lần gọi kế tiếp.

## 4. Kiểm tra

Dùng một tính năng AI trong app, chẳng hạn "Trò chuyện tạo CV". Sau đó mở log của function `cv-assistant` trên Supabase. Mỗi lần gọi thành công, kết quả có trường `model` cho biết model nào đã trả lời.

## Ghi chú

- Muốn bỏ Gemini thì xóa secret `GEMINI_API_KEY`. Hệ thống quay về chỉ dùng OpenRouter.
- Với gói miễn phí, Google có thể dùng nội dung gửi lên để cải thiện sản phẩm. Nếu cần chặt hơn, hãy bật thanh toán cho project Google Cloud.
