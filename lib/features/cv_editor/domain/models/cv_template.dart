import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/app_language.dart';

final class CvTemplate {
  const CvTemplate({
    required this.id,
    required this.name,
    required String audience,
    required String description,
    required this.accentHex,
    required this.layout,
    this.hasPhoto = false,
    this.isPremium = false,
    this.isNew = false,
  }) : _audience = audience,
       _description = description;

  final String id;
  final String name;
  final String _audience;
  final String _description;

  /// Who the template suits, in the app language.
  String get audience => tr(_audience, _templateEn[_audience] ?? _audience);

  /// One-line description, in the app language.
  String get description =>
      tr(_description, _templateEn[_description] ?? _description);
  final String accentHex;
  final CvTemplateLayout layout;
  final bool hasPhoto;
  final bool isPremium;
  final bool isNew;
}

enum CvTemplateLayout {
  classic,
  modern,
  cleanPhoto,
  creative,
  sidebar,
  executive,
  academic,
  freshPhoto,
}

abstract final class CvTemplateCatalog {
  static const freeTemplates = <CvTemplate>[
    CvTemplate(
      id: AppConstants.templateHarvardAts,
      name: 'Harvard ATS',
      audience: 'Mọi ngành • Bố cục chuẩn tuyển dụng',
      description: 'Một cột rõ ràng, tối ưu hệ thống tuyển dụng.',
      accentHex: '#111827',
      layout: CvTemplateLayout.classic,
    ),
    CvTemplate(
      id: AppConstants.templateModernMinimalist,
      name: 'Modern Minimalist',
      audience: 'Văn phòng • Sinh viên',
      description: 'Khoảng trắng thoáng, điểm nhấn xanh hiện đại.',
      accentHex: '#2563EB',
      layout: CvTemplateLayout.modern,
    ),
    CvTemplate(
      id: AppConstants.templateMinimalistClean,
      name: 'Minimalist Clean',
      audience: 'Giáo dục • Y tế • Có ảnh',
      description: 'Ảnh hồ sơ gọn, tông teal nhẹ và dễ đọc.',
      accentHex: '#0F766E',
      layout: CvTemplateLayout.cleanPhoto,
      hasPhoto: true,
    ),
    CvTemplate(
      id: AppConstants.templateChronologicalSlate,
      name: 'Chronological Slate',
      audience: 'Người đi làm • Kinh nghiệm gần nhất trước',
      description: 'Dòng thời gian rõ, phù hợp hồ sơ có lịch sử ổn định.',
      accentHex: '#334155',
      layout: CvTemplateLayout.classic,
      isNew: true,
    ),
    CvTemplate(
      id: AppConstants.templateGraduateSkills,
      name: 'Graduate Skills',
      audience: 'Sinh viên • Fresher • Chuyển ngành',
      description: 'Ưu tiên năng lực, học vấn và dự án nổi bật.',
      accentHex: '#0369A1',
      layout: CvTemplateLayout.modern,
      isNew: true,
    ),
    CvTemplate(
      id: AppConstants.templateInternationalCompact,
      name: 'International Compact',
      audience: 'Ứng tuyển quốc tế • Không ảnh',
      description: 'Một cột gọn, ít màu và tối ưu khả năng quét nhanh.',
      accentHex: '#111827',
      layout: CvTemplateLayout.academic,
      isNew: true,
    ),
    CvTemplate(
      id: AppConstants.templateProfessionalSidebar,
      name: 'Professional Sidebar',
      audience: 'Sinh viên • Có ảnh',
      description: 'Sidebar kỹ năng và nội dung chính cân đối.',
      accentHex: '#18A999',
      layout: CvTemplateLayout.sidebar,
      hasPhoto: true,
    ),
    CvTemplate(
      id: AppConstants.templateFreshProfile,
      name: 'Fresh Profile',
      audience: 'Marketing • Dịch vụ • Có ảnh',
      description: 'Ảnh nổi bật cùng mảng màu xanh tươi trẻ.',
      accentHex: '#047857',
      layout: CvTemplateLayout.freshPhoto,
      hasPhoto: true,
    ),
  ];

  static const premiumTemplates = <CvTemplate>[
    CvTemplate(
      id: 'premium_elegant_photo',
      name: 'Elegant Portrait',
      audience: 'Có ảnh',
      description: 'Phong cách thanh lịch dành cho hồ sơ cấp cao.',
      accentHex: '#B45309',
      layout: CvTemplateLayout.cleanPhoto,
      hasPhoto: true,
      isPremium: true,
    ),
    CvTemplate(
      id: 'premium_creative_portfolio',
      name: 'Creative Portfolio',
      audience: 'Thiết kế',
      description: 'Bố cục giàu hình ảnh cho ngành sáng tạo.',
      accentHex: '#DB2777',
      layout: CvTemplateLayout.creative,
      hasPhoto: true,
      isPremium: true,
    ),
    CvTemplate(
      id: 'premium_ai_focus',
      name: 'Modern Focus',
      audience: 'Gọn, hiện đại',
      description: 'Gợi ý nội dung và từ khóa theo vị trí ứng tuyển.',
      accentHex: '#4F46E5',
      layout: CvTemplateLayout.executive,
      isPremium: true,
    ),
    CvTemplate(
      id: AppConstants.templateCreativeTech,
      name: 'Creative Tech',
      audience: 'Công nghệ',
      description: 'Header nổi bật cho hồ sơ công nghệ sáng tạo.',
      accentHex: '#7C3AED',
      layout: CvTemplateLayout.creative,
      hasPhoto: true,
      isPremium: true,
    ),
    CvTemplate(
      id: AppConstants.templateExecutiveNavy,
      name: 'Executive Navy',
      audience: 'Quản lý',
      description: 'Phong cách doanh nghiệp, ưu tiên thành tích.',
      accentHex: '#1E3A8A',
      layout: CvTemplateLayout.executive,
      isPremium: true,
    ),
    CvTemplate(
      id: AppConstants.templateAcademicClassic,
      name: 'Academic Classic',
      audience: 'Giáo dục',
      description: 'Bố cục cổ điển cho học thuật và chứng chỉ.',
      accentHex: '#9A3412',
      layout: CvTemplateLayout.academic,
      isPremium: true,
    ),
    CvTemplate(
      id: AppConstants.templateFinancePrecision,
      name: 'Finance Precision',
      audience: 'Tài chính',
      description: 'Bố cục nghiêm túc, nhấn mạnh số liệu và thành tích.',
      accentHex: '#1E3A5F',
      layout: CvTemplateLayout.executive,
      isPremium: true,
    ),
    CvTemplate(
      id: AppConstants.templateHealthcareCalm,
      name: 'Healthcare Calm',
      audience: 'Y tế',
      description: 'Màu xanh dịu, khoảng trắng tốt và dễ kiểm tra.',
      accentHex: '#0F766E',
      layout: CvTemplateLayout.modern,
      isPremium: true,
    ),
    CvTemplate(
      id: AppConstants.templateSalesImpact,
      name: 'Sales Impact',
      audience: 'Kinh doanh',
      description: 'Tiêu đề mạnh, tập trung KPI và kết quả đo lường.',
      accentHex: '#B45309',
      layout: CvTemplateLayout.executive,
      isPremium: true,
    ),
  ];

  static const allTemplates = <CvTemplate>[
    ...freeTemplates,
    ...premiumTemplates,
  ];

  /// Templates selectable by the user: Pro accounts get every design.
  static List<CvTemplate> available({required bool isPro}) =>
      isPro ? allTemplates : freeTemplates;

  static CvTemplate byId(String id) => allTemplates.firstWhere(
    (template) => template.id == id,
    orElse: () => freeTemplates.first,
  );
}

const _templateEn = <String, String>{
  'Mọi ngành • Bố cục chuẩn tuyển dụng': 'Any field • Standard hiring layout',
  'Một cột rõ ràng, tối ưu hệ thống tuyển dụng.':
      'One clear column, easy for hiring systems to read.',
  'Văn phòng • Sinh viên': 'Office • Students',
  'Khoảng trắng thoáng, điểm nhấn xanh hiện đại.':
      'Airy spacing with a modern blue accent.',
  'Giáo dục • Y tế • Có ảnh': 'Education • Healthcare • Photo',
  'Ảnh hồ sơ gọn, tông teal nhẹ và dễ đọc.':
      'Neat profile photo, soft teal tone, easy to read.',
  'Người đi làm • Kinh nghiệm gần nhất trước':
      'Professionals • Latest experience first',
  'Dòng thời gian rõ, phù hợp hồ sơ có lịch sử ổn định.':
      'Clear timeline for a steady work history.',
  'Sinh viên • Fresher • Chuyển ngành': 'Students • Graduates • Career change',
  'Ưu tiên năng lực, học vấn và dự án nổi bật.':
      'Puts skills, education and key projects first.',
  'Ứng tuyển quốc tế • Không ảnh': 'International jobs • No photo',
  'Một cột gọn, ít màu và tối ưu khả năng quét nhanh.':
      'Compact single column, little colour, quick to scan.',
  'Sinh viên • Có ảnh': 'Students • Photo',
  'Sidebar kỹ năng và nội dung chính cân đối.':
      'Balanced skills sidebar and main content.',
  'Marketing • Dịch vụ • Có ảnh': 'Marketing • Services • Photo',
  'Ảnh nổi bật cùng mảng màu xanh tươi trẻ.':
      'Prominent photo with a fresh green band.',
  'Có ảnh': 'Photo',
  'Phong cách thanh lịch dành cho hồ sơ cấp cao.':
      'Elegant style for senior profiles.',
  'Thiết kế': 'Design',
  'Bố cục giàu hình ảnh cho ngành sáng tạo.':
      'Visual layout for creative fields.',
  'Gọn, hiện đại': 'Compact, modern',
  'Gợi ý nội dung và từ khóa theo vị trí ứng tuyển.':
      'Content and keyword hints for your target role.',
  'Công nghệ': 'Technology',
  'Header nổi bật cho hồ sơ công nghệ sáng tạo.':
      'Bold header for creative tech profiles.',
  'Quản lý': 'Management',
  'Phong cách doanh nghiệp, ưu tiên thành tích.':
      'Corporate style that puts achievements first.',
  'Giáo dục': 'Education',
  'Bố cục cổ điển cho học thuật và chứng chỉ.':
      'Classic layout for academia and certificates.',
  'Tài chính': 'Finance',
  'Bố cục nghiêm túc, nhấn mạnh số liệu và thành tích.':
      'Formal layout that highlights numbers and results.',
  'Y tế': 'Healthcare',
  'Màu xanh dịu, khoảng trắng tốt và dễ kiểm tra.':
      'Soft blue, good spacing, easy to review.',
  'Kinh doanh': 'Sales',
  'Tiêu đề mạnh, tập trung KPI và kết quả đo lường.':
      'Strong headings focused on KPIs and measurable results.',
};
