# Smart CV Maker Mobile

Ứng dụng Flutter giúp sinh viên, fresher và người đi làm tự tạo và tùy biến CV chuyên nghiệp đa nền tảng (**Android**, **iOS** và **Web**). Dự án xây dựng theo kiến trúc **Clean Architecture** và triết lý **Offline-First**: người dùng có thể tạo, kéo thả sắp xếp bố cục, dùng các gợi ý mẫu "Điền vào chỗ trống", phóng to/thu nhỏ cỡ chữ và xuất file **PDF vector A4** hoặc **Microsoft Word (.docx)** hoàn toàn không cần kết nối mạng. Khi đăng nhập và có mạng, ứng dụng hỗ trợ **Xem trước đồng bộ Cloud an toàn** với Supabase mà không lo mất dữ liệu cục bộ.

---

## 🚀 Trạng thái dự án (Cập nhật Tuần 9)

Dự án đã hoàn thành toàn bộ các mốc tính năng cốt lõi và mở rộng của Tuần 9:

### 1. Trải nghiệm tự làm CV chuyên nghiệp (CV Builder & Editor)
- **Kéo thả / Sắp xếp bố cục section động**: Hỗ trợ người dùng thay đổi thứ tự hiển thị của các khối nội dung (*Tóm tắt, Học vấn, Kinh nghiệm, Kỹ năng, Dự án, Chứng chỉ*) thông qua `SectionReorderSheet`. Bố cục tùy biến được lưu tự động và phản ánh chính xác lên cả bản xem trước và file xuất ra.
- **Gợi ý mẫu khởi tạo nhanh ("Điền vào mẫu" / Placeholder Fill-in)**:
  - Tích hợp hàng chip gợi ý trực tiếp ngay dưới trường Tóm tắt bản thân (*Fresher IT*, *Mobile Flutter*, *Backend Dev*, *Kinh doanh & Marketing*) — 1 chạm điền ngay mẫu câu chuẩn ATS.
  - Tích hợp nút hành động thứ cấp trong trạng thái rỗng (*Empty state*) của các tab Học vấn, Kinh nghiệm, Kỹ năng, Dự án.
  - Modal `StarterSamplePickerSheet` duyệt và áp dụng nhanh trọn bộ nội dung mẫu song ngữ (VI / EN).
- **Thanh công cụ Typography & Phóng to thu nhỏ kích thước chữ**:
  - `EditorTypographyToolbar` cho phép người dùng tự do điều chỉnh tỉ lệ font từ **75% đến 140%**, kèm các mốc nhanh (**85%**, **100%**, **115%**, **130%**) và badge hiển thị % trực tiếp.
  - Phím tắt soạn thảo nhanh: In đậm (`**`), Gạch đầu dòng (`•`), Chèn liên kết (`🔗`).
- **Thư viện kỹ năng gợi ý theo ngành nghề (`SkillBankSheet`)**: Khám phá và thêm nhanh kỹ năng 1 chạm phân theo 5 lĩnh vực chuyên môn (*Mobile, Frontend, Backend, Data/AI, Kỹ năng mềm*), tự động đánh dấu các kỹ năng đã có trong hồ sơ.
- **Ngân hàng từ khóa hành động ATS & Công thức Google XYZ (`AtsActionVerbsSheet`)**: Cung cấp danh mục động từ hành động mạnh mẽ (*Phát triển, Tối ưu hóa, Triển khai, Dẫn dắt, Đo lường...*) kèm hướng dẫn cấu trúc câu chuẩn quốc tế giúp ứng viên viết bullet point gây ấn tượng.
- **Kho 17 Mẫu CV đa dạng**: 14 template Free (*Harvard ATS, Modern Minimalist, Tech Lead, Executive, Compact, ...*) và 3 template Pro với hệ màu sắc và bố cục phong phú.
- **Không gian xem trước tương tác (Interactive Preview & Drag-and-Drop Workspace)**:
  - Chế độ kép chuyển đổi linh hoạt: **[📄 Trang A4 (PDF)]** ↔ **[🔀 Bố cục kéo thả]**.
  - Kéo thả sắp xếp trực tiếp các section trên màn hình xem trước (`CvInteractiveSectionReorder`), tự động lưu SQLite và cập nhật tức thì vào bản in.
  - Bộ sưu tập đổi mẫu CV 1-chạm (`TemplateGallerySheet`) và bảng chọn 8 màu sắc chủ đạo (`CvPreviewColorSheet`) ngay tại màn hình xem trước.
  - Huy hiệu điểm ATS và checklist 8 tiêu chí chuẩn tuyển dụng quốc tế.
  - Tối ưu bố cục & Căn chỉnh 1 trang A4 (`CvPageFitSheet`): Preset 85% Auto-fit 1 trang tránh rớt dòng lẻ loi, kèm lời khuyên chuyên môn từ HR.
  - Bật / tắt ẩn hiện mục CV linh hoạt: Nút mắt ẩn/hiện trực tiếp trên thẻ mục, xuất PDF và Word tự động loại bỏ mục ẩn qua `visibleSectionOrder`.
  - Đối chiếu từ khóa JD tuyển dụng (`CvJdMatcherSheet`): Đánh giá độ tương thích % ATS với tin tuyển dụng, phân tích từ khóa đã có và gợi ý thêm từ khóa còn thiếu.
  - Giả lập in ấn đen-trắng (B&W Grayscale Simulation): Kiểm tra độ sắc nét và tương phản của tài liệu khi HR in ra máy in laser văn phòng.

### 2. Đầu ra tài liệu đa định dạng (PDF Vector & Microsoft Word DOCX)
- **Xuất PDF Vector A4 sắc nét**: Hỗ trợ hiển thị chuẩn kích thước A4 (595.28 × 841.89 pt), ngắt trang thông minh, nhúng ảnh đại diện và font tiếng Việt Unicode đầy đủ.
- **Xuất Microsoft Word (.docx) MVP**: Tự động đóng gói cấu trúc ZIP OpenXML chuẩn Microsoft Word, chạy 100% offline, 0MB bloatware, cho phép mở và tự do chỉnh sửa trên Microsoft Word, Google Docs hoặc LibreOffice.
- **Hộp thoại chọn định dạng xuất**: `ExportPdfDialog` cho phép lựa chọn linh hoạt giữa PDF (giữ nguyên layout đồ họa) và Word (ưu tiên chỉnh sửa trên máy tính).

### 3. Đồng bộ Cloud có kiểm soát & Bảo vệ dữ liệu (Safe Cloud Sync)
- **Xem trước đồng bộ Cloud (`CloudSyncPreviewSheet`)**: Đối chiếu dữ liệu read-only trước khi ghi:
  - ⬆️ Số CV tải lên Cloud (bản sửa trên máy mới hơn)
  - ⬇️ Số CV tải về máy (bản trên cloud mới hơn)
  - ⚠️ Số CV xung đột (giải quyết an toàn theo Last-Write-Wins)
  - 🗑️ Số CV xóa trên Cloud theo hàng đợi
- **Bảo toàn dữ liệu Local-First**: SQLite trên máy luôn là nguồn dữ liệu chính. Tích hợp nút **"Sao lưu JSON ra máy tính trước"** ngay trên dialog xem trước trước khi thực hiện đồng bộ.

### 4. Sao lưu & Nhập CV từ tài liệu cũ
- **Sao lưu / Phục hồi offline**: Xuất toàn bộ CV ra file JSON có đánh dấu phiên bản và khôi phục không ghi đè.
- **Nhập CV từ Word (.docx) & PDF**: Trích xuất thông tin tự động và hiển thị qua hộp thoại xem lại (`ResumeImportReviewDialog`).

### 5. Hỗ trợ đa nền tảng (Android, iOS & Web)
- Android & iOS: SQLite cục bộ qua Drift Native.
- Web: Drift Web Worker + SQLite WASM lưu trữ an toàn trong IndexedDB/OPFS.

---

## 🛠 Công nghệ sử dụng

- **Flutter 3.x & Dart 3.x**: Cross-platform mobile & web development.
- **Riverpod (StateNotifier / Provider)**: Quản lý trạng thái phân tầng, phản ứng nhanh.
- **GoRouter**: Điều hướng khai báo (declarative routing), hỗ trợ deep-linking và URL Web.
- **Drift (SQLite) & sqlite3.wasm**: Cơ sở dữ liệu quan hệ cục bộ cho offline-first caching và đồng bộ.
- **Supabase**: Backend-as-a-Service (PostgreSQL, Row-Level Security, Supabase Auth email/Google).
- **PDF & Printing**: Kết xuất tài liệu PDF vector khổ A4 và xem trước tương tác.
- **Archive**: Đóng gói và trích xuất OpenXML ZIP phục vụ đọc/ghi file Microsoft Word (`.docx`).

---

## 📐 Kiến trúc phần mềm (Clean Architecture)

```text
lib/
├── app/                  # Theme, Router và cấu hình ứng dụng
├── core/                 # Cấu hình Database (Drift), Supabase, hằng số
└── features/
    ├── auth/             # Đăng nhập, đăng ký, phiên đăng nhập, Guest Mode
    ├── cv_management/    # Màn hình chính Dashboard, danh mục mẫu CV, Cloud Sync Card & Preview
    ├── cv_editor/        # Editor đa tab, thanh công cụ Typography, Reorder Sheet, Starter Samples
    ├── cv_preview/       # Xem trước A4, dịch vụ xuất PDF vector và Microsoft Word (.docx)
    ├── cv_backup/        # Dịch vụ xuất/nhập sao lưu JSON ngoại tuyến
    ├── resume_import/    # Đọc và phân tích hồ sơ cũ từ DOCX/PDF
    └── ai_tools/         # Điều phối và giao diện gợi ý AI Summary
```

Mỗi feature tuân thủ nghiêm ngặt 3 tầng:
1. **Domain**: Models, Use cases, Repository Interfaces (độc lập hoàn toàn với framework và thư viện ngoài).
2. **Data**: Data sources (SQLite Drift, Supabase REST), Repositories Implementation, Mappers.
3. **Presentation**: Screens, Widgets, Riverpod Controllers/Notifiers.

---

## 💻 Yêu cầu môi trường & Cài đặt

- Flutter SDK `^3.11.4` (hoặc mới hơn).
- Dart SDK `^3.11.0`.
- Android Studio / VS Code có Flutter Extension.
- Thiết bị thật Android (Samsung Galaxy A11 hoặc tương đương) / Máy ảo Android / Trình duyệt Chrome cho Web.

### Cài đặt mã nguồn

```bash
git clone https://github.com/CrystalTech-Mobile-Internship/cv-maker-mobile.git
cd cv-maker-mobile
flutter pub get
```

### Cấu hình biến môi trường (`.env`)

Sao chép file mẫu và cấu hình:

PowerShell:
```powershell
Copy-Item .env.example .env
```

macOS/Linux:
```bash
cp .env.example .env
```

Điền các thông số Supabase của dự án vào `.env`. Khi chưa có thông số, ứng dụng tự động chạy ở **Chế độ Khách (Guest Mode)** hoàn toàn bình thường.

### Chạy ứng dụng

- Chạy trên thiết bị di động (Android / iOS):
  ```bash
  flutter run
  ```
- Chạy trên trình duyệt Web:
  ```bash
  flutter run -d chrome
  ```

---

## 🧪 Kiểm tra chất lượng & Test Suite

Chạy phân tích tĩnh mã nguồn:
```bash
dart analyze lib
```

Chạy toàn bộ kiểm thử tự động:
```bash
flutter test
```

Chạy riêng các nhóm kiểm thử tính năng:
- **CV Editor & Tools**: `flutter test test/features/cv_editor/`
- **PDF & Word (.docx) Export**: `flutter test test/features/cv_preview/`
- **Cloud Sync & Safety**: `flutter test test/features/cv_management/`

---

## 📚 Tài liệu chi tiết trong dự án

- [Kế hoạch & Phân công Tuần 9](internship-notes/week/week9/week09_plan.md)
- [Báo cáo hoàn thiện DOCX, Sync Preview & Section Reorder](internship-notes/week/week9/day03_sync_preview_docx_and_section_reorder.md)
- [Đặc tả yêu cầu phần mềm (SRS)](docs/requirements.md)
- [Luồng người dùng MVP](docs/mvp-flow.md)
- [Sao lưu và khôi phục CV ngoại tuyến](docs/local-backup.md)
- [Nhập CV từ Word/PDF](docs/resume-import.md)
- [Hướng dẫn và kiến trúc Web](docs/web-support.md)
- [Quy trình phối hợp Coding Agent](docs/agent-workflow.md)

---

## 👥 Nhóm thực hiện

- **Nguyễn Tuấn Anh** — Fullstack Mobile Engineer (Trải nghiệm ứng dụng, Editor & Bố cục, Đầu ra PDF/DOCX, Sync Preview & Backup).
- **Nguyễn Hoàng Phong** — Fullstack Mobile Engineer (Supabase Backend, Migration, RLS, Edge Functions).

*Dự án thực tập doanh nghiệp (Internship 2026).*
