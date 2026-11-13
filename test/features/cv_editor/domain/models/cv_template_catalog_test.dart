import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog keeps six free templates and the rest for Pro', () {
    final free = CvTemplateCatalog.freeTemplates;
    final all = CvTemplateCatalog.allTemplates;

    expect(free, hasLength(6));
    expect(free.every((item) => !item.isPremium), isTrue);
    expect(
      CvTemplateCatalog.premiumTemplates.every((t) => t.isPremium),
      isTrue,
    );
    expect(all.map((item) => item.id).toSet().length, all.length);
    expect(free.where((item) => item.hasPhoto), isNotEmpty);
    expect(free.where((item) => !item.hasPhoto), isNotEmpty);
    expect(
      all.map((item) => item.layout).toSet(),
      containsAll([
        CvTemplateLayout.classic,
        CvTemplateLayout.modern,
        CvTemplateLayout.sidebar,
        CvTemplateLayout.executive,
      ]),
    );
  });

  test('only Pro accounts can pick every template', () {
    expect(
      CvTemplateCatalog.available(isPro: false),
      CvTemplateCatalog.freeTemplates,
    );
    expect(
      CvTemplateCatalog.available(isPro: true),
      CvTemplateCatalog.allTemplates,
    );
  });
}
