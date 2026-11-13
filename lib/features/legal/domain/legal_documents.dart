/// Terms of use and privacy policy shown inside the app.
class LegalSection {
  const LegalSection(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.updatedOn,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String updatedOn;
  final String intro;
  final List<LegalSection> sections;
}

enum LegalDocumentType { terms, privacy }

abstract final class LegalDocuments {
  static const updatedOn = '12/11/2026';

  static LegalDocument of(LegalDocumentType type) =>
      type == LegalDocumentType.terms ? terms : privacy;

  static const terms = LegalDocument(
    title: 'Điều khoản sử dụng',
    updatedOn: updatedOn,
    intro:
        'Khi dùng Smart CV Maker, bạn đồng ý với các điều khoản dưới đây. '
        'Vui lòng đọc kỹ trước khi tạo tài khoản.',
    sections: [
      LegalSection('1. Dịch vụ', [
        'Smart CV Maker giúp bạn tạo, chỉnh sửa, xuất CV và chuẩn bị ứng tuyển. '
            'Bạn có thể dùng không cần tài khoản; khi đăng nhập, CV được sao lưu để dùng trên nhiều thiết bị.',
      ]),
      LegalSection('2. Tài khoản', [
        'Bạn chịu trách nhiệm giữ an toàn mật khẩu và mọi hoạt động trên tài khoản của mình.',
        'Thông tin đăng ký phải chính xác. Mỗi người chỉ nên dùng một tài khoản.',
      ]),
      LegalSection('3. Nội dung của bạn', [
        'CV và nội dung bạn tạo thuộc về bạn. Bạn chịu trách nhiệm về tính trung thực của thông tin trong CV.',
        'Chúng tôi chỉ dùng nội dung đó để cung cấp tính năng cho bạn, không bán hay chia sẻ cho nhà tuyển dụng.',
      ]),
      LegalSection('4. Trợ lý AI', [
        'Gợi ý của AI chỉ mang tính tham khảo và có thể chưa chính xác. Hãy đọc lại trước khi dùng.',
        'Tài khoản miễn phí có số lượt AI giới hạn mỗi ngày. Không dùng AI để tạo nội dung sai sự thật hoặc vi phạm pháp luật.',
      ]),
      LegalSection('5. Cộng đồng', [
        'Không đăng nội dung xúc phạm, lừa đảo, quảng cáo trái phép, tin tuyển dụng giả hoặc thông tin cá nhân của người khác.',
        'Bài viết bị nhiều người báo cáo sẽ tự động ẩn. Chúng tôi có thể xóa nội dung hoặc khóa tài khoản vi phạm.',
      ]),
      LegalSection('6. Gói Pro', [
        'Gói Pro được kích hoạt sau khi xác nhận thanh toán. Quyền lợi và giá được ghi rõ trong màn Nâng cấp Pro.',
        'Nếu có sai sót khi thanh toán, hãy liên hệ để được hỗ trợ.',
      ]),
      LegalSection('7. Giới hạn trách nhiệm', [
        'Ứng dụng được cung cấp như hiện có. Chúng tôi không bảo đảm kết quả tuyển dụng.',
        'Hãy thường xuyên tải bản sao CV về máy để phòng trường hợp mất dữ liệu.',
      ]),
      LegalSection('8. Thay đổi điều khoản', [
        'Điều khoản có thể được cập nhật. Ngày cập nhật được ghi ở đầu trang; tiếp tục sử dụng nghĩa là bạn đồng ý với bản mới.',
      ]),
    ],
  );

  static const privacy = LegalDocument(
    title: 'Chính sách bảo mật',
    updatedOn: updatedOn,
    intro:
        'Chúng tôi tôn trọng quyền riêng tư của bạn. Chính sách này cho biết dữ liệu nào được thu thập, '
        'dùng vào việc gì và bạn có quyền gì.',
    sections: [
      LegalSection('1. Dữ liệu chúng tôi lưu', [
        'Thông tin tài khoản: họ tên, email, phương thức đăng nhập.',
        'Nội dung CV: thông tin cá nhân, học vấn, kinh nghiệm, kỹ năng, ảnh đại diện (nếu có).',
        'Bài viết, bình luận trong cộng đồng; yêu cầu nâng cấp Pro; số lượt AI đã dùng trong ngày.',
      ]),
      LegalSection('2. Nơi lưu trữ', [
        'CV luôn được lưu trên thiết bị của bạn. Khi đăng nhập, CV được sao lưu lên máy chủ đặt tại Singapore.',
        'Mỗi tài khoản chỉ xem được dữ liệu của chính mình. Kết nối được mã hóa.',
      ]),
      LegalSection('3. Khi dùng trợ lý AI', [
        'Chỉ phần nội dung cần thiết (văn bản CV, câu trả lời của bạn, tin tuyển dụng) được gửi qua máy chủ của ứng dụng tới dịch vụ AI để xử lý.',
        'Ứng dụng không lưu lại nội dung này trên máy chủ. Thư xin việc do AI viết không kèm email, số điện thoại hay địa chỉ của bạn.',
        'Không nhập mật khẩu, số giấy tờ tùy thân hay thông tin tài chính vào trợ lý AI.',
      ]),
      LegalSection('4. Mục đích sử dụng', [
        'Cung cấp và đồng bộ CV, đăng nhập, tính năng AI, cộng đồng và gói Pro.',
        'Chúng tôi không bán dữ liệu và không dùng CV của bạn để quảng cáo.',
      ]),
      LegalSection('5. Chia sẻ dữ liệu', [
        'Dữ liệu chỉ được chia sẻ với nhà cung cấp hạ tầng (lưu trữ, gửi email, xử lý AI) ở mức cần thiết để vận hành dịch vụ, hoặc khi pháp luật yêu cầu.',
        'Bài viết trong cộng đồng hiển thị cho các thành viên đã đăng nhập.',
      ]),
      LegalSection('6. Quyền của bạn', [
        'Xem, sửa, xuất toàn bộ CV ra tệp sao lưu bất cứ lúc nào.',
        'Xóa CV, bài viết, bình luận của mình. Yêu cầu xóa tài khoản và toàn bộ dữ liệu bằng cách liên hệ với chúng tôi.',
      ]),
      LegalSection('7. Lưu giữ dữ liệu', [
        'Dữ liệu được giữ đến khi bạn xóa hoặc yêu cầu xóa tài khoản. Số lượt AI theo ngày chỉ dùng để giới hạn sử dụng.',
      ]),
      LegalSection('8. Trẻ em', [
        'Ứng dụng dành cho người từ 16 tuổi trở lên.',
      ]),
    ],
  );
}
