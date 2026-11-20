import '../../../core/i18n/app_language.dart';

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
  static const updatedOn = '20/11/2026';

  static LegalDocument of(LegalDocumentType type) =>
      type == LegalDocumentType.terms ? terms : privacy;

  /// Terms in the app language.
  static LegalDocument get terms => appInEnglish ? _termsEn : _termsVi;

  /// Privacy policy in the app language.
  static LegalDocument get privacy => appInEnglish ? _privacyEn : _privacyVi;

  static const _termsVi = LegalDocument(
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
        'Gói Pro được kích hoạt tự động khi nhận được chuyển khoản đúng số tiền và nội dung. Quyền lợi và giá được ghi rõ trong màn Nâng cấp Pro.',
        'Nếu có sai sót khi thanh toán, hãy nhắn cho chúng tôi qua nút hỗ trợ trong ứng dụng.',
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

  static const _termsEn = LegalDocument(
    title: 'Terms of use',
    updatedOn: updatedOn,
    intro:
        'By using Smart CV Maker you agree to the terms below. '
        'Please read them before creating an account.',
    sections: [
      LegalSection('1. The service', [
        'Smart CV Maker helps you create, edit and export CVs and prepare for job applications. '
            'You can use it without an account; when you sign in, your CVs are backed up so you can use them on several devices.',
      ]),
      LegalSection('2. Your account', [
        'You are responsible for keeping your password safe and for all activity on your account.',
        'Sign-up details must be accurate. Each person should use only one account.',
      ]),
      LegalSection('3. Your content', [
        'The CVs and content you create belong to you. You are responsible for the truthfulness of the information in your CV.',
        'We use that content only to provide features to you. We do not sell it or share it with employers.',
      ]),
      LegalSection('4. AI assistant', [
        'AI suggestions are for reference only and may be inaccurate. Read them before using them.',
        'Free accounts have a limited number of AI uses per day. Do not use the AI to create false or unlawful content.',
      ]),
      LegalSection('5. Community', [
        'Do not post offensive content, scams, unauthorised ads, fake job postings or other people\'s personal information.',
        'Posts reported by many members are hidden automatically. We may remove content or suspend accounts that break these rules.',
      ]),
      LegalSection('6. Pro plan', [
        'Pro is activated automatically once a transfer with the correct amount and reference is received. Benefits and prices are shown on the Upgrade to Pro screen.',
        'If something goes wrong with a payment, message us through the support button in the app.',
      ]),
      LegalSection('7. Limitation of liability', [
        'The app is provided as is. We do not guarantee any hiring outcome.',
        'Download a backup of your CVs regularly in case of data loss.',
      ]),
      LegalSection('8. Changes to these terms', [
        'These terms may be updated. The update date is shown at the top; continuing to use the app means you accept the new version.',
      ]),
    ],
  );

  static const _privacyVi = LegalDocument(
    title: 'Chính sách bảo mật',
    updatedOn: updatedOn,
    intro:
        'Chúng tôi tôn trọng quyền riêng tư của bạn. Chính sách này cho biết dữ liệu nào được thu thập, '
        'dùng vào việc gì và bạn có quyền gì.',
    sections: [
      LegalSection('1. Dữ liệu chúng tôi lưu', [
        'Thông tin tài khoản: họ tên, email, phương thức đăng nhập.',
        'Nội dung CV: thông tin cá nhân, học vấn, kinh nghiệm, kỹ năng, ảnh đại diện (nếu có).',
        'Bài viết, bình luận trong cộng đồng; tin nhắn hỗ trợ bạn gửi; số lượt AI đã dùng trong ngày.',
        'Khi mua Pro: gói đã chọn, số tiền, mã chuyển khoản và thời điểm thanh toán. Chúng tôi không lưu số thẻ hay mật khẩu ngân hàng.',
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
        'Cung cấp và đồng bộ CV, đăng nhập, tính năng AI, cộng đồng, hỗ trợ và gói Pro.',
        'Chúng tôi không bán dữ liệu và không dùng CV của bạn để quảng cáo.',
        'Bản web đếm lượt xem trang ẩn danh (không dùng cookie, không gắn với tài khoản) để biết trang nào được dùng nhiều.',
      ]),
      LegalSection('5. Chia sẻ dữ liệu', [
        'Dữ liệu chỉ được chia sẻ với nhà cung cấp hạ tầng (lưu trữ, gửi email, xử lý AI, đối soát chuyển khoản) ở mức cần thiết để vận hành dịch vụ, hoặc khi pháp luật yêu cầu.',
        'Bài viết trong cộng đồng hiển thị cho các thành viên đã đăng nhập.',
      ]),
      LegalSection('6. Quyền của bạn', [
        'Xem, sửa, xuất toàn bộ CV ra tệp sao lưu bất cứ lúc nào.',
        'Xóa CV, bài viết, bình luận của mình. Yêu cầu xóa tài khoản và toàn bộ dữ liệu bằng cách nhắn cho chúng tôi qua nút hỗ trợ.',
      ]),
      LegalSection('7. Lưu giữ dữ liệu', [
        'Dữ liệu được giữ đến khi bạn xóa hoặc yêu cầu xóa tài khoản. Số lượt AI theo ngày chỉ dùng để giới hạn sử dụng.',
      ]),
      LegalSection('8. Trẻ em', [
        'Ứng dụng dành cho người từ 16 tuổi trở lên.',
      ]),
    ],
  );

  static const _privacyEn = LegalDocument(
    title: 'Privacy policy',
    updatedOn: updatedOn,
    intro:
        'We respect your privacy. This policy explains what data we collect, '
        'what we use it for and what rights you have.',
    sections: [
      LegalSection('1. Data we keep', [
        'Account details: name, email and how you sign in.',
        'CV content: personal details, education, experience, skills and profile photo (if any).',
        'Community posts and comments; support messages you send; the number of AI uses each day.',
        'When you buy Pro: the plan, amount, transfer reference and payment time. We never store card numbers or banking passwords.',
      ]),
      LegalSection('2. Where data is stored', [
        'Your CVs are always kept on your device. When you sign in, they are backed up to servers in Singapore.',
        'Each account can only see its own data. Connections are encrypted.',
      ]),
      LegalSection('3. When you use the AI assistant', [
        'Only the content needed (CV text, your answers, the job posting) is sent through the app\'s server to the AI service for processing.',
        'The app does not keep this content on its server. Cover letters written by the AI do not include your email, phone number or address.',
        'Do not enter passwords, ID numbers or financial details into the AI assistant.',
      ]),
      LegalSection('4. How we use data', [
        'To provide and sync your CVs, sign-in, AI features, the community, support and the Pro plan.',
        'We do not sell data and do not use your CVs for advertising.',
        'The web version counts page views anonymously (no cookies, not linked to your account) to see which pages are used most.',
      ]),
      LegalSection('5. Sharing', [
        'Data is shared only with infrastructure providers (storage, email, AI processing, payment matching) as far as needed to run the service, or when required by law.',
        'Community posts are visible to signed-in members.',
      ]),
      LegalSection('6. Your rights', [
        'View, edit and export all your CVs to a backup file at any time.',
        'Delete your own CVs, posts and comments. Ask us to delete your account and all its data by messaging us through the support button.',
      ]),
      LegalSection('7. Retention', [
        'Data is kept until you delete it or ask us to delete your account. Daily AI counts are used only to limit usage.',
      ]),
      LegalSection('8. Children', ['The app is for people aged 16 and over.']),
    ],
  );
}
