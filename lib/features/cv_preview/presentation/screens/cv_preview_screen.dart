import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/personal_info_model.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../providers/pdf_export_provider.dart';
import '../widgets/export_pdf_dialog.dart';

class CvPreviewScreen extends ConsumerStatefulWidget {
  const CvPreviewScreen({super.key, this.cv});

  final CvModel? cv;

  @override
  ConsumerState<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends ConsumerState<CvPreviewScreen> {
  late String _selectedTemplate;
  late String _cvLanguage;
  late double _fontSizeScale;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.cv?.templateId ?? 'harvard_ats';
    _cvLanguage = widget.cv?.language ?? 'vi';
    _fontSizeScale = widget.cv?.fontSizeScale ?? 1.0;
  }

  void _onFontScaleChanged(double newScale) {
    setState(() => _fontSizeScale = newScale);
    final cv = widget.cv;
    if (cv != null) {
      ref.read(cvRepositoryProvider).save(
        cv.copyWith(fontSizeScale: newScale),
      );
    }
  }

  Future<void> _handleExportPdf() async {
    final isEn = _cvLanguage == 'en';
    final cv = widget.cv;
    final fullNameRaw = cv?.personalInfo.fullName.trim() ?? '';
    final defaultBaseName = fullNameRaw.isNotEmpty
        ? 'CV_${fullNameRaw.replaceAll(RegExp(r'\s+'), '_')}'
        : (isEn ? 'CV_My_Resume' : 'CV_Nguyen_Tuan_Anh');
    final defaultFileName = '$defaultBaseName.pdf';

    final chosenFileName = await ExportPdfDialog.show(
      context: context,
      initialFileName: defaultFileName,
      isEnglish: isEn,
      fontSizeScale: _fontSizeScale,
    );

    if (chosenFileName == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      final pdfService = ref.read(pdfExportServiceProvider);
      final effectiveCv = (cv ??
          CvModel(
            id: 'sample_cv',
            title: defaultBaseName,
            templateId: _selectedTemplate,
            language: _cvLanguage,
            primaryColor: '#1E293B',
            fontSizeScale: _fontSizeScale,
            personalInfo: const PersonalInfoModel(),
            summary: '',
            isSynced: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )).copyWith(
            language: _cvLanguage,
            templateId: _selectedTemplate,
            fontSizeScale: _fontSizeScale,
          );

      final bytes = await pdfService.generateCvPdf(
        cv: effectiveCv,
        language: _cvLanguage,
        templateId: _selectedTemplate,
      );

      await pdfService.savePdfLocally(
        bytes: bytes,
        fileName: chosenFileName,
      );

      await pdfService.shareOrSavePdf(
        bytes: bytes,
        fileName: chosenFileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEn
                        ? 'Exported "$chosenFileName" successfully!\nSaved to phone storage & ready to share.'
                        : 'Đã xuất "$chosenFileName" thành công!\nĐã lưu vào bộ nhớ máy và sẵn sàng lưu/chia sẻ.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEn ? 'Error exporting PDF: $e' : 'Lỗi khi xuất tệp PDF: $e',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.dangerRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildScaleChip(double scale, String label) {
    final isSelected = (_fontSizeScale - scale).abs() < 0.02;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onFontScaleChanged(scale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primarySlate : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primarySlate : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.primarySlate,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = _cvLanguage == 'en';
    final cv = widget.cv;
    final scale = _fontSizeScale;

    // Resolve Dynamic Values
    final fullName = (cv?.personalInfo.fullName.isNotEmpty == true)
        ? cv!.personalInfo.fullName.toUpperCase()
        : (isEn ? 'TUAN ANH NGUYEN' : 'NGUYỄN TUẤN ANH');

    final targetRole = (cv?.personalInfo.targetRole.isNotEmpty == true)
        ? cv!.personalInfo.targetRole.toUpperCase()
        : (isEn ? 'FULLSTACK SOFTWARE ENGINEER' : 'KỸ SƯ PHẦN MỀM FLUTTER');

    final address = (cv?.personalInfo.address.isNotEmpty == true)
        ? cv!.personalInfo.address
        : (isEn ? 'Hanoi, Vietnam' : 'Hà Nội, Việt Nam');

    final phone = (cv?.personalInfo.phone.isNotEmpty == true)
        ? cv!.personalInfo.phone
        : '0901 234 567';

    final email = (cv?.personalInfo.email.isNotEmpty == true)
        ? cv!.personalInfo.email
        : 'tuananh@example.com';

    final summary = (cv?.summary.isNotEmpty == true)
        ? cv!.summary
        : (isEn
            ? 'Results-driven Fullstack Software Engineer specializing in cross-platform mobile architectures with Flutter, Dart, Clean Architecture, and Riverpod. Proven track record in engineering offline-first SQLite databases, vector PDF document rendering engines, and scalable Supabase cloud integrations.'
            : 'Kỹ sư phần mềm mobile chuyên sâu về Flutter, kiến trúc Clean Architecture, State Management (Riverpod) và tích hợp Backend-as-a-Service (Supabase). Đam mê tối ưu hóa trải nghiệm người dùng và xây dựng hệ thống bền vững.');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEn ? 'Resume Preview' : 'Xem trước CV'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTemplate,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppTheme.primarySlate,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'harvard_ats',
                  child: Text(
                    'Harvard ATS',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownMenuItem(
                  value: 'modern_minimalist',
                  child: Text(
                    'Modern Minimalist',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedTemplate = val);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: Column(
            children: [
              // Language Selector Segmented Control
              Container(
                constraints: const BoxConstraints(maxWidth: 550),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _cvLanguage = 'en'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isEn ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isEn
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🇬🇧 ', style: TextStyle(fontSize: 14)),
                              Text(
                                'English (ATS Tech)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      isEn ? FontWeight.w700 : FontWeight.w500,
                                  color: isEn
                                      ? AppTheme.primarySlate
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _cvLanguage = 'vi'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !isEn ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !isEn
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🇻🇳 ', style: TextStyle(fontSize: 14)),
                              Text(
                                'Tiếng Việt',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      !isEn ? FontWeight.w700 : FontWeight.w500,
                                  color: !isEn
                                      ? AppTheme.primarySlate
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Font Size Controller Bar (Inspired by font-size-app)
              Container(
                constraints: const BoxConstraints(maxWidth: 550),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.format_size_rounded,
                      size: 20,
                      color: AppTheme.accentTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'Scale:' : 'Cỡ chữ:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primarySlate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildScaleChip(0.90, isEn ? '0.9x' : '0.9x Gọn'),
                            const SizedBox(width: 6),
                            _buildScaleChip(1.00, isEn ? '1.0x' : '1.0x Chuẩn'),
                            const SizedBox(width: 6),
                            _buildScaleChip(1.15, isEn ? '1.15x' : '1.15x Lớn'),
                            const SizedBox(width: 6),
                            _buildScaleChip(1.25, isEn ? '1.25x' : '1.25x Rộng'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // A4 Sheet Container Simulation (Enforcing True A4 Aspect Ratio 1 : 1.4142)
              LayoutBuilder(
                builder: (context, constraints) {
                  final sheetWidth = constraints.maxWidth.clamp(0.0, 550.0);
                  // Standard A4 aspect ratio: Height / Width = 297mm / 210mm ≈ 1.4142
                  final a4MinHeight = sheetWidth * 1.4142;

                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: 550,
                      minHeight: a4MinHeight,
                    ),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Harvard ATS Header (Centered)
                    Text(
                      fullName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19 * scale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      targetRole,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5 * scale,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      '$address • $phone • $email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    Divider(color: Colors.black, thickness: 1.2 * scale),
                    SizedBox(height: 10 * scale),

                    // Section 1: Summary
                    _buildSectionHeader(
                      isEn
                          ? 'PROFESSIONAL SUMMARY'
                          : 'TÓM TẮT MỤC TIÊU NGHỀ NGHIỆP',
                      scale,
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: 11.5 * scale,
                        height: 1.45,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16 * scale),

                    // Section 2: Education
                    _buildSectionHeader(isEn ? 'EDUCATION' : 'HỌC VẤN', scale),
                    SizedBox(height: 6 * scale),
                    if (cv != null && cv.educations.isNotEmpty) ...[
                      ...cv.educations.map((edu) {
                        final startYear = edu.startDate.year;
                        final endYear = edu.isCurrent
                            ? (isEn ? 'Present' : 'Hiện tại')
                            : (edu.endDate?.year.toString() ?? '');
                        final period = '$startYear - $endYear';
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8 * scale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      edu.institution.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11.5 * scale,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    period,
                                    style: TextStyle(
                                      fontSize: 11 * scale,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${edu.degree} — ${edu.fieldOfStudy}${edu.gpa != null ? ' (GPA: ${edu.gpa})' : ''}',
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isEn
                                  ? 'HANOI UNIVERSITY OF SCIENCE AND TECH'
                                  : 'ĐẠI HỌC BÁCH KHOA HÀ NỘI',
                              style: TextStyle(
                                fontSize: 11.5 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '2020 - 2024',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isEn
                            ? 'Bachelor of Engineering in Computer Science — GPA: 3.6 / 4.0'
                            : 'Kỹ sư Công nghệ Thông tin - GPA: 3.6/4.0',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    SizedBox(height: 16 * scale),

                    // Section 3: Experience
                    _buildSectionHeader(
                      isEn
                          ? 'WORK EXPERIENCE & PROJECTS'
                          : 'KINH NGHIỆM LÀM VIỆC & DỰ ÁN',
                      scale,
                    ),
                    SizedBox(height: 6 * scale),
                    if (cv != null && cv.experiences.isNotEmpty) ...[
                      ...cv.experiences.map((exp) {
                        final startStr =
                            '${exp.startDate.month.toString().padLeft(2, '0')}/${exp.startDate.year}';
                        final endStr = exp.isCurrent
                            ? (isEn ? 'Present' : 'Hiện tại')
                            : (exp.endDate != null
                                ? '${exp.endDate!.month.toString().padLeft(2, '0')}/${exp.endDate!.year}'
                                : '');
                        final period = '$startStr - $endStr';

                        return Padding(
                          padding: EdgeInsets.only(bottom: 10 * scale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      exp.company.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11.5 * scale,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    period,
                                    style: TextStyle(
                                      fontSize: 11 * scale,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                exp.location.isNotEmpty
                                    ? '${exp.jobTitle} • ${exp.location}'
                                    : exp.jobTitle,
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              SizedBox(height: 3 * scale),
                              ...exp.bulletPoints.map(
                                (b) => _buildBulletPoint(b, scale),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isEn
                                  ? 'TECH SOLUTIONS GLOBAL'
                                  : 'CÔNG TY CỔ PHẦN CÔNG NGHỆ TECH',
                              style: TextStyle(
                                fontSize: 11.5 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? '01/2023 - Present' : '01/2023 - Hiện tại',
                            style: TextStyle(
                              fontSize: 11 * scale,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isEn
                            ? 'Lead Mobile & Fullstack Engineer'
                            : 'Kỹ sư phần mềm Flutter',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      _buildBulletPoint(
                        isEn
                            ? 'Architected production mobile app using Clean Architecture, Riverpod, and Drift SQLite.'
                            : 'Thiết kế kiến trúc Clean Architecture nhiều tầng tách biệt presentation, domain và data.',
                        scale,
                      ),
                      _buildBulletPoint(
                        isEn
                            ? 'Engineered high-performance A4 vector PDF engine with automated pagination.'
                            : 'Tối ưu hóa công cụ render PDF A4 vector độ nét cao, ngăn chặn tràn trang thông minh.',
                        scale,
                      ),
                      _buildBulletPoint(
                        isEn
                            ? 'Integrated Supabase Singapore Cloud backend with real-time replication.'
                            : 'Tích hợp xác thực và đồng bộ dữ liệu đám mây Supabase Singapore bảo mật cao.',
                        scale,
                      ),
                    ],
                    SizedBox(height: 16 * scale),

                    // Section 4: Skills
                    _buildSectionHeader(
                      isEn ? 'TECHNICAL SKILLS' : 'KỸ NĂNG CHUYÊN MÔN',
                      scale,
                    ),
                    SizedBox(height: 6 * scale),
                    if (cv != null && cv.skills.isNotEmpty) ...[
                      Builder(
                        builder: (context) {
                          final hard = cv.skills
                              .where((s) => s.category == SkillCategory.hard)
                              .map((s) => s.name)
                              .join(', ');
                          final soft = cv.skills
                              .where((s) => s.category == SkillCategory.soft)
                              .map((s) => s.name)
                              .join(', ');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (hard.isNotEmpty)
                                Text(
                                  '• ${isEn ? "Technical & Frameworks: " : "Kỹ năng chuyên môn: "}$hard',
                                  style: TextStyle(
                                    fontSize: 11 * scale,
                                    height: 1.45,
                                    color: Colors.black87,
                                  ),
                                ),
                              if (soft.isNotEmpty)
                                Text(
                                  '• ${isEn ? "Methodologies & Soft Skills: " : "Kỹ năng mềm & Phương pháp: "}$soft',
                                  style: TextStyle(
                                    fontSize: 11 * scale,
                                    height: 1.45,
                                    color: Colors.black87,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      Text(
                        isEn
                            ? '• Languages & Frameworks: Flutter, Dart, TypeScript, Kotlin, SQL\n'
                                '• Backend & Cloud: Supabase, PostgreSQL, Row-Level Security, REST APIs\n'
                                '• Architecture & Tools: Clean Architecture, Riverpod, Git Flow, CI/CD, Vector PDF Engine'
                            : '• Ngôn ngữ & Framework: Flutter, Dart, TypeScript, Kotlin\n'
                                '• Backend & Database: Supabase, PostgreSQL, Row-Level Security, REST API\n'
                                '• Kiến trúc & Công cụ: Clean Architecture, Riverpod, Git Flow, Vector PDF Engine',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    // Standard A4 Paper visual indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 13,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isEn
                              ? 'Standard A4 Page (210 × 297 mm)'
                              : 'Khổ giấy A4 tiêu chuẩn (210 × 297 mm)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : _handleExportPdf,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              _isExporting
                  ? (isEn ? 'Exporting PDF...' : 'Đang xuất PDF...')
                  : (isEn
                      ? 'Download PDF (A4) - English'
                      : 'Tải xuống File PDF (A4) - Tiếng Việt'),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(String title, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.black,
          ),
        ),
        Divider(color: Colors.black54, thickness: 0.8 * scale, height: 6 * scale),
      ],
    );
  }

  static Widget _buildBulletPoint(String text, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11 * scale,
                height: 1.35,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
