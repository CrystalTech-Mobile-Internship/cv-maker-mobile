# ĐẶC TẢ XUẤT FILE MICROSOFT WORD (.DOCX) — SMART CV MAKER MOBILE

- Ngày cập nhật: 04/11/2026
- Phiên bản: DOCX Exporter MVP v1
- Phụ trách: Nguyễn Tuấn Anh
- Vị trí mã nguồn: `lib/features/cv_preview/`

---

## 1. Mục tiêu và bối cảnh

Trong khi file PDF giữ đúng chuẩn 100% bố cục in ấn A4, nhiều nhà tuyển dụng hoặc người dùng cá nhân muốn có một bản CV dạng file văn bản Microsoft Word (`.docx`) để:
1. Tiếp tục chỉnh sửa bổ sung tự do trên máy tính cá nhân qua Microsoft Word, LibreOffice hoặc Google Docs.
2. Tải lên một số cổng nộp hồ sơ yêu cầu bắt buộc định dạng `.docx` để hệ thống tự động bóc tách thông tin (Parser).

## 2. Giải pháp kiến trúc

- **Không thêm dependency cồng kềnh**: File `.docx` thực chất là một kho lưu trữ ZIP chứa các file XML theo đặc tả OpenXML (ECMA-376). Thay vì thêm thư viện nặng làm tăng kích thước APK vượt ngưỡng cam kết, ứng dụng tận dụng trực tiếp thư viện `archive` (đã có sẵn trong dự án).
- **Cấu trúc gói ZIP sinh ra**:
  - `[Content_Types].xml`: Khai báo MIME type cho các phần tử XML của WordprocessingML.
  - `_rels/.rels`: Định nghĩa quan hệ package.
  - `word/_rels/document.xml.rels`: Định nghĩa quan hệ tài liệu Word.
  - `word/document.xml`: Nội dung chính của CV, bao gồm tiêu đề, thông tin liên hệ, mục tiêu nghề nghiệp, học vấn, kinh nghiệm, kỹ năng, dự án và chứng chỉ.
- **Hỗ trợ Unicode tiếng Việt**: Toàn bộ nội dung văn bản được mã hóa UTF-8 chuẩn xác, các ký tự XML đặc biệt (`&`, `<`, `>`, `"`, `'`) được escape an toàn.
- **Tuân thủ thứ tự section động**: Nội dung sinh ra tuân thủ chính xác theo `cv.effectiveSectionOrder`, phản ánh thứ tự mà người dùng đã sắp xếp trong `SectionReorderSheet`.

## 3. Giao diện người dùng

Tại màn hình xem trước (`CvPreviewScreen`), khi bấm nút "Tải xuống / Chia sẻ", hộp thoại `ExportPdfDialog` cung cấp nút chọn định dạng (`SegmentedButton`):
- **PDF (.pdf)**: Ưu tiên in ấn, gửi trực tiếp, giữ nguyên đồ họa và font chữ mỹ thuật.
- **Word (.docx)**: Ưu tiên khả năng chỉnh sửa tự do trên máy tính.

Tệp sinh ra được lưu vào bộ nhớ tạm thời của thiết bị và mở bảng chia sẻ hệ thống (`SharePlus` / `Printing.sharePdf`) để người dùng lưu vào tệp hoặc gửi qua Zalo/Email.
