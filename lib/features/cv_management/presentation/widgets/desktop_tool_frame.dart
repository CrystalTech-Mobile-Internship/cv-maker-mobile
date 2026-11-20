import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/app_language.dart';
import '../../../../core/widgets/desktop_frame_scope.dart';
import '../../../admin/presentation/admin_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'desktop_shell.dart';
import 'desktop_tools.dart';

/// On computers, shows a tool page inside the sidebar layout, like the
/// main sections. Phones get the page on its own, as before.
class DesktopToolFrame extends ConsumerWidget {
  const DesktopToolFrame({super.key, required this.route, required this.child});

  /// Route of this tool, highlighted in the sidebar.
  final String route;
  final Widget child;

  static const minWidth = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MediaQuery.sizeOf(context).width < minWidth) return child;
    final user = ref.watch(currentAuthUserProvider);
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: DesktopShell(
        items: desktopDestinations,
        selectedIndex: -1,
        onSelect: (index) => context.go('/home?tab=$index'),
        onCreate: () => context.go('/home?create=1'),
        title: '',
        showHeader: false,
        accountName: user?.displayName.isNotEmpty == true
            ? user!.displayName
            : user?.email,
        accountDetail: user == null
            ? tr('Đăng nhập để sao lưu CV', 'Sign in to back up CVs')
            : user.email,
        onAccount: () => context.go('/home?tab=3'),
        tools: desktopToolLinks(
          context,
          isAdmin: isAdmin,
          adminWaiting: isAdmin
              ? ref.watch(adminStatsProvider).valueOrNull?.waitingThreads ?? 0
              : 0,
          current: route,
        ),
        child: DesktopFrameScope(child: child),
      ),
    );
  }
}

/// Page for a route that shows the computer sidebar. The sidebar must stay
/// still between these pages, so on computers the page draws no animation
/// at all and only the content area fades in (see `DesktopShell`). The
/// width is read while animating, so resizing the window is handled too.
/// Phones keep the usual page animation.
Page<void> sidebarPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (MediaQuery.sizeOf(context).width >= DesktopToolFrame.minWidth) {
      return child;
    }
    return Theme.of(context).pageTransitionsTheme.buildTransitions(
      ModalRoute.of(context)! as PageRoute<void>,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  },
);
