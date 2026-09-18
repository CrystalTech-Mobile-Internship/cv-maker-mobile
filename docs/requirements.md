# Requirements — Project 2: CV Maker Mobile

## 1. Project Overview

| Thuộc tính | Phân tích |
|---|---|
| Loại ứng dụng | Productivity / Career / Document Creator |
| Platform | iOS + Android |
| Quy mô | Lớn hơn Project 1 |
| Dữ liệu | Nhiều section CV, form động, local storage |
| File | PDF export, lưu trữ và chia sẻ |
| Cross-platform | UI, file system, permission, sharing khác nhau theo OS |
| Backend | Nhấn mạnh local storage; có thể mở rộng cloud |

## 2. Problem Statement

Sinh viên, fresher và người tìm việc cần tạo hoặc chỉnh sửa CV nhanh nhưng không phải lúc nào cũng có laptop hoặc kỹ năng thiết kế. Project 2 biến quy trình tạo CV thành một flow trên mobile.

```
Thông tin cá nhân
+ Học vấn
+ Kinh nghiệm
+ Kỹ năng
+ Dự án
        ↓
Dynamic CV Data
        ↓
Template
        ↓
Preview
        ↓
PDF
        ↓
Save / Share
```

## 3. Đối tượng người dùng

| Nhóm | Nhu cầu | Giá trị app mang lại |
|---|---|---|
| Sinh viên | Tạo CV xin thực tập | Template + form dễ nhập |
| Fresher | Tạo CV đầu tiên | Hướng dẫn cấu trúc thông tin |
| Người tìm việc | Chỉnh CV nhanh khi di chuyển | Mobile editing + PDF + share |
| Người không biết thiết kế | Muốn CV nhìn chuyên nghiệp | Template có sẵn |

## 4. User Goals

- **UG-P2-01:** Tôi muốn tạo một CV mới trên điện thoại.
- **UG-P2-02:** Tôi muốn nhập/chỉnh sửa từng section của CV.
- **UG-P2-03:** Tôi muốn thêm nhiều mục Experience/Education/Project.
- **UG-P2-04:** Tôi muốn đổi template mà không mất dữ liệu.
- **UG-P2-05:** Tôi muốn xem trước CV trước khi xuất.
- **UG-P2-06:** Tôi muốn xuất CV thành PDF.
- **UG-P2-07:** Tôi muốn lưu và chia sẻ file từ điện thoại.
- **UG-P2-08 (mở rộng):** Tôi muốn AI gợi ý cách viết nội dung CV tốt hơn.

## 5. Feature List

| Nhóm | Feature | Ưu tiên | Ghi chú |
|---|---|---|---|
| CV Management | Create / Edit / Delete CV | Must-have | CRUD local cho tài liệu CV |
| Form | Dynamic CV Sections | Must-have | Education, Experience, Skills, Projects... |
| Template | Template Selection | Must-have | Chọn/gán template cho cùng dữ liệu |
| Preview | CV Preview | Must-have | Xem kết quả trước khi export |
| Storage | Local Save | Must-have | Lưu dữ liệu CV trên thiết bị |
| File | PDF Export | Must-have | Kết xuất CV thành tài liệu PDF |
| System | Share PDF | Must-have | Chia sẻ bằng hệ thống Android/iOS |
| Import | Load/Download document | Theo đề cương | Cần làm rõ định dạng và phạm vi |
| Enhancement | Multiple CV Versions | Nice-to-have | Nhiều CV cho nhiều vị trí |
| AI | AI Writing Assistant | Proposed AI | Gợi ý/rewrite bullet CV |

## 6. Cấu trúc dữ liệu CV

| Section | Dữ liệu | Kiểu |
|---|---|---|
| Personal Information | Name, email, phone, location, title | Single object |
| Summary | Professional summary | Text |
| Education | School, degree, dates, description | List |
| Experience | Company, position, dates, achievements | List |
| Skills | Skill name/level hoặc tag | List |
| Projects | Project name, role, technology, description | List |
| Certificates | Name, issuer, date | List |
| Languages | Language, proficiency | List |

## 7. Luồng chính

```
Open App
  ↓
CV List
  ↓
Create New CV
  ↓
Fill Dynamic Forms
  ↓
Choose Template
  ↓
Preview
  ↓
Save
  ↓
Export PDF
  ↓
Share / Open / Store
```

## 8. Cross-platform Concerns

| Hạng mục | Android | iOS | Điểm cần thống nhất |
|---|---|---|---|
| UI | Android rendering | iOS rendering | Thiết kế responsive/cross-platform |
| Local storage | Android storage | iOS storage | Dùng abstraction chung của framework |
| PDF | File path/share intent | File URL/share sheet | Một service interface chung |
| Share | Android share sheet | iOS share sheet | Behavior khác nhau theo OS |
| Permission | Android permission model | iOS permission model | Chỉ xin khi feature cần |
| Testing | Emulator + device | Simulator + iPhone | Test platform-specific behavior |

## 9. Phạm vi

| In scope | Out of scope |
|---|---|
| Tạo, lưu, chỉnh sửa CV | Recruitment platform hoàn chỉnh |
| Template system | Job marketplace |
| Dynamic forms | Company ATS backend |
| Preview | Social network |
| PDF export | Payment/subscription |
| File sharing | Multi-tenant admin |
| Local storage | Cloud sync bắt buộc (nếu mentor chưa yêu cầu) |
| iOS + Android | Web app |

## 10. Đề xuất AI (Future)

- **AI CV Writing Assistant:** Người dùng nhập ý thô; AI gợi ý viết lại summary hoặc achievement bullet rõ ràng hơn.
- **AI Bullet Improver:** Chuyển câu mô tả chung thành bullet có cấu trúc Action - Context - Result.
- **AI Completeness Check:** Phát hiện section quan trọng còn thiếu hoặc quá sơ sài.
- **AI Job-tailoring (Future):** Nếu user cung cấp job description, AI gợi ý nội dung nào nên nhấn mạnh.

> **Nguyên tắc AI:** AI không được tự tạo kinh nghiệm, kỹ năng hay thành tích không có thật. Mọi nội dung AI phải ở trạng thái suggestion và cần người dùng xác nhận trước khi lưu vào CV.
