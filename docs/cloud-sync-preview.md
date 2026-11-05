# ĐẶC TẢ XEM TRƯỚC ĐỒNG BỘ CLOUD VÀ XỬ LÝ AN TOÀN DỮ LIỆU — SMART CV MAKER MOBILE

- Ngày cập nhật: 04/11/2026
- Phiên bản: Cloud Sync Safety v1
- Phụ trách: Nguyễn Tuấn Anh
- Vị trí mã nguồn: `lib/features/cv_editor/domain/models/cloud_sync_preview.dart`, `lib/features/cv_management/presentation/widgets/cloud_sync_preview_sheet.dart`

---

## 1. Vấn đề cần giải quyết

Trong mô hình **Offline-First**, người dùng thường xuyên tạo và chỉnh sửa CV ngoại tuyến trên thiết bị. Khi bấm nút "Đồng bộ", nếu hệ thống tự động ghi đè hoặc xóa dữ liệu mà không cho người dùng biết trước thì có nguy cơ mất bản ghi quý giá hoặc gây hoang mang cho người dùng.

Để giải quyết triệt để rủi ro này, Phase 3 (Tuần 9) bổ sung bước **Xem trước đồng bộ có kiểm soát (Cloud Sync Preview)**.

## 2. Nguyên tắc an toàn dữ liệu

1. **Kiểm tra chỉ đọc (Read-only Inspection)**: Phương thức `inspectSyncPreview()` trong `CvSyncRepository` chỉ tải metadata các bản ghi từ Supabase và đối chiếu với SQLite cục bộ, tuyệt đối không ghi, sửa hay xóa bất kỳ dòng nào trong cơ sở dữ liệu.
2. **Minh bạch 4 chỉ số thao tác**:
   - ⬆️ **Tải lên Cloud**: Số bản ghi cục bộ mới hơn hoặc chưa từng có trên cloud.
   - ⬇️ **Tải về máy**: Số bản ghi trên cloud mới hơn.
   - ⚠️ **Xung đột**: Bản ghi được chỉnh sửa ở cả hai nơi (được dung hòa theo Last-Write-Wins UTC).
   - 🗑️ **Xóa trên Cloud**: Số bản ghi nằm trong hàng đợi xóa ngoại tuyến (`cv_deletions`).
3. **Bảo vệ bằng nút Sao lưu JSON tức thì**: Ngay trên giao diện xem trước, người dùng luôn có nút "Sao lưu JSON ra máy tính trước" để xuất file dự phòng an toàn trước khi bấm xác nhận đồng bộ.
4. **Xác nhận có điều kiện**: Nếu có xung đột hoặc thao tác xóa trên cloud, nút hành động sẽ chuyển sang màu cảnh báo và yêu cầu xác nhận rõ ràng: "Xác nhận & Tiến hành đồng bộ".
