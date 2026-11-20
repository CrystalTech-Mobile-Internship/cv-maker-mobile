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

Widget _plain(String label) => Scaffold(
  body: Row(
    children: [
      const SizedBox(width: 200, child: Text('sidebar')),
      Expanded(child: Text(label)),
    ],
  ),
);

Future<GoRouter> _pumpPages(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/a',
    routes: [
      GoRoute(
        path: '/a',
        pageBuilder: (context, state) =>
            sidebarPage(context, state, _plain('page a')),
      ),
      GoRoute(
        path: '/b',
        pageBuilder: (context, state) =>
            sidebarPage(context, state, _plain('page b')),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

/// True when anything above [finder] moves, scales or fades.
bool _isAnimating(WidgetTester tester, Finder finder) {
  for (final element in finder.evaluate()) {
    var moving = false;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is FadeTransition && widget.opacity.value < 1) moving = true;
      if (widget is ScaleTransition && widget.scale.value != 1) moving = true;
      if (widget is SlideTransition && widget.position.value != Offset.zero) {
        moving = true;
      }
      return !moving;
    });
    if (moving) return true;
  }
  return false;
}

void main() {
  testWidgets('on a computer switching pages does not animate the sidebar', (
    tester,
  ) async {
    final router = await _pumpPages(tester, const Size(1280, 800));

    router.go('/b');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(_isAnimating(tester, find.text('sidebar')), isFalse);
    await tester.pumpAndSettle();
  });

  testWidgets('on a phone pages keep their animation', (tester) async {
    final router = await _pumpPages(tester, const Size(390, 800));

    router.go('/b');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(_isAnimating(tester, find.text('sidebar')), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
  });

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
