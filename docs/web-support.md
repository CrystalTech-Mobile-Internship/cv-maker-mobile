# Flutter Web support

## Phạm vi hiện tại

- Guest Mode, Supabase Auth và điều hướng dùng chung với mobile.
- CV được lưu offline bằng Drift + SQLite WASM trong storage của trình duyệt.
- Ảnh đại diện Web được tối ưu rồi lưu dạng data URI trong payload CV; giới hạn
  2 MB sau tối ưu để tránh làm IndexedDB và payload đồng bộ quá lớn.
- PDF A4 được render bằng cùng engine với mobile và tải qua trình duyệt.
- Gemini/Groq chỉ được gọi qua Supabase Edge Function; browser không chứa AI key.

## Asset Drift bắt buộc

- `web/sqlite3.wasm`: lấy từ release của `sqlite3` đúng phiên bản trong
  `pubspec.lock`.
- `web/drift_worker.js`: lấy từ package/release Drift đúng phiên bản.

Với phiên bản hiện tại:

- `sqlite3`: `3.5.2`.
- SHA-256 của `web/sqlite3.wasm`:
  `13d3f11d05b39ba0618a7115fb41640a5d48b6300f5d3f325f554b42bd6688a4`.
- `drift`: `2.34.4`.

## Chạy và kiểm tra

```powershell
flutter build web --debug --no-pub
flutter run -d chrome --no-pub
```

Checklist smoke test:

1. Vào Guest Mode và tạo một CV.
2. Lưu CV, reload trình duyệt và xác nhận CV vẫn còn.
3. Mở Editor, Preview và xác nhận tờ A4 render thành công.
4. Tải PDF và kiểm tra tệp bắt đầu bằng `%PDF-`.
5. Kiểm tra console không có lỗi tải `sqlite3.wasm`, worker hoặc IndexedDB.

## Lưu ý triển khai

- Server phải trả MIME type `application/wasm` cho `sqlite3.wasm`.
- Không bắt buộc bật COOP/COEP. Nếu không có SharedArrayBuffer, Drift tự dùng
  IndexedDB chậm hơn nhưng tương thích tốt hơn với popup Google OAuth.
- Dữ liệu Web thuộc từng browser profile/origin. Xóa site data sẽ xóa CV chưa
  đồng bộ, vì vậy người dùng đăng nhập nên đồng bộ cloud trước khi xóa dữ liệu
  trình duyệt.
