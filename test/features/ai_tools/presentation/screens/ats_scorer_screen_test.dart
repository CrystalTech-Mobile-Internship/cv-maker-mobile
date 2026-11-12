import 'package:cv_maker_mobile/features/ai_tools/presentation/screens/ats_scorer_screen.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/models.dart';
import 'package:cv_maker_mobile/features/cv_management/presentation/controllers/cv_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scores the selected CV against the pasted JD', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cv = CvModel.empty(id: 'cv-1').copyWith(
      title: 'Flutter CV',
      summary: 'Flutter developer with Dart and Firebase.',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cvListStreamProvider.overrideWith((ref) => Stream.value([cv])),
        ],
        child: const MaterialApp(home: AtsScorerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('ats-jd-input')),
      'Yêu cầu Flutter, Dart, Firebase và Docker cho dự án mobile.',
    );
    await tester.ensureVisible(find.text('Chấm điểm CV theo JD'));
    await tester.tap(find.text('Chấm điểm CV theo JD'));
    await tester.pumpAndSettle();

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Docker'), findsOneWidget);
    expect(find.text('Thêm kỹ năng còn thiếu'), findsOneWidget);
  });

  testWidgets('shows an empty notice without local CVs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cvListStreamProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: AtsScorerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Bạn chưa có CV nào'), findsOneWidget);
  });
}
