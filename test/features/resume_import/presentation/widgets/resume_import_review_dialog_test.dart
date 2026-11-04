import 'package:cv_maker_mobile/features/resume_import/domain/models/resume_import_draft.dart';
import 'package:cv_maker_mobile/features/resume_import/presentation/widgets/resume_import_review_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('review dialog summarizes structured sections on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final draft = ResumeImportDraft(
      sourceName: 'hoa.docx',
      rawText: 'CV text',
      fullName: 'Trần Văn Hòa',
      targetRole: 'Flutter Developer',
      email: 'hoa@example.com',
      phone: '0912345678',
      address: '',
      summary: 'Flutter developer',
      skills: const ['Flutter', 'Dart'],
      educations: [
        ResumeEducationDraft(
          institution: 'IUH',
          degree: 'Kỹ sư',
          fieldOfStudy: 'CNTT',
          startDate: DateTime.utc(2023),
        ),
      ],
      experiences: [
        ResumeExperienceDraft(
          jobTitle: 'Intern',
          company: 'XYZ',
          startDate: DateTime.utc(2026, 6),
        ),
      ],
      projects: const [
        ResumeProjectDraft(name: 'Smart CV', role: 'Mobile Developer'),
      ],
      certifications: const [
        ResumeCertificationDraft(name: 'TOEIC', score: '700'),
      ],
      warnings: const ['Hãy kiểm tra lại dữ liệu.'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showResumeImportReviewDialog(context, draft),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(find.text('Kiểm tra dữ liệu CV đã đọc'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mục có cấu trúc (4)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mục có cấu trúc (4)'), findsOneWidget);
    for (final label in [
      'Học vấn: 1',
      'Kinh nghiệm: 1',
      'Dự án: 1',
      'Chứng chỉ: 1',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
