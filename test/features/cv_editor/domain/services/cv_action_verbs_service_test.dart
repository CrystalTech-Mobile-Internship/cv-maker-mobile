import 'package:flutter_test/flutter_test.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/services/cv_action_verbs_service.dart';

void main() {
  group('CvActionVerbsService', () {
    test('contains curated action verbs across categories', () {
      expect(CvActionVerbsService.verbs.length, greaterThanOrEqualTo(8));
      final item = CvActionVerbsService.verbs.first;
      expect(item.verb('vi').isNotEmpty, isTrue);
      expect(item.verb('en').isNotEmpty, isTrue);
      expect(item.example('vi').isNotEmpty, isTrue);
      expect(item.example('en').isNotEmpty, isTrue);
    });

    test('getByCategory filters correctly', () {
      final eng = CvActionVerbsService.getByCategory('engineering');
      expect(eng.every((v) => v.category == 'engineering'), isTrue);

      final all = CvActionVerbsService.getByCategory('all');
      expect(all.length, CvActionVerbsService.verbs.length);
    });
  });
}
