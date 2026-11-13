# Tài liệu dự án

Thư mục này dành cho **nhóm phát triển và người nhận bàn giao**. Nó nằm trong
repo riêng tư và **không được đưa lên trang web**: bản web trên Vercel chỉ
chứa ứng dụng đã build (`build/web`).

Người dùng cuối chỉ cần đọc hai trang có sẵn trong ứng dụng:
**Điều khoản sử dụng** và **Chính sách bảo mật** (nội dung ở
`lib/features/legal/domain/legal_documents.dart`). Hướng dẫn tạo CV có ảnh
nằm trong `README.md` ở thư mục gốc.

## Sản phẩm

- [Đặc tả yêu cầu](requirements.md)
- [Phạm vi MVP](mvp-scope.md) và [luồng người dùng](mvp-flow.md)
- [Quyết định kiến trúc](architecture-decisions.md)
- [Thiết kế giao diện](design/README.md)

## Tính năng

- [Đăng nhập, tài khoản, giới hạn thiết bị](authentication.md)
- [Trợ lý AI và giới hạn lượt dùng](ai-assistant.md)
- [Cộng đồng](community.md)
- [Lưu trên máy](local-storage.md), [sao lưu và khôi phục](local-backup.md)
- [Xem trước đồng bộ](cloud-sync-preview.md), [đồng bộ 2 Supabase project](dual-supabase-sync.md)
- [Nhập CV từ Word/PDF](resume-import.md), [xuất Word](docx-export.md)
- [Bản web](web-support.md)

## Cơ sở dữ liệu và vận hành

- [Thiết lập Supabase](database/supabase-setup.md), [hướng dẫn chi tiết](database/setup_guide.md)
- [Từ điển dữ liệu](database/data-dictionary.md), [ánh xạ dữ liệu máy ↔ máy chủ](database/local-cloud-mapping.md)
- [Deploy bản web lên Vercel](deploy-web.md)

## Quy trình làm việc

- [Quy trình phối hợp với coding agent](agent-workflow.md)

## Không đưa vào tài liệu

Không ghi khóa bí mật (service role, khóa AI, mật khẩu database), email hay số
điện thoại thật vào bất kỳ file nào trong repo. Dữ liệu CV dùng cho test nằm ở
`test/fixtures/cvs/` và chỉ chứa thông tin giả (`example.com`).
