import '../i18n/app_language.dart';

/// Global application constants
class AppConstants {
  static const String appName = 'Smart CV Maker';

  /// Support address shown in the legal pages; leave empty until the
  /// public support mailbox is ready.
  static const String supportEmail = '';

  static String get appTagline => tr(
    'Tạo CV chuyên nghiệp, nổi bật với nhà tuyển dụng',
    'Make a professional CV that stands out',
  );

  // Storage / Preferences keys
  static const String prefIsGuestMode = 'is_guest_mode';
  static const String prefActiveCvId = 'active_cv_id';

  // Templates
  static const String templateHarvardAts = 'harvard_ats';
  static const String templateModernMinimalist = 'modern_minimalist';
  static const String templateMinimalistClean = 'minimalist_clean';
  static const String templateCreativeTech = 'creative_tech';
  static const String templateProfessionalSidebar = 'professional_sidebar';
  static const String templateExecutiveNavy = 'executive_navy';
  static const String templateAcademicClassic = 'academic_classic';
  static const String templateFreshProfile = 'fresh_profile';
  static const String templateChronologicalSlate = 'chronological_slate';
  static const String templateGraduateSkills = 'graduate_skills';
  static const String templateFinancePrecision = 'finance_precision';
  static const String templateHealthcareCalm = 'healthcare_calm';
  static const String templateSalesImpact = 'sales_impact';
  static const String templateInternationalCompact = 'international_compact';
  static const String templateTechTimeline = 'tech_timeline';
  static const String templateStartupBold = 'startup_bold';
  static const String templateMinimalMono = 'minimal_mono';
}
