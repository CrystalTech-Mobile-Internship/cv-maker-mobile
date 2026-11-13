import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_bullet_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes typed or imported bullet glyphs before printing', () {
    final cv = CvModel.empty(id: 'cv-1').copyWith(
      projects: [
        ProjectModel(
          id: 'p1',
          name: 'Demo',
          role: 'Developer',
          description: '• Built the API\n- Wrote tests\nPlain line',
        ),
      ],
    );

    final cleaned = CvBulletCleaner.clean(cv);

    expect(
      cleaned.projects.single.description,
      'Built the API\nWrote tests\nPlain line',
    );
    expect(CvBulletCleaner.line('  ●  Led a team'), 'Led a team');
    expect(CvBulletCleaner.line('Co-founded a club'), 'Co-founded a club');
  });
}
