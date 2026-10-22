import '../../../../core/constants/app_constants.dart';

final class CvTemplate {
  const CvTemplate({
    required this.id,
    required this.name,
    required this.audience,
    required this.description,
    required this.accentHex,
    required this.layout,
    this.hasPhoto = false,
    this.isPremium = false,
    this.isNew = false,
  });

  final String id;
  final String name;
  final String audience;
  final String description;
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
      audience: 'Mọi ngành • Ưu tiên ATS',
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
      id: AppConstants.templateCreativeTech,
      name: 'Creative Tech',
      audience: 'Công nghệ • Thiết kế • Có ảnh',
      description: 'Header nổi bật cho hồ sơ công nghệ sáng tạo.',
      accentHex: '#7C3AED',
      layout: CvTemplateLayout.creative,
      hasPhoto: true,
    ),
    CvTemplate(
      id: AppConstants.templateProfessionalSidebar,
      name: 'Professional Sidebar',
      audience: 'Sinh viên • CNTT • Bố cục 1/3–2/3',
      description: 'Sidebar kỹ năng và nội dung chính cân đối.',
      accentHex: '#18A999',
      layout: CvTemplateLayout.sidebar,
      hasPhoto: true,
    ),
    CvTemplate(
      id: AppConstants.templateExecutiveNavy,
      name: 'Executive Navy',
      audience: 'Quản lý • Kinh doanh • Không ảnh',
      description: 'Phong cách doanh nghiệp, ưu tiên thành tích.',
      accentHex: '#1E3A8A',
      layout: CvTemplateLayout.executive,
      isNew: true,
    ),
    CvTemplate(
      id: AppConstants.templateAcademicClassic,
      name: 'Academic Classic',
      audience: 'Giáo dục • Nghiên cứu • Không ảnh',
      description: 'Bố cục cổ điển cho học thuật và chứng chỉ.',
      accentHex: '#9A3412',
      layout: CvTemplateLayout.academic,
      isNew: true,
    ),
    CvTemplate(
      id: AppConstants.templateFreshProfile,
      name: 'Fresh Profile',
      audience: 'Marketing • Dịch vụ • Có ảnh',
      description: 'Ảnh nổi bật cùng mảng màu xanh tươi trẻ.',
      accentHex: '#047857',
      layout: CvTemplateLayout.freshPhoto,
      hasPhoto: true,
      isNew: true,
    ),
  ];

  static const premiumTemplates = <CvTemplate>[
    CvTemplate(
      id: 'premium_elegant_photo',
      name: 'Elegant Portrait',
      audience: 'Premium • Có ảnh',
      description: 'Phong cách thanh lịch dành cho hồ sơ cấp cao.',
      accentHex: '#B45309',
      layout: CvTemplateLayout.cleanPhoto,
      hasPhoto: true,
      isPremium: true,
    ),
    CvTemplate(
      id: 'premium_creative_portfolio',
      name: 'Creative Portfolio',
      audience: 'Premium • Thiết kế',
      description: 'Bố cục giàu hình ảnh cho ngành sáng tạo.',
      accentHex: '#DB2777',
      layout: CvTemplateLayout.creative,
      hasPhoto: true,
      isPremium: true,
    ),
    CvTemplate(
      id: 'premium_ai_focus',
      name: 'AI Optimized',
      audience: 'Premium • ATS + AI',
      description: 'Gợi ý nội dung và từ khóa theo vị trí ứng tuyển.',
      accentHex: '#4F46E5',
      layout: CvTemplateLayout.executive,
      isPremium: true,
    ),
  ];

  static const allTemplates = <CvTemplate>[
    ...freeTemplates,
    ...premiumTemplates,
  ];

  static CvTemplate byId(String id) => allTemplates.firstWhere(
    (template) => template.id == id,
    orElse: () => freeTemplates.first,
  );
}
