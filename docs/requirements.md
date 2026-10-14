# ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS) — SMART CV MAKER MOBILE

* **Dự án:** Smart CV Maker Mobile (Ứng dụng Di động Tạo & Tối ưu hóa CV Thông minh)
* **Phiên bản:** v1.0.0
* **Tài liệu lưu trữ:** `cv-maker-mobile/docs/requirements.md`
* **Nhóm thực hiện:** Nguyễn Tuấn Anh (Fullstack Mobile Engineer) & Nguyễn Hoàng Phong (Fullstack Mobile Engineer)
* **Nền tảng mục tiêu:** Cross-platform (Android & iOS)

---

## 1. TỔNG QUAN DỰ ÁN (PROJECT OVERVIEW)

| Thuộc tính | Chi tiết kỹ thuật |
| :--- | :--- |
| **Phân loại ứng dụng** | Productivity / Career Tool / Document Creator |
| **Công nghệ cốt lõi** | **Flutter 3.x (Dart 3.x)** hỗ trợ cả Android và iOS |
| **Cơ sở dữ liệu đám mây** | **Supabase Cloud** (PostgreSQL 15+, Row-Level Security, Storage Buckets, Auth) |
| **Lưu trữ cục bộ** | **Drift + SQLite** (mô hình Offline-First, tự động lưu nháp Auto-Save) |
| **Động cơ tài liệu** | **Flutter PDF Engine (`pdf` & `printing`)** — Kết xuất PDF Vector chuẩn A4, ngắt trang thông minh |
| **Trí tuệ nhân tạo (AI)**| **Google Gemini API** dự kiến cho giai đoạn sau MVP cốt lõi; không chặn nghiệm thu luồng chính |
| **Quản lý trạng thái** | **Riverpod** (StateNotifier / AsyncNotifier) |

---

### 1.1. Phạm vi MVP đã được nhóm xác nhận ngày 06/10/2026

- Ứng dụng hỗ trợ cả Guest Mode, đăng ký, đăng nhập và quên mật khẩu.
- MVP có bốn template Free: Harvard ATS, Modern Minimalist, Minimalist Clean và Creative Tech.
- Xuất PDF A4 và chia sẻ bằng System Share Sheet là chức năng bắt buộc.
- Dữ liệu được lưu local bằng Drift + SQLite trước; đồng bộ Supabase triển khai sau khi luồng local ổn định.
- Gemini AI được hoãn đến sau khi các chức năng cốt lõi đạt tiêu chí nghiệm thu.
- Không nhập CV từ PDF hoặc Word trong MVP.
- Giao diện MVP dùng tiếng Việt.
- Android là nền tảng kiểm thử chính. Mã nguồn vẫn phải tương thích iOS, nhưng chưa bắt buộc tạo bản build iOS khi nhóm không có macOS.

Chi tiết ranh giới phạm vi được lưu tại `docs/mvp-scope.md`.

---

## 2. BÀI TOÁN & GIÁ TRỊ MANG LẠI (PROBLEM STATEMENT)

Sinh viên mới tốt nghiệp, fresher và người đi làm thường gặp khó khăn khi tạo hồ sơ xin việc (CV):
1. **Thiếu công cụ di động tiện lợi:** Đa phần công cụ tạo CV trực tuyến hiện nay tối ưu cho máy tính, giao diện trên điện thoại bị vỡ hoặc khó thao tác khi đang di chuyển.
2. **Khó khăn trong diễn đạt kinh nghiệm:** Ứng viên thường viết mô tả công việc chung chung, thiếu số liệu định lượng, không đúng chuẩn của các hệ thống lọc hồ sơ tự động (ATS - Applicant Tracking System).
3. **Lỗi định dạng khi xuất file:** Các ứng dụng di động thông thường xuất file ảnh chất lượng thấp, hoặc xuất PDF bị lỗi phông chữ tiếng Việt, tràn lề, cắt ngang dòng chữ giữa hai trang A4.

**Smart CV Maker Mobile** giải quyết triệt để các vấn đề trên thông qua quy trình chuẩn:
```
Nhập liệu Form động (Offline) ➔ Tự động gắn vào Template chuẩn ATS ➔ Live Preview ➔ Xuất PDF Vector A4 sắc nét ➔ Chia sẻ tức thì
```

---

## 3. ĐỐI TƯỢNG NGƯỜI DÙNG & MỤC TIÊU (USER PERSONAS & GOALS)

### 3.1. Đối tượng người dùng
* **Sinh viên / Fresher:** Cần tạo CV chuẩn chỉnh để ứng tuyển thực tập/việc làm đầu tiên, cần sự hỗ trợ của AI để gợi ý cách viết tóm tắt bản thân và các kỹ năng quan trọng.
* **Người đi làm bận rộn:** Cần chỉnh sửa nhanh thông tin liên hệ, cập nhật kinh nghiệm ngay trên điện thoại khi nhận được cơ hội việc làm gấp.
* **Người tìm việc quốc tế:** Cần CV bố cục chuẩn ATS (Academic / Minimalist) theo tiêu chuẩn tuyển dụng toàn cầu.

### 3.2. Mục tiêu người dùng (User Goals)
* **UG-01:** Tôi muốn tạo mới và quản lý nhiều bản CV khác nhau trực tiếp trên điện thoại.
* **UG-02:** Tôi muốn ứng dụng tự động lưu dữ liệu ngay cả khi mất mạng hoặc lỡ tay tắt app.
* **UG-03 (sau MVP):** Tôi muốn được AI gợi ý cách diễn đạt kinh nghiệm làm việc chuyên nghiệp (Action Verbs + Metrics + Impact).
* **UG-04:** Tôi muốn chuyển đổi giữa các mẫu Free mà không bị mất dữ liệu đã nhập.
* **UG-05:** Tôi muốn xem trước tài liệu như bản in thật trên khổ A4 trước khi quyết định xuất file.
* **UG-06:** Tôi muốn xuất file PDF vector sắc nét không lỗi font tiếng Việt và chia sẻ trực tiếp qua Zalo/Email.

---

## 4. DANH MỤC 25 TÍNH NĂNG CHI TIẾT (FEATURE BREAKDOWN)

### Nhóm 1: Quản lý CV & Form nhập liệu động (Mobile Core)
* **F01 - Dashboard CV Manager:** Xem danh sách CV, trạng thái trống (Empty State), tạo mới, đổi tên, sao chép (Duplicate) và xóa CV.
* **F02 - Form Thông tin cá nhân:** Họ tên, vị trí ứng tuyển, email, số điện thoại, địa chỉ, liên kết mạng xã hội (LinkedIn/GitHub), chọn và cắt ảnh chân dung 1:1.
* **F03 - Form Tóm tắt nghề nghiệp (Summary):** Ô nhập văn bản đa dòng kèm bộ đếm từ và gợi ý văn mẫu theo ngành.
* **F04 - Form Học vấn (Education):** Thêm/xóa động nhiều trường học, bằng cấp, chuyên ngành, thời gian và điểm số/thành tích.
* **F05 - Form Kinh nghiệm (Work Experience):** Thêm/xóa nhiều vị trí công tác, tên công ty, thời gian làm việc, checkbox "Hiện đang làm việc tại đây", danh sách các gạch đầu dòng mô tả nhiệm vụ.
* **F06 - Form Kỹ năng (Skills):** Nhập kỹ năng dạng Tag-Chip hiện đại, phân loại nhóm (Hard/Soft skills), thanh trượt mức độ thông thạo.
* **F07 - Form Dự án & Hoạt động (Projects):** Tên dự án, vai trò, công nghệ sử dụng, đường dẫn Demo/Source code.
* **F08 - Kéo-thả sắp xếp danh mục (Reorder):** Thay đổi linh hoạt thứ tự hiển thị của các section hoặc các mục con theo ý muốn.

### Nhóm 2: Hệ thống Mẫu & Động cơ kết xuất PDF (Template & PDF Engine)
* **F09 - Động cơ PDF Vector chuẩn A4:** Kết xuất văn bản và hình ảnh theo tọa độ vector, độ phân giải cao không bị vỡ hạt khi in ấn.
* **F10 - Thuật toán Ngắt trang thông minh (Smart Pagination):** Tự động tính toán chiều cao khối nội dung để phân tách nhiều trang A4, chống cắt đôi dòng chữ hoặc để tiêu đề lẻ loi cuối trang.
* **F11 - Mẫu Template 01 (Harvard Academic):** Bố cục 1 cột truyền thống, tối ưu máy quét ATS, đường kẻ phân cách sắc sảo.
* **F12 - Mẫu Template 02 (Modern Minimalist):** Bố cục 2 cột bất đối xứng (Sidebar thông tin/kỹ năng + Nội dung kinh nghiệm).
* **F13 - Mẫu Template 03 (Minimalist Clean — Free):** Phong cách Châu Âu thanh lịch, thoáng đãng, phù hợp giáo dục, y tế và hỗ trợ ảnh đại diện tuỳ chọn.
* **F14 - Mẫu Template 04 (Creative Tech — Free):** Thiết kế có màu nhấn dành cho ngành Công nghệ/Sáng tạo và hỗ trợ ảnh đại diện tuỳ chọn.
* **F15 - Live Preview tương tác:** Trình xem trước PDF tương tác thời gian thực (phóng to, thu nhỏ, xoay trang).
* **F16 - Bộ điều khiển giao diện (Styling Controls):** Đổi màu chủ đạo (Color Palette), tùy biến kích cỡ chữ (Font size) và khoảng cách dòng.

### Nhóm 3: Đám mây, Dữ liệu, Trợ lý AI & Tương tác Hệ thống
* **F17 - Cơ sở dữ liệu quan hệ PostgreSQL:** Lược đồ CSDL chuẩn hóa trên Supabase Cloud quản lý người dùng, CV và sections.
* **F18 - Bảo mật Row-Level Security (RLS):** Phân quyền nghiêm ngặt ở tầng CSDL, cô lập dữ liệu người dùng tuyệt đối (`auth.uid() = user_id`).
* **F19 - Supabase Storage Buckets:** Lưu trữ ảnh đại diện người dùng và tệp PDF xuất bản an toàn.
* **F20 - Đồng bộ hóa Đám mây (Cloud Sync):** Tự động đồng bộ 2 chiều giữa cơ sở dữ liệu Drift/SQLite trên máy và Supabase khi có kết nối Internet.
* **F21 - AI Polish Summary (sau MVP):** Dùng Google Gemini viết lại đoạn tóm tắt nghề nghiệp hấp dẫn dựa trên thông tin ứng viên.
* **F22 - AI Bullet Point Enhancer (sau MVP):** Nâng cấp câu mô tả kinh nghiệm theo công thức quốc tế: *Action Verb + Metric + Impact*.
* **F23 - AI ATS Scoring & Keyword Matcher (sau MVP):** So khớp từ khóa trong CV với mô tả công việc (Job Description) để chấm điểm phù hợp.
* **F24 - Tập dữ liệu mẫu (Seed Data):** Cung cấp sẵn 3 bản CV mẫu chất lượng cao cho người dùng tham khảo.
* **F25 - Tích hợp Hệ thống (Share & Print) & CI/CD:** Chia sẻ file PDF trực tiếp qua Zalo/Email, in không dây và kiểm thử tự động trên GitHub Actions.

---

## 5. CẤU TRÚC DỮ LIỆU CỐT LÕI (CORE DATA MODELS)

```
┌────────────────────────────────────────────────────────┐
│                        CvModel                         │
├────────────────────────────────────────────────────────┤
│ • id: String (UUID)                                    │
│ • userId: String (Nullable - Guest mode)               │
│ • title: String ("CV Lập Trình Viên Flutter")          │
│ • templateId: String ("harvard" | "modern" | ...)      │
│ • primaryColor: String ("#1E293B")                     │
│ • fontSizeScale: Double (1.0)                          │
│ • personalInfo: PersonalInfoModel                      │
│ • summary: String                                      │
│ • educations: List<EducationModel>                     │
│ • experiences: List<ExperienceModel>                   │
│ • skills: List<SkillModel>                             │
│ • projects: List<ProjectModel>                         │
│ • isSynced: Boolean                                    │
│ • updatedAt: DateTime                                  │
└────────────────────────────────────────────────────────┘
```

---

## 6. YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS)

| Tiêu chí | Yêu cầu kỹ thuật |
| :--- | :--- |
| **Hiệu năng (Performance)** | • Thời gian khởi động app: `< 2 giây`.<br>• Thời gian kết xuất file PDF A4: `< 1.5 giây`.<br>• Trợ lý AI phản hồi: `< 3 giây` (có loading indicator). |
| **Dung lượng (Footprint)** | • Gói cài đặt APK phát hành: `< 35 MB`.<br>• File PDF xuất ra: `< 2.5 MB` (đạt chuẩn gửi đính kèm email).<br>• Mức chiếm dụng RAM khi render PDF: `< 120 MB`. |
| **Độ tin cậy & Ngoại tuyến** | **Offline-First 100%:** Người dùng hoàn toàn có thể tạo, chỉnh sửa và xuất file PDF bình thường khi ở chế độ máy bay (không có kết nối mạng). |
| **Bảo mật dữ liệu** | • Khóa API Gemini và Supabase Service Key bảo mật tuyệt đối qua biến môi trường.<br>• Supabase RLS ngăn chặn triệt để hành vi can thiệp trái phép giữa các người dùng. |
| **Khả năng tương thích** | Hoạt động mượt mà trên Android 8.0 (API 26) đến Android 16+ và iOS 15+. |

---

## 7. QUY TẮC AN TOÀN TRÍ TUỆ NHÂN TẠO (AI SAFETY PRINCIPLES)

1. **Nguyên tắc Trung thực (No Hallucination):** AI chỉ đóng vai trò hỗ trợ biên tập, trau chuốt câu từ và gợi ý từ khóa. AI tuyệt đối không tự bịa đặt trường học, công ty hoặc chứng chỉ mà người dùng chưa từng cung cấp.
2. **Quyền quyết định của Người dùng (User-in-the-loop):** Mọi kết quả do AI sinh ra phải được hiển thị trong hộp thoại xem trước (Preview Dialog). Chỉ khi người dùng bấm "Áp dụng vào CV", dữ liệu mới được lưu vào Form.
3. **Bảo vệ quyền riêng tư:** Dữ liệu gửi lên AI API chỉ bao gồm thông tin nghề nghiệp/kỹ năng cần tối ưu, không gửi các dữ liệu định danh nhạy cảm (số CCCD, mật khẩu, thông tin tài chính).

---

## 8. CHIẾN LƯỢC TÍCH HỢP TRÍ TUỆ NHÂN TẠO & CÁC NHÀ CUNG CẤP API MIỄN PHÍ

Để đảm bảo ứng dụng luôn hoạt động ổn định, không phụ thuộc vào một nhà cung cấp duy nhất và không phát sinh chi phí trong quá trình thực tập, kiến trúc AI của dự án áp dụng chiến lược đa nhà cung cấp (Multi-provider Fallback Strategy):

| Nhà cung cấp AI | Mô hình sử dụng | Tốc độ xử lý | Yêu cầu thẻ tín dụng | Hạn mức miễn phí | Vai trò trong dự án |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **Google Gemini** *(AI Studio)* | Gemini 1.5 Flash / 2.0 Flash | Nhanh (~1.5s) | ❌ Không | 15 RPM (Request/Phút), 1.500 RPD | **Nhà cung cấp Chính (Primary)**: Tiếng Việt tự nhiên, context lớn. |
| **Groq Cloud** *(console.groq.com)* | Llama 3.3 70B Versatile, Llama 3.1 8B | ⚡ Siêu tốc (< 0.8s) | ❌ Không | 30 RPM, hàng nghìn request/ngày | **Dự phòng cấp 1 (Fast Fallback)**: Tốc độ LPU tức thì, chuẩn OpenAI. |
| **OpenRouter** *(openrouter.ai)* | `llama-3.3-70b:free`, `deepseek-r1:free` | Khá (~2-3s) | ❌ Không | Miễn phí các model gắn tag `:free` | **Dự phòng cấp 2 (Multi-model)**: Đa dạng mô hình suy luận sâu. |
| **GitHub Models** | GPT-4o mini, Phi-3, Mistral Large | Nhanh (~1.5s) | ❌ Không | Hạn mức theo GitHub Token | **Thử nghiệm đối soát (Testing & Benchmarking)** |
| **Cohere** *(cohere.com)* | Command R | Khá (~2s) | ❌ Không | Trial Key: 20 calls/phút, 1.000 calls/tháng | **Phân tích văn bản & Trích xuất từ khóa** |

### 8.1. Cơ chế Chuyển đổi Dự phòng Tự động (Failover Mechanism)
```
Ứng viên yêu cầu tối ưu CV
           ↓
Gọi Google Gemini Flash (Primary)
           ↓
   [Thành công?] ──Có──> Trả kết quả về giao diện cho người dùng
           │
         Không (Lỗi 429 Quota / Timeout > 5s)
           ↓
Tự động chuyển sang Groq Llama 3.3 (Fallback)
           ↓
   [Thành công?] ──Có──> Trả kết quả về giao diện cho người dùng
           │
         Không
           ↓
Thông báo lỗi thân thiện & gợi ý người dùng thử lại
```

---

## 9. CHIẾN LƯỢC ĐA NỀN TẢNG (CROSS-PLATFORM & WEB) VÀ MÔ HÌNH THƯƠNG MẠI HÓA (FREEMIUM)

### 9.1. Kiến trúc Đa nền tảng (Android, iOS & Web)
Để tối ưu hóa trải nghiệm người dùng và thuyết phục Hội đồng chuyên môn, dự án triển khai theo kiến trúc **Adaptive Multiplatform** từ một codebase Flutter duy nhất:
* **Mobile (Android & iOS):** Màn hình cảm ứng dọc (360px - 430px), tối ưu cho thao tác một tay, điều hướng dạng Wizard/Tabs, xem trước PDF qua BottomSheet hoặc Preview Screen riêng.
* **Web (Desktop/Tablet Browser):** Màn hình ngang (>= 900px), tự động chuyển sang bố cục **Split-View**:
  - **Cột trái (45%):** Form chỉnh sửa CV động (Accordion/Tabs cho Thông tin, Kinh nghiệm, Học vấn, Kỹ năng).
  - **Cột phải (55%):** Khung Live Preview A4 hiển thị theo thời gian thực (Realtime Hot Canvas). Khi người dùng gõ phím bên trái, tờ giấy A4 bên phải cập nhật tức thì.
  - **Thanh điều hướng trên (Top Bar):** Đổi màu sắc, chọn Template, nút In ấn trực tiếp, nút Xuất PDF và nút **"Nâng cấp PRO 💎"**.
* **Đồng bộ cơ sở dữ liệu trên Web:** Sử dụng `drift_flutter` hỗ trợ Web WASM (WebAssembly SQLite) kết hợp Supabase Cloud Realtime để dữ liệu chỉnh sửa trên Web và Điện thoại tự động đồng bộ qua lại.

### 9.2. Mô hình Thương mại hóa Freemium & Cổng thanh toán VietQR

Nhằm chứng minh tính khả thi thương mại và bài toán sản phẩm thực tế, ứng dụng áp dụng mô hình phân tầng dịch vụ (Tiering Model):

| Tiêu chí | Gói Miễn Phí (FREE) | Gói Chuyên Nghiệp (PRO / VIP) |
| :--- | :--- | :--- |
| **Giá thành** | **0 VNĐ** | **49.000 VNĐ / tháng** hoặc **99.000 VNĐ vĩnh viễn** |
| **Số lượng bản CV** | Tối đa 2 bản CV | **Không giới hạn** |
| **Kho mẫu Template** | 4 mẫu Free trong MVP | Các mẫu Premium bổ sung trong giai đoạn sau |
| **Độ nét PDF** | Xuất PDF tiêu chuẩn | **Xuất PDF Vector A4 sắc nét tối đa** |
| **Watermark** | Có dòng watermark nhỏ: *"Tạo bởi Smart CV Maker"* | **Không có Watermark (Bản in sạch 100%)** |
| **Trợ lý AI** | 3 lượt dùng thử AI gợi ý cơ bản | **Không giới hạn lượt dùng AI** |
| **AI ATS Matcher** | Không hỗ trợ | **Hỗ trợ không giới hạn**: Dán JD tuyển dụng để chấm điểm và trích xuất từ khóa |

### 9.3. Quy trình Tích hợp Thanh toán VietQR Tự động (PayOS / SePay)
Thay vì sử dụng Google/Apple In-App Purchase phức tạp và bị khấu trừ 30%, hệ thống tích hợp luồng thanh toán QR chuẩn Open Banking Việt Nam:
1. Người dùng bấm **"Nâng cấp PRO"** trên màn hình Mobile hoặc Web.
2. Hệ thống gọi API (PayOS / SePay) tạo giao dịch thanh toán kèm mã giao dịch động (VD: `PRO_CV_USER123`).
3. Ứng dụng hiển thị **Mã VietQR động** kèm số tiền và nội dung chuyển khoản tự động điền sẵn.
4. Người dùng quét mã trên ứng dụng ngân hàng và chuyển tiền.
5. Cổng thanh toán gửi **Webhook** về Supabase Database / Edge Function để xác thực giao dịch thành công.
6. Trường `is_pro = true` trong bảng `profiles` được cập nhật; ứng dụng tự động mở khóa toàn bộ quyền lợi PRO trong vòng 3 giây mà không cần người dùng thao tác lại.

---

## 10. MỞ RỘNG BẢNG TÍNH NĂNG CHI TIẾT (EXTENDED FEATURES)

* **F26 - Mô hình Tài khoản Pro & Thanh toán VietQR:** Hệ thống kiểm soát tính năng Freemium, hiển thị Paywall Dialog, tạo mã VietQR động và lắng nghe trạng thái nâng cấp tài khoản tự động.
* **F27 - Giao diện Adaptive Web Split-View:** Bố cục chia đôi màn hình trên trình duyệt Web/Tablet, hỗ trợ Live Preview A4 thời gian thực song song với Form nhập liệu.
* **F28 - Trợ lý AI ATS Scorer & JD Matcher:** Cho phép người dùng nhập bản mô tả công việc (Job Description) từ nhà tuyển dụng, AI phân tích so khớp, chấm điểm % phù hợp và đề xuất từ khóa kỹ năng còn thiếu.
* **F29 - Động cơ CV Song ngữ (English & Tiếng Việt) & Xuất PDF Tiếng Anh Chuẩn Quốc Tế:** Hỗ trợ tạo và kết xuất bản in PDF 100% bằng tiếng Anh chuẩn ATS chuyên ngành kỹ thuật (từ tiêu đề mục, mốc thời gian, kỹ năng, đến nội dung tóm tắt và dự án), đáp ứng trọn vẹn nhu cầu ứng tuyển của sinh viên ngành CNTT/Kỹ thuật vào các doanh nghiệp công nghệ toàn cầu.

---

## 11. ĐẶC TẢ ĐỘNG CƠ CV SONG NGỮ (BILINGUAL RESUME ENGINE)

Đối với sinh viên ngành Kỹ thuật / Công nghệ thông tin, ứng tuyển các vị trí như Software Engineer, Data Engineer, DevOps, AI Engineer hầu hết đều yêu cầu nộp hồ sơ xin việc (Resume/CV) hoàn toàn bằng **tiếng Anh**:

### 11.1. Chuẩn hóa Tiêu đề & Cấu trúc Bản in PDF Tiếng Anh (English Template Section Mapping)
Khi người dùng chọn chế độ CV Tiếng Anh (`cvLanguage = 'en'`), toàn bộ các thành phần trên bản vẽ PDF A4 được tự động dịch chuyển sang chuẩn mực ATS quốc tế:

| Thành phần CV | Hiển thị Bản in Tiếng Việt (🇻🇳 vi) | Hiển thị Bản in Tiếng Anh (🇬🇧 en) |
| :--- | :--- | :--- |
| **Mục Tóm tắt** | `TÓM TẮT MỤC TIÊU NGHỀ NGHIỆP` | **`PROFESSIONAL SUMMARY`** |
| **Mục Học vấn** | `HỌC VẤN` | **`EDUCATION`** |
| **Mục Kinh nghiệm** | `KINH NGHIỆM LÀM VIỆC & DỰ ÁN` | **`WORK EXPERIENCE & TECHNICAL PROJECTS`** |
| **Mục Kỹ năng** | `KỸ NĂNG CHUYÊN MÔN` | **`TECHNICAL SKILLS`** |
| **Mục Chứng chỉ** | `CHỨNG CHỈ & GIẢI THƯỞNG` | **`CERTIFICATIONS & HONORS`** |
| **Mốc thời gian** | `10/2026 - Hiện tại` | **`10/2026 - Present`** |
| **Chân trang** | `Trang 1 / 1` | **`Page 1 of 1`** |

### 11.2. Trợ lý AI Hỗ trợ Chuyển ngữ & Tối ưu Thuật ngữ Kỹ thuật (Tech English AI)
- AI nhận văn bản nháp tiếng Việt hoặc tiếng Anh sơ cấp của sinh viên, tự động dịch và nâng cấp bằng các **Action Verbs mạnh** (*Architected, Engineered, Spearheaded, Implemented, Streamlined, Deployed...*).
- Định dạng theo chuẩn công thức đo lường tác động: **Action + Context + Metric / Impact** (VD: *"Engineered a real-time sync engine reducing latency by 40%"*).

