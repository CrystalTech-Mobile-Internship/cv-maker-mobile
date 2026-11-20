import '../models/cv_model.dart';
import '../../../../core/i18n/app_language.dart';

/// One user-facing requirement used to estimate whether a CV is ready.
class CvCompletionItem {
  const CvCompletionItem({
    required this.id,
    required this.label,
    required this.isCompleted,
  });

  final String id;
  final String label;
  final bool isCompleted;
}

/// Pure-domain result that can be reused by Home, Preview and future reports.
class CvCompletionReport {
  const CvCompletionReport({required this.items});

  final List<CvCompletionItem> items;

  int get completedCount => items.where((item) => item.isCompleted).length;

  int get percentage =>
      items.isEmpty ? 0 : (completedCount / items.length * 100).round();

  List<CvCompletionItem> get missingItems =>
      items.where((item) => !item.isCompleted).toList(growable: false);
}

/// Evaluates only locally available CV data; no network or storage dependency.
abstract final class CvCompletionService {
  static CvCompletionReport evaluate(CvModel cv) {
    final personal = cv.personalInfo;
    return CvCompletionReport(
      items: List.unmodifiable([
        CvCompletionItem(
          id: 'full-name',
          label: tr('Họ và tên', 'Full name'),
          isCompleted: personal.fullName.trim().isNotEmpty,
        ),
        CvCompletionItem(
          id: 'target-role',
          label: tr('Vị trí ứng tuyển', 'Target role'),
          isCompleted: personal.targetRole.trim().isNotEmpty,
        ),
        CvCompletionItem(
          id: 'contact',
          label: tr('Email và số điện thoại', 'Email and phone'),
          isCompleted:
              personal.email.trim().isNotEmpty &&
              personal.phone.trim().isNotEmpty,
        ),
        CvCompletionItem(
          id: 'summary',
          label: tr('Tóm tắt nghề nghiệp', 'Professional summary'),
          isCompleted: cv.summary.trim().isNotEmpty,
        ),
        CvCompletionItem(
          id: 'education',
          label: tr('Học vấn', 'Education'),
          isCompleted: cv.educations.isNotEmpty,
        ),
        CvCompletionItem(
          id: 'experience',
          label: tr('Kinh nghiệm', 'Experience'),
          isCompleted: cv.experiences.isNotEmpty,
        ),
        CvCompletionItem(
          id: 'skills',
          label: tr('Kỹ năng', 'Skills'),
          isCompleted: cv.skills.isNotEmpty,
        ),
        CvCompletionItem(
          id: 'projects',
          label: tr('Dự án', 'Projects'),
          isCompleted: cv.projects.isNotEmpty,
        ),
      ]),
    );
  }
}
