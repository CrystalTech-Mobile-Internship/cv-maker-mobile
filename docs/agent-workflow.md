# QUY TRÌNH LÀM VIỆC VỚI AGENT

Tài liệu này quy định cách AI agent nhận việc, triển khai, kiểm tra và bàn giao trong dự án Smart CV Maker Mobile.

## 1. Mục tiêu

- Giữ mọi thay đổi bám sát yêu cầu và luồng MVP.
- Tránh sửa lan sang phần việc của thành viên khác.
- Không làm mất dữ liệu người dùng hoặc làm lộ khóa bí mật.
- Mỗi thay đổi có thể kiểm tra, review và hoàn tác độc lập.
- Agent báo cáo trung thực phần đã hoàn thành và phần còn mô phỏng.

## 2. Tài liệu agent phải đọc

Trước khi triển khai feature, agent đọc theo thứ tự:

1. `AGENTS.md`.
2. `docs/requirements.md`.
3. `docs/mvp-flow.md`.
4. Các file code và test liên quan trực tiếp.
5. Skill phù hợp trong `.agents/skills/`.

Không cần tải toàn bộ repository vào ngữ cảnh nếu công việc chỉ liên quan đến một feature nhỏ.

## 3. Vòng đời một công việc

### Giai đoạn A — Khảo sát

Agent phải:

- Kiểm tra branch và `git status`.
- Xác định code hiện có, dependency và test liên quan.
- Phân biệt tính năng thật với placeholder hoặc dữ liệu hard-code.
- Phát hiện thay đổi chưa commit của người dùng và giữ nguyên chúng.
- Nêu rõ giả định có ảnh hưởng đến thiết kế.

Đầu ra: mô tả ngắn về hiện trạng, mục tiêu và phạm vi file dự kiến thay đổi.

### Giai đoạn B — Thiết kế lát cắt

Một lát cắt feature ưu tiên đi xuyên suốt các tầng cần thiết:

```text
UI -> Riverpod state -> use case/repository -> local data -> cloud sync (nếu cần)
```

Agent không tạo abstraction chỉ để dự phòng. Interface chỉ được thêm khi có ranh giới thực sự giữa domain và nguồn dữ liệu hoặc khi giúp kiểm thử.

Với chức năng có dữ liệu người dùng, phải trả lời được:

- Dữ liệu được lưu local ở đâu?
- Khi offline thì hành vi thế nào?
- Khi lỗi thì dữ liệu có còn không?
- Khi đăng nhập thì dữ liệu thuộc user nào?
- RLS ngăn người dùng khác truy cập bằng cách nào?

### Giai đoạn C — Triển khai

- Thay đổi theo phạm vi nhỏ nhất nhưng hoàn chỉnh.
- Ưu tiên dữ liệu thật qua repository thay cho hard-code mới.
- Không gọi Supabase trực tiếp từ Widget.
- Không đặt business logic trong callback UI nếu logic có thể tái sử dụng hoặc cần kiểm thử.
- Không đưa secret key hoặc service-role key vào Flutter.
- Migration SQL phải được lưu trong `supabase/migrations/`.
- Cập nhật tài liệu khi thay đổi hành vi, biến môi trường hoặc cách chạy.

### Giai đoạn D — Kiểm tra

Chạy theo thứ tự phù hợp:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Nếu thay đổi Supabase, kiểm tra thêm:

- Migration có thể tạo schema từ đầu.
- RLS đã bật trên bảng chứa dữ liệu người dùng.
- Có policy riêng cho `select`, `insert`, `update` và `delete` cần thiết.
- Hai tài khoản thử nghiệm không thể truy cập dữ liệu của nhau.
- Ứng dụng không sử dụng secret hoặc service-role key.

Nếu không chạy được một kiểm tra, agent phải nêu lệnh, nguyên nhân và phần chưa được xác minh.

### Giai đoạn E — Tự review

Trước khi bàn giao, agent kiểm tra:

- Diff chỉ chứa thay đổi thuộc nhiệm vụ.
- Không có credential, `.env`, log nhạy cảm hoặc dữ liệu thật.
- Không bỏ quên loading, empty, offline và error state liên quan.
- Không phá Guest Mode.
- Không ghi đè công việc chưa commit của người khác.
- Tên file, class, provider và commit message nhất quán.

### Giai đoạn F — Bàn giao

Báo cáo phải có:

1. Kết quả đạt được.
2. File chính đã thay đổi.
3. Kiểm tra đã chạy và kết quả.
4. Giới hạn hoặc quyết định còn mở.
5. Câu lệnh hoặc commit message đề xuất; agent không tự commit nếu chưa được yêu cầu.

## 4. Chọn skill theo công việc

- Dùng `smart-cv-feature` khi tạo hoặc sửa feature Flutter.
- Dùng `smart-cv-supabase` khi làm Auth, schema, migration, RLS hoặc đồng bộ.
- Dùng `smart-cv-quality` khi review, chuẩn bị commit hoặc xử lý lỗi kiểm thử.
- Nếu một công việc chạm cả Flutter và Supabase, dùng `smart-cv-feature` trước để chốt luồng, sau đó dùng `smart-cv-supabase` cho ranh giới dữ liệu và bảo mật.

### 4.1. Tương thích nhiều agent

Nội dung skill chuẩn được lưu trong `.agents/skills/`. Không sửa nội dung workflow trong các thư mục tương thích.

- Codex khám phá skill qua `.codex/skills/`.
- Claude Code khám phá skill qua `.claude/skills/` và đọc quy tắc chung từ `CLAUDE.md`.
- Antigravity khám phá skill trực tiếp từ `.agents/skills/` và quy tắc từ `.agents/rules/`.
- Cursor khám phá skill qua `.cursor/skills/` và quy tắc từ `.cursor/rules/`.

Các `SKILL.md` trong thư mục tương thích chỉ chứa metadata và đường dẫn tới skill chuẩn. Khi sửa skill, chỉ sửa file tương ứng trong `.agents/skills/`, sau đó kiểm tra metadata ở các entrypoint vẫn giống nhau.

Rules không dùng chung một file vì frontmatter kích hoạt của từng nền tảng khác nhau. `AGENTS.md` giữ nguyên tắc chung; rules theo file chỉ bổ sung quy tắc Flutter, Supabase và kiểm thử.

## 5. Quy tắc phối hợp hai thành viên

- Mỗi người nhận một issue hoặc phạm vi file rõ ràng trước khi code.
- Không cùng sửa một file lớn trong cùng thời điểm nếu chưa thống nhất.
- Schema cloud được chia sẻ bằng migration, không chỉ thao tác thủ công trên Dashboard.
- Thay đổi contract model hoặc schema phải thông báo cho người còn lại trước khi merge.
- Pull request phải mô tả cách kiểm thử và ảnh hưởng tới offline/sync.

## 6. Quy trình Git đề xuất

```text
develop
  ├── feature/cv-models
  ├── feature/local-storage
  ├── feature/supabase-auth
  └── feature/resume-sync
```

Quy trình:

1. Cập nhật `develop`.
2. Tạo nhánh feature nếu công việc kéo dài hoặc có nhiều file.
3. Tạo các commit nhỏ theo một mục đích.
4. Chạy kiểm tra trước khi push.
5. Review rồi merge về `develop`.
6. Chỉ merge `develop` vào `main` khi bản demo ổn định.

## 7. Mẫu yêu cầu tốt dành cho agent

```text
Hãy triển khai model CV theo docs/requirements.md và docs/mvp-flow.md.
Phạm vi chỉ gồm domain model, JSON serialization và unit test.
Không sửa UI hoặc Supabase. Không commit; hãy chạy format, analyze, test và
đưa cho tôi commit message đề xuất.
```

Một yêu cầu tốt nên nêu mục tiêu, phạm vi, điều không được sửa, kiểm tra cần chạy và quyền commit/push.

