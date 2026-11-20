import 'package:cv_maker_mobile/core/widgets/home_fallback_leading.dart';
import 'package:cv_maker_mobile/features/admin/presentation/admin_providers.dart';
import 'package:cv_maker_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:cv_maker_mobile/features/cv_management/presentation/widgets/desktop_tool_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _ToolPage extends StatelessWidget {
  const _ToolPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: homeFallbackLeading(context),
      title: const Text('Tool page'),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/job-tracker',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const Text('home')),
      GoRoute(
        path: '/job-tracker',
        builder: (_, _) =>
            const DesktopToolFrame(route: '/job-tracker', child: _ToolPage()),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAuthUserProvider.overrideWithValue(null),
        isAdminProvider.overrideWith((ref) async => false),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('on a computer the tool opens inside the sidebar layout', (
    tester,
  ) async {
    await _pump(tester, const Size(1280, 800));

    expect(find.text('Tool page'), findsOneWidget);
    expect(find.byKey(const Key('tool-job-tracker')), findsOneWidget);
    expect(find.byKey(const Key('tool-support')), findsOneWidget);
    // The sidebar is always there, so no back button.
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('on a phone the tool keeps its own page', (tester) async {
    await _pump(tester, const Size(390, 800));

    expect(find.text('Tool page'), findsOneWidget);
    expect(find.byKey(const Key('tool-job-tracker')), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}
