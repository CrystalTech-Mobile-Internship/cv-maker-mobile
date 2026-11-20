import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('free keeps simple one-column designs and Pro gets the rest', () {
    final free = CvTemplateCatalog.freeTemplates;
    final pro = CvTemplateCatalog.premiumTemplates;
    final all = CvTemplateCatalog.allTemplates;

    expect(free, hasLength(6));
    expect(pro.length, greaterThan(free.length));
    expect(free.where((item) => item.hasPhoto), hasLength(1));
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
        CvTemplateLayout.banner,
        CvTemplateLayout.timeline,
        CvTemplateLayout.accent,
      ]),
    );
    // Designs with their own structure are Pro only.
    const proLayouts = {
      CvTemplateLayout.sidebar,
      CvTemplateLayout.banner,
      CvTemplateLayout.timeline,
      CvTemplateLayout.accent,
    };
    expect(free.any((t) => proLayouts.contains(t.layout)), isFalse);
  });

  test('templates moved to Pro still resolve for existing CVs', () {
    for (final id in ['professional_sidebar', 'fresh_profile']) {
      final template = CvTemplateCatalog.byId(id);
      expect(template.id, id);
      expect(template.isPremium, isTrue);
    }
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
