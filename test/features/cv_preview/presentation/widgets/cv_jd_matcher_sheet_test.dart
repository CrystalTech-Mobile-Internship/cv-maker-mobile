import 'package:cv_maker_mobile/features/ai_tools/presentation/controllers/ai_assistant_providers.dart';
import 'package:cv_maker_mobile/features/auth/domain/models/auth_user.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/cv_model.dart';
import 'package:cv_maker_mobile/features/cv_editor/domain/models/skill_model.dart';
import 'package:cv_maker_mobile/features/cv_preview/presentation/widgets/cv_jd_matcher_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ai_tools/helpers/fake_ai_assistant_repository.dart';

final _cv = CvModel.empty(id: 'test-cv').copyWith(
  skills: const [
    SkillModel(id: 's1', name: 'Flutter', category: SkillCategory.hard),
    SkillModel(id: 's2', name: 'Dart', category: SkillCategory.hard),
  ],
);

const _user = AuthUser(
  id: 'u1',
  email: 'me@example.com',
  displayName: 'Me',
  provider: 'email',
  isEmailConfirmed: true,
);

Widget _app({
  required ValueChanged<SkillModel> onAdd,
  AuthUser? user,
  FakeAiAssistantRepository? repository,
}) {
  return ProviderScope(
    overrides: [
      currentAuthUserProvider.overrideWithValue(user),
      aiAssistantRepositoryProvider.overrideWithValue(
        repository ?? FakeAiAssistantRepository(),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CvJdMatcherSheet(cv: _cv, onAddMissingSkill: onAdd),
      ),
    ),
  );
}

void main() {
  testWidgets('scores pasted job text and adds a missing skill', (
    tester,
  ) async {
    SkillModel? added;
    await tester.pumpWidget(_app(onAdd: (s) => added = s));

    await tester.enterText(
      find.byKey(const Key('jd-matcher-input')),
      'Cần Flutter, Dart, Firebase và Git cho dự án mobile.',
    );
    await tester.tap(find.byKey(const Key('jd-matcher-submit')));
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsOneWidget);
    await tester.tap(find.text('Firebase'));
    await tester.pumpAndSettle();
    expect(added?.name, 'Firebase');
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('reads a job link for signed-in users', (tester) async {
    SharedPreferences.setMockInitialValues({'ai_data_consent_v1': true});
    await tester.pumpWidget(_app(onAdd: (_) {}, user: _user));

    await tester.enterText(
      find.byKey(const Key('jd-matcher-input')),
      'https://jobs.example.com/flutter-dev',
    );
    await tester.tap(find.byKey(const Key('jd-matcher-submit')));
    await tester.pumpAndSettle();

    // Fake posting: Flutter, Dart, Git, Docker -> 2 of 4 on the CV.
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Docker'), findsOneWidget);
  });

  testWidgets('asks guests to sign in before reading a link', (tester) async {
    await tester.pumpWidget(_app(onAdd: (_) {}));

    await tester.enterText(
      find.byKey(const Key('jd-matcher-input')),
      'https://jobs.example.com/flutter-dev',
    );
    await tester.tap(find.byKey(const Key('jd-matcher-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Cần đăng nhập'), findsOneWidget);
  });
}
