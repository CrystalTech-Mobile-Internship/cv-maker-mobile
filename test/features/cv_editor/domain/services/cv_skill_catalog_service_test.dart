import 'package:flutter_test/flutter_test.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_skill_catalog_service.dart';

void main() {
  group('CvSkillCatalogService', () {
    test('contains expected domain groups with bilingual titles', () {
      expect(CvSkillCatalogService.groups.length, greaterThanOrEqualTo(5));
      final mobileGroup = CvSkillCatalogService.groups.firstWhere((g) => g.id == 'mobile');
      expect(mobileGroup.title('vi'), contains('Di động'));
      expect(mobileGroup.title('en'), contains('Mobile'));
      expect(mobileGroup.skills.any((s) => s.name.contains('Flutter')), isTrue);
    });

    test('findSuggestionsByDomain returns items for valid domain and fallback', () {
      final webSkills = CvSkillCatalogService.findSuggestionsByDomain('web_frontend');
      expect(webSkills.any((s) => s.name.contains('React')), isTrue);

      final fallback = CvSkillCatalogService.findSuggestionsByDomain('non_existing');
      expect(fallback.isNotEmpty, isTrue);
    });
  });
}
