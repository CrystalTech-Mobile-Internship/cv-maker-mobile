import 'package:cv_maker_mobile/core/i18n/app_language.dart';
import 'package:cv_maker_mobile/core/i18n/language_menu_button.dart';
import 'package:cv_maker_mobile/features/legal/domain/legal_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppI18n.current = AppLanguage.vi;
  });
  tearDown(() => AppI18n.current = AppLanguage.vi);

  test('tr follows the current language', () {
    expect(tr('Lưu', 'Save'), 'Lưu');
    AppI18n.current = AppLanguage.en;
    expect(tr('Lưu', 'Save'), 'Save');
    expect(LegalDocuments.terms.title, 'Terms of use');
  });

  testWidgets('language menu switches the text and saves the choice', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(appLanguageProvider);
            return MaterialApp(
              home: Scaffold(
                appBar: AppBar(actions: const [LanguageMenuButton()]),
                body: Text(tr('Xin chào', 'Hello')),
              ),
            );
          },
        ),
      ),
    );
    expect(find.text('Xin chào'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-en')));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language'), 'en');
  });
}
