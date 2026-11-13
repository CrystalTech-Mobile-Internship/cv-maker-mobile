import '../models/cv_model.dart';

/// Removes bullet glyphs typed or imported at the start of list lines.
///
/// Templates draw their own bullet, so "• Built X" would otherwise print
/// as "• • Built X".
abstract final class CvBulletCleaner {
  static final RegExp _leading = RegExp(r'^\s*[•·▪◦●○\-–—*]+\s*');

  static String line(String value) => value.replaceFirst(_leading, '');

  static String lines(String value) => value.split('\n').map(line).join('\n');

  static CvModel clean(CvModel cv) {
    return cv.copyWith(
      experiences: [
        for (final item in cv.experiences)
          item.copyWith(
            bulletPoints: [
              for (final bullet in item.bulletPoints) line(bullet),
            ],
          ),
      ],
      projects: [
        for (final item in cv.projects)
          item.copyWith(description: lines(item.description)),
      ],
      educations: [
        for (final item in cv.educations)
          item.copyWith(
            achievements: [
              for (final achievement in item.achievements) line(achievement),
            ],
          ),
      ],
    );
  }
}
