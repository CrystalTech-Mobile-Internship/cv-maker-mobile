import '../../../../core/constants/app_constants.dart';

final class CvTemplate {
  const CvTemplate({
    required this.id,
    required this.name,
    required this.audience,
  });

  final String id;
  final String name;
  final String audience;
}

abstract final class CvTemplateCatalog {
  static const freeTemplates = <CvTemplate>[
    CvTemplate(
      id: AppConstants.templateHarvardAts,
      name: 'Harvard ATS',
      audience: 'Mọi ngành • Ưu tiên ATS',
    ),
    CvTemplate(
      id: AppConstants.templateModernMinimalist,
      name: 'Modern Minimalist',
      audience: 'Văn phòng • Sinh viên',
    ),
    CvTemplate(
      id: AppConstants.templateMinimalistClean,
      name: 'Minimalist Clean',
      audience: 'Giáo dục • Y tế • Có ảnh',
    ),
    CvTemplate(
      id: AppConstants.templateCreativeTech,
      name: 'Creative Tech',
      audience: 'Công nghệ • Thiết kế • Có ảnh',
    ),
    CvTemplate(
      id: AppConstants.templateProfessionalSidebar,
      name: 'Professional Sidebar',
      audience: 'Sinh viên • CNTT • Bố cục 1/3–2/3',
    ),
  ];

  static CvTemplate byId(String id) => freeTemplates.firstWhere(
    (template) => template.id == id,
    orElse: () => freeTemplates.first,
  );
}
