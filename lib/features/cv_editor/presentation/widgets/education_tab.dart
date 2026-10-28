import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/models/education_model.dart';

/// Tab for displaying and managing Education & Degrees.
class EducationTab extends StatelessWidget {
  const EducationTab({
    super.key,
    required this.educations,
    required this.onAddEducation,
    this.onEditEducation,
    this.onDeleteEducation,
    this.language = 'vi',
  });

  final List<EducationModel> educations;
  final VoidCallback onAddEducation;
  final ValueChanged<EducationModel>? onEditEducation;
  final ValueChanged<String>? onDeleteEducation;
  final String language;

  bool get _isEn => language == 'en';

  @override
  Widget build(BuildContext context) {
    if (educations.isEmpty) {
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
                  Icons.school_rounded,
                  size: 38,
                  color: AppTheme.primarySlate,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEn ? 'Education & Degrees' : 'Học vấn & Bằng cấp',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isEn
                    ? 'Add universities, degree levels, graduation year, and GPA.'
                    : 'Thêm thông tin trường đại học, niên khóa, bằng cấp và GPA của bạn.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddEducation,
                icon: const Icon(Icons.add_rounded),
                label: Text(_isEn ? 'Add Education' : 'Thêm mục mới'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        ...educations.map((item) {
          final startYear = item.startDate.year;
          final endYear = item.isCurrent
              ? (_isEn ? 'Present' : 'Hiện tại')
              : (item.endDate?.year.toString() ?? '');
          final period = '$startYear - $endYear';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
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
                      Icons.school_outlined,
                      color: AppTheme.primarySlate,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.institution,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.degree} • ${item.fieldOfStudy}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              period,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            if (item.gpa != null && item.gpa!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'GPA: ${item.gpa}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEditEducation != null)
                        IconButton(
                          tooltip: _isEn ? 'Edit' : 'Chỉnh sửa',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => onEditEducation!(item),
                        ),
                      if (onDeleteEducation != null)
                        IconButton(
                          tooltip: _isEn ? 'Delete' : 'Xoá',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.red.shade400,
                          ),
                          onPressed: () => onDeleteEducation!(item.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onAddEducation,
          icon: const Icon(Icons.add_rounded),
          label: Text(_isEn ? 'Add Another Education' : 'Thêm mục học vấn'),
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
