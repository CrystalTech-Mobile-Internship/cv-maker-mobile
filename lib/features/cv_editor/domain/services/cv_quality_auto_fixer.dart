import '../models/models.dart';
import '../../../../core/i18n/app_language.dart';

class CvAutoFixResult {
  const CvAutoFixResult({required this.cv, required this.changes});

  final CvModel cv;

  /// Human-readable list of what was fixed (empty when nothing changed).
  final List<String> changes;

  bool get hasChanges => changes.isNotEmpty;
}

/// Safe, meaning-preserving formatting fixes for issues reported by the
/// quality checker: whitespace, bullet symbols, capitalisation, empty
/// bullets and duplicate skills. Never rewrites wording.
abstract final class CvQualityAutoFixer {
  static final _spaces = RegExp(r'[ \t]{2,}');
  static final _bulletPrefix = RegExp(r'^\s*([-•*●▪◦]+|\d+[.)])\s+');

  static String _clean(String text) => text.replaceAll(_spaces, ' ').trim();

  static String _cleanBullet(String text) {
    var value = _clean(text.replaceFirst(_bulletPrefix, ''));
    if (value.isNotEmpty) {
      value = value[0].toUpperCase() + value.substring(1);
    }
    return value;
  }

  static CvAutoFixResult fix(CvModel cv) {
    var bulletFixes = 0;
    var removedBullets = 0;

    List<String> fixList(List<String> bullets) {
      final result = <String>[];
      for (final bullet in bullets) {
        final cleaned = _cleanBullet(bullet);
        if (cleaned.isEmpty) {
          removedBullets++;
          continue;
        }
        if (cleaned != bullet) bulletFixes++;
        result.add(cleaned);
      }
      return result;
    }

    final experiences = [
      for (final e in cv.experiences)
        e.copyWith(bulletPoints: fixList(e.bulletPoints)),
    ];
    final educations = [
      for (final e in cv.educations)
        e.copyWith(achievements: fixList(e.achievements)),
    ];

    final summary = _clean(cv.summary);
    final seen = <String>{};
    final skills = <SkillModel>[];
    var duplicateSkills = 0;
    for (final skill in cv.skills) {
      final key = skill.name.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) {
        duplicateSkills++;
        continue;
      }
      skills.add(skill);
    }

    final info = cv.personalInfo;
    final cleanedInfo = info.copyWith(
      fullName: _clean(info.fullName),
      targetRole: _clean(info.targetRole),
      email: info.email.trim().toLowerCase(),
      phone: _clean(info.phone),
      address: _clean(info.address),
    );
    final infoChanged =
        cleanedInfo.fullName != info.fullName ||
        cleanedInfo.targetRole != info.targetRole ||
        cleanedInfo.email != info.email ||
        cleanedInfo.phone != info.phone ||
        cleanedInfo.address != info.address;

    final changes = <String>[
      if (bulletFixes > 0)
        tr(
          'Chuẩn hóa $bulletFixes gạch đầu dòng (viết hoa, bỏ ký hiệu thừa, khoảng trắng).',
          'Tidied $bulletFixes bullet points (capitals, extra symbols, spaces).',
        ),
      if (removedBullets > 0)
        tr(
          'Xóa $removedBullets gạch đầu dòng trống.',
          'Removed $removedBullets empty bullet points.',
        ),
      if (duplicateSkills > 0)
        tr(
          'Gộp $duplicateSkills kỹ năng bị trùng.',
          'Merged $duplicateSkills duplicate skills.',
        ),
      if (summary != cv.summary)
        tr(
          'Dọn khoảng trắng thừa trong tóm tắt.',
          'Removed extra spaces in the summary.',
        ),
      if (infoChanged)
        tr('Chuẩn hóa thông tin liên hệ.', 'Tidied contact details.'),
    ];
    if (changes.isEmpty) return CvAutoFixResult(cv: cv, changes: const []);

    return CvAutoFixResult(
      cv: cv.copyWith(
        summary: summary,
        skills: skills,
        experiences: experiences,
        educations: educations,
        personalInfo: cleanedInfo,
      ),
      changes: changes,
    );
  }
}
