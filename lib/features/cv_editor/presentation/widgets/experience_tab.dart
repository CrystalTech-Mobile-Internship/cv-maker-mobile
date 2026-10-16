import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/experience_model.dart';

/// Tab for displaying and managing Work Experiences & Projects.
class ExperienceTab extends StatelessWidget {
  const ExperienceTab({
    super.key,
    required this.experiences,
    required this.onAddExperience,
    this.onEditExperience,
    this.onDeleteExperience,
    this.language = 'vi',
  });

  final List<ExperienceModel> experiences;
  final VoidCallback onAddExperience;
  final ValueChanged<ExperienceModel>? onEditExperience;
  final ValueChanged<String>? onDeleteExperience;
  final String language;

  bool get _isEn => language == 'en';

  @override
  Widget build(BuildContext context) {
    if (experiences.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primarySlate.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.work_rounded,
                  size: 38,
                  color: AppTheme.primarySlate,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEn ? 'Work Experience' : 'Kinh nghiệm làm việc',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isEn
                    ? 'Describe projects, roles, key achievements, and impact.'
                    : 'Mô tả dự án, vị trí công tác và kết quả đo lường được.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddExperience,
                icon: const Icon(Icons.add_rounded),
                label: Text(_isEn ? 'Add Experience' : 'Thêm mục mới'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        ...experiences.map((item) {
          final startStr =
              '${item.startDate.month.toString().padLeft(2, '0')}/${item.startDate.year}';
          final endStr = item.isCurrent
              ? (_isEn ? 'Present' : 'Hiện tại')
              : (item.endDate != null
                    ? '${item.endDate!.month.toString().padLeft(2, '0')}/${item.endDate!.year}'
                    : '');
          final period = '$startStr - $endStr';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accentTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: AppTheme.accentTeal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.jobTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.location.isNotEmpty
                                  ? '${item.company} • ${item.location}'
                                  : item.company,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              period,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onEditExperience != null)
                            IconButton(
                              tooltip: _isEn ? 'Edit' : 'Chỉnh sửa',
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => onEditExperience!(item),
                            ),
                          if (onDeleteExperience != null)
                            IconButton(
                              tooltip: _isEn ? 'Delete' : 'Xoá',
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () => onDeleteExperience!(item.id),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (item.bulletPoints.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...item.bulletPoints.map(
                      (bp) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                bp,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade800,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAddExperience,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            _isEn ? 'Add Another Experience' : 'Thêm mục kinh nghiệm',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
