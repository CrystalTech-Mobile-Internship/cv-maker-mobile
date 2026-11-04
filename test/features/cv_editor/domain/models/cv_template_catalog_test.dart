import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog offers varied free templates with stable unique ids', () {
    final free = CvTemplateCatalog.freeTemplates;

    expect(free.length, greaterThanOrEqualTo(14));
    expect(free.map((item) => item.id).toSet().length, free.length);
    expect(free.where((item) => item.hasPhoto), isNotEmpty);
    expect(free.where((item) => !item.hasPhoto), isNotEmpty);
    expect(
      free.map((item) => item.layout).toSet(),
      containsAll([
        CvTemplateLayout.classic,
        CvTemplateLayout.modern,
        CvTemplateLayout.sidebar,
        CvTemplateLayout.executive,
      ]),
    );
  });
}
