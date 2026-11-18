import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_preview/data/services/pdf_export_service_impl.dart';
import 'package:cv_maker_mobile/features/cv_preview/domain/models/pdf_section_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('records one region per visible section, top to bottom', () async {
    final cv = CvModel.empty(id: 'r1').copyWith(
      summary: 'Backend developer who builds reliable services.',
      skills: const [
        SkillModel(id: 's1', name: 'Dart', category: SkillCategory.hard),
      ],
      experiences: [
        ExperienceModel(
          id: 'e1',
          jobTitle: 'Intern',
          company: 'ACME',
          startDate: DateTime.utc(2024),
          bulletPoints: const ['Built an app'],
        ),
      ],
    );
    final regions = <PdfSectionRegion>[];

    await PdfExportServiceImpl().generateCvPdf(
      cv: cv,
      language: 'vi',
      sectionRegions: regions,
    );

    final ids = regions.map((r) => r.section).toList();
    expect(ids, containsAllInOrder(['summary', 'experience', 'skills']));
    for (var i = 1; i < regions.length; i++) {
      if (regions[i].page == regions[i - 1].page) {
        expect(regions[i].top, greaterThanOrEqualTo(regions[i - 1].top));
      }
    }
    expect(regions.every((r) => r.height > 0 && r.width > 100), isTrue);
  });
}
