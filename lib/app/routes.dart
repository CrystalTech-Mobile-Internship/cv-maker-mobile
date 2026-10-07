import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/cv_management/presentation/screens/home_screen.dart';
import '../features/cv_editor/presentation/screens/cv_editor_screen.dart';
import '../features/cv_editor/domain/models/cv_model.dart';
import '../features/cv_preview/presentation/screens/cv_preview_screen.dart';

/// Application Declarative Routing Configuration
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
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
      builder: (context, state) => const CvPreviewScreen(),
    ),
  ],
);
