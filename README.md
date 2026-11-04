# Smart CV Maker Mobile

Ứng dụng Flutter giúp sinh viên, fresher và người đi làm tạo CV chuyên nghiệp trên Android, iOS và Web. Dự án hướng tới trải nghiệm offline-first: người dùng có thể tạo và chỉnh sửa CV khi không có mạng, sau đó đồng bộ với Supabase khi đăng nhập và có kết nối.

## Trạng thái dự án

Dự án đang ở giai đoạn xây dựng MVP.

Đã có:

- Flutter project cho Android, iOS và Web.
- Material 3 theme.
- Riverpod và GoRouter.
- Khung màn hình Login, Dashboard, CV Editor và Preview.
- Chế độ Khách khi chưa cấu hình Supabase.
- Tài liệu yêu cầu và luồng MVP.
- Bộ domain model CV, JSON serialization và ba hồ sơ mẫu.
- Drift + SQLite/WASM, repository lưu CV local và hàng đợi xóa trên cloud.
- Xem trước và xuất PDF A4; Web tải tệp qua trình duyệt.
- AI Polish Summary qua Supabase Edge Function, không nhúng AI key vào client.

Đang phát triển:

- Deploy và kiểm thử Edge Function AI bằng Supabase Secrets.
- Hoàn thiện retry đồng bộ, RLS và kiểm thử hai tài khoản.
- Hoàn thiện bố cục Web split-view cho Editor và Preview.

ATS Scorer, thanh toán Pro và một số mẫu Premium hiện vẫn là giao diện chuẩn bị; chưa phải chức năng backend hoàn chỉnh.

## Công nghệ

- Flutter và Dart.
- Riverpod cho state management.
- GoRouter cho điều hướng.
- Supabase cho Auth, PostgreSQL, RLS và Storage.
- Drift + SQLite cho lưu trữ local theo hướng offline-first.
- `pdf` và `printing` dự kiến dùng cho PDF A4.
- Google Gemini dự kiến hỗ trợ biên tập nội dung CV sau khi MVP cốt lõi ổn định.

## Luồng MVP

```text
Login hoặc Guest
       |
       v
Dashboard CV
       |
       v
CV Editor -> Tự động lưu local
       |
       v
Preview -> Chọn template -> Xuất PDF
       |
       v
Đồng bộ Supabase khi đã đăng nhập và có mạng
```

Chi tiết xem tại [docs/mvp-flow.md](docs/mvp-flow.md).

## Cấu trúc hiện tại

```text
lib/
├── app/                  # App, route và theme
├── core/                 # Cấu hình dùng chung và Supabase client
└── features/
    ├── auth/             # Đăng nhập và Guest Mode
    ├── cv_management/    # Dashboard quản lý CV
    ├── cv_editor/        # Form chỉnh sửa CV
    └── cv_preview/       # Xem trước và xuất PDF

docs/                     # Yêu cầu, luồng MVP và quy trình agent
.agents/skills/           # Nội dung skill chuẩn, dùng chung
.agents/rules/            # Rule dành cho Antigravity
.codex/skills/            # Entrypoint dành cho Codex
.claude/                  # Entrypoint, rules dành cho Claude Code
.cursor/                  # Entrypoint, rules dành cho Cursor
AGENTS.md                 # Hướng dẫn chung cho Codex/Antigravity
CLAUDE.md                 # Điểm vào quy tắc cho Claude Code
```

Mã nguồn tách theo ranh giới presentation, domain và data. Giao diện chỉ làm việc qua repository; Drift chịu trách nhiệm lưu local, còn Supabase sẽ được nối vào lớp đồng bộ cloud sau này.

## Yêu cầu môi trường

- Flutter SDK tương thích với Dart `^3.11.4`.
- Android Studio hoặc VS Code có Flutter extension.
- Android SDK cho Android development.
- Xcode và CocoaPods nếu chạy iOS trên macOS.
- Một Supabase project dành cho development nếu cần kiểm thử cloud.

Kiểm tra môi trường:

```bash
flutter doctor
flutter --version
```

## Cài đặt

```bash
git clone https://github.com/TuanAnh-Internship/cv-maker-mobile.git
cd cv-maker-mobile
flutter pub get
```

Tạo file cấu hình cá nhân:

PowerShell:

```powershell
Copy-Item .env.example .env
```

macOS/Linux:

```bash
cp .env.example .env
```

Sau đó thay các placeholder cần thiết trong `.env`. Không commit file này.

Chạy ứng dụng:

```bash
flutter run
```

Chạy bản Web:

```bash
flutter run -d chrome
```

Bản Web sử dụng `web/sqlite3.wasm` và `web/drift_worker.js` để lưu CV bằng
SQLite trong IndexedDB/OPFS. Khi nâng phiên bản Drift/SQLite, cần cập nhật hai
asset này theo phiên bản tương ứng. Chi tiết xem tại
[docs/web-support.md](docs/web-support.md).

Khi chưa có URL/key Supabase hợp lệ, ứng dụng vẫn cho phép vào chế độ Khách. Biến môi trường phải giữ đúng tên mà code hiện tại đang đọc trong `lib/core/constants/env_constants.dart`.

## Bảo mật cấu hình

- `.env` chỉ dùng trên máy cá nhân và đã được chặn trong `.gitignore`.
- Không đưa Supabase secret key, service-role key hoặc database password vào Flutter.
- Client mobile chỉ dùng key dành cho public client; dữ liệu được bảo vệ bằng RLS.
- Khóa AI không nên nằm trong APK production; production nên gọi AI qua backend hoặc Edge Function.
- Nếu thay đổi tên biến môi trường, cập nhật đồng thời code, `.env.example` và README.

## Kiểm tra chất lượng

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Nếu cần tự động sửa định dạng:

```bash
dart format lib test
```

## Làm việc với coding agent

Repository có bộ hướng dẫn dành cho agent:

- [AGENTS.md](AGENTS.md): nguyên tắc chung và Definition of Done.
- [CLAUDE.md](CLAUDE.md): điểm vào tương thích cho Claude Code.
- [docs/agent-workflow.md](docs/agent-workflow.md): quy trình khảo sát, triển khai, kiểm tra và bàn giao.
- `.agents/skills/smart-cv-feature`: phát triển feature Flutter.
- `.agents/skills/smart-cv-supabase`: Auth, migration, RLS và sync.
- `.agents/skills/smart-cv-quality`: review và kiểm tra trước commit.
- `.codex/skills`, `.claude/skills` và `.cursor/skills`: entrypoint tương thích cho từng agent.
- `.agents/rules`, `.claude/rules` và `.cursor/rules`: quy tắc theo phạm vi file với frontmatter riêng của từng nền tảng.

Bộ cấu hình hỗ trợ Codex, Claude Code, Google Antigravity và Cursor. Khi cập nhật skill, chỉ sửa nội dung chuẩn trong `.agents/skills/`; các thư mục còn lại không được sao chép lại toàn bộ nội dung skill.

Ví dụ yêu cầu agent:

```text
Hãy triển khai CV domain models theo docs/requirements.md và docs/mvp-flow.md.
Chỉ sửa domain model và test, không sửa UI hoặc Supabase. Hãy chạy format,
analyze, test và đưa commit message đề xuất; không tự commit.
```

## Git workflow

- `main`: phiên bản ổn định hoặc dùng để demo.
- `develop`: nhánh tích hợp chính trong quá trình phát triển.
- `feature/<ten-ngan>`: tính năng kéo dài hoặc thay đổi nhiều file.

Ví dụ:

```bash
git switch develop
git switch -c feature/cv-models
```

Dùng Conventional Commits:

```text
feat(models): add CV domain models
fix(sync): preserve pending offline changes
docs: define MVP user flows
test(auth): add guest login widget tests
```

Không commit hoặc push khi format, analyze hoặc test quan trọng vẫn đang thất bại mà chưa được giải thích.

## Tài liệu

- [Nhập CV Word/PDF và dùng lại hồ sơ](docs/resume-import.md)
- [Sao lưu và khôi phục CV trên thiết bị](docs/local-backup.md)

- [Đặc tả yêu cầu](docs/requirements.md)
- [Phạm vi MVP đã chốt](docs/mvp-scope.md)
- [Luồng người dùng MVP](docs/mvp-flow.md)
- [Quyết định kiến trúc](docs/architecture-decisions.md)
- [Thiết kế lưu trữ local](docs/local-storage.md)
- [Từ điển dữ liệu Supabase](docs/database/data-dictionary.md)
- [Mapping dữ liệu local và cloud](docs/database/local-cloud-mapping.md)
- [Hướng dẫn Supabase development](docs/database/supabase-setup.md)
- [Quy trình làm việc với agent](docs/agent-workflow.md)
- [Hướng dẫn chạy và kiểm thử Web](docs/web-support.md)

## Nhóm thực hiện

- Nguyễn Tuấn Anh — Fullstack Mobile Engineer.
- Nguyễn Hoàng Phong — Fullstack Mobile Engineer.

Đây là dự án thực tập doanh nghiệp và hiện chưa phải sản phẩm production.
