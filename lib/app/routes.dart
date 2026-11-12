import 'package:go_router/go_router.dart';

import '../core/constants/auth_callback_constants.dart';
import '../features/auth/presentation/screens/account_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/auth_redirect.dart';
import '../features/ai_tools/presentation/screens/ai_interview_screen.dart';
import '../features/ai_tools/presentation/screens/ats_scorer_screen.dart';
import '../features/billing/presentation/screens/pro_upgrade_screen.dart';
import '../features/cv_management/presentation/screens/home_screen.dart';
import '../features/cv_editor/presentation/screens/cv_editor_screen.dart';
import '../features/cv_editor/domain/models/cv_model.dart';
import '../features/cv_preview/presentation/screens/cv_preview_screen.dart';

String? redirectForAppUri(Uri uri) {
  if (AuthCallbackConstants.isMobileCallback(uri) || uri.path == '/') {
    return '/home';
  }
  return null;
}

/// Application Declarative Routing Configuration
GoRouter createAppRouter({
  required bool startInGuestMode,
  required bool startAuthenticated,
}) => GoRouter(
  initialLocation: startInGuestMode || startAuthenticated ? '/home' : '/login',
  redirect: (context, state) => redirectForAppUri(state.uri),
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => LoginScreen(
        redirectPath: safeAuthRedirect(state.uri.queryParameters['redirect']),
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => RegisterScreen(
        redirectPath: safeAuthRedirect(state.uri.queryParameters['redirect']),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      name: 'reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/editor',
      name: 'editor',
      builder: (context, state) => CvEditorScreen(
        initialCv: state.extra is CvModel ? state.extra as CvModel : null,
      ),
    ),
    GoRoute(
      path: '/preview',
      name: 'preview',
      builder: (context, state) => CvPreviewScreen(
        cv: state.extra is CvModel ? state.extra as CvModel : null,
      ),
    ),
    GoRoute(
      path: '/ats-scorer',
      name: 'ats-scorer',
      builder: (context, state) => const AtsScorerScreen(),
    ),
    GoRoute(
      path: '/ai-interview',
      name: 'ai-interview',
      builder: (context, state) => const AiInterviewScreen(),
    ),
    GoRoute(
      path: '/upgrade-pro',
      name: 'upgrade-pro',
      builder: (context, state) => const ProUpgradeScreen(),
    ),
  ],
);
