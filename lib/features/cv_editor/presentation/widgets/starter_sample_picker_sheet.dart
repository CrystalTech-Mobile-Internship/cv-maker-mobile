import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/certification_model.dart';
import '../../domain/models/education_model.dart';
import '../../domain/models/experience_model.dart';
import '../../domain/models/project_model.dart';
import '../../domain/models/skill_model.dart';
import '../../domain/services/cv_starter_template_service.dart';
import '../../../../core/widgets/app_sheet.dart';

class StarterSamplePickerSheet extends StatelessWidget {
  const StarterSamplePickerSheet({
    super.key,
    required this.language,
    this.onSelectSummary,
    this.onAddExperiences,
    this.onAddProjects,
    this.onAddSkills,
    this.onAddEducation,
    this.onAddCertifications,
  });

  final String language;
  final ValueChanged<String>? onSelectSummary;
  final ValueChanged<List<ExperienceModel>>? onAddExperiences;
  final ValueChanged<List<ProjectModel>>? onAddProjects;
  final ValueChanged<List<SkillModel>>? onAddSkills;
  final ValueChanged<List<EducationModel>>? onAddEducation;
  final ValueChanged<List<CertificationModel>>? onAddCertifications;

  bool get _isEn => language == 'en';

  static Future<void> show({
    required BuildContext context,
    required String language,
    ValueChanged<String>? onSelectSummary,
    ValueChanged<List<ExperienceModel>>? onAddExperiences,
    ValueChanged<List<ProjectModel>>? onAddProjects,
    ValueChanged<List<SkillModel>>? onAddSkills,
    ValueChanged<List<EducationModel>>? onAddEducation,
    ValueChanged<List<CertificationModel>>? onAddCertifications,
  }) {
    return showAppSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StarterSamplePickerSheet(
        language: language,
        onSelectSummary: onSelectSummary,
        onAddExperiences: onAddExperiences,
        onAddProjects: onAddProjects,
        onAddSkills: onAddSkills,
        onAddEducation: onAddEducation,
        onAddCertifications: onAddCertifications,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: DefaultTabController(
          length: 5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pill
              AppSheetHandle(margin: const EdgeInsets.only(top: 10, bottom: 8)),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.indigoSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppTheme.brandIndigo,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEn
                                ? 'Starter Templates & Guidance'
                                : 'Mẫu gợi ý nội dung có sẵn',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isEn
                                ? 'Insert ready-made samples to write your CV faster'
                                : 'Chèn mẫu chuyên nghiệp để không phải viết từ đầu',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                isScrollable: true,
                labelColor: AppTheme.brandIndigo,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppTheme.brandIndigo,
                indicatorWeight: 3,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: _isEn ? 'Summary' : 'Mục tiêu'),
                  Tab(text: _isEn ? 'Experience' : 'Kinh nghiệm'),
                  Tab(text: _isEn ? 'Projects' : 'Dự án'),
                  Tab(text: _isEn ? 'Skills' : 'Kỹ năng'),
                  Tab(text: _isEn ? 'Education' : 'Học vấn & Bằng cấp'),
                ],
              ),
              const Divider(height: 1),
              // Tab views
              Expanded(
                child: TabBarView(
                  children: [
                    _buildSummaryTab(context),
                    _buildExperienceTab(context),
                    _buildProjectsTab(context),
                    _buildSkillsTab(context),
                    _buildEducationTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: CvStarterTemplateService.summaryOptions.length,
      itemBuilder: (context, index) {
        final option = CvStarterTemplateService.summaryOptions[index];
        final title = option.title(language);
        final content = option.content(language);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      color: AppTheme.brandIndigo,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onSelectSummary?.call(content);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isEn
                                ? 'Applied summary sample!'
                                : 'Đã chèn mẫu mục tiêu nghề nghiệp!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(_isEn ? 'Use this sample' : 'Sử dụng mẫu này'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandIndigo,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExperienceTab(BuildContext context) {
    final samples = CvStarterTemplateService.getStarterExperiences(language);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final exp in samples)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${exp.jobTitle} • ${exp.company}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final bullet in exp.bulletPoints)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              bullet,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onAddExperiences?.call(samples);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn
                                  ? 'Added starter experience!'
                                  : 'Đã thêm kinh nghiệm mẫu!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(_isEn ? 'Add sample' : 'Thêm mẫu này'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectsTab(BuildContext context) {
    final samples = CvStarterTemplateService.getStarterProjects(language);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final proj in samples)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${proj.name} — ${proj.role}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final tech in proj.technologies)
                        Chip(
                          label: Text(
                            tech,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    proj.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onAddProjects?.call(samples);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn
                                  ? 'Added starter project!'
                                  : 'Đã thêm dự án mẫu!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(_isEn ? 'Add sample' : 'Thêm mẫu này'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsTab(BuildContext context) {
    final samples = CvStarterTemplateService.getStarterSkills(language);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEn ? 'Recommended Skill Set:' : 'Bộ kỹ năng đề xuất:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in samples)
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppTheme.brandIndigo,
                    child: Text(
                      skill.category.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  label: Text('${skill.name} (${skill.proficiency}%)'),
                ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              onAddSkills?.call(samples);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isEn ? 'Added starter skills!' : 'Đã thêm bộ kỹ năng mẫu!',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              _isEn ? 'Insert All Skills' : 'Chèn tất cả kỹ năng mẫu',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandIndigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationTab(BuildContext context) {
    final eduSamples = CvStarterTemplateService.getStarterEducation(language);
    final certSamples = CvStarterTemplateService.getStarterCertifications(
      language,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final edu in eduSamples)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${edu.institution} (${edu.fieldOfStudy})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  Text(
                    '${edu.degree} • GPA ${edu.gpa}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onAddEducation?.call(eduSamples);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn
                                  ? 'Added starter education!'
                                  : 'Đã thêm học vấn mẫu!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(_isEn ? 'Add sample' : 'Thêm mẫu học vấn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        for (final cert in certSamples)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${cert.name} — ${cert.issuer}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  Text(
                    'Điểm: ${cert.score}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onAddCertifications?.call(certSamples);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn
                                  ? 'Added starter certification!'
                                  : 'Đã thêm chứng chỉ mẫu!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(_isEn ? 'Add sample' : 'Thêm mẫu chứng chỉ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandIndigo,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
