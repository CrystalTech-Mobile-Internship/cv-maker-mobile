import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/domain/models/auth_user.dart';
import '../features/auth/presentation/auth_redirect.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/cv_editor/data/services/linked_account_cv_adopter.dart';
import '../features/cv_management/presentation/controllers/dashboard_sync_controller.dart';
import 'routes.dart';
import 'theme.dart';

/// Root application widget
class CvMakerApp extends ConsumerStatefulWidget {
  const CvMakerApp({
    super.key,
    required this.startInGuestMode,
    this.startAuthenticated = false,
  });

  final bool startInGuestMode;
  final bool startAuthenticated;

  @override
  ConsumerState<CvMakerApp> createState() => _CvMakerAppState();
}

class _CvMakerAppState extends ConsumerState<CvMakerApp> {
  late final _router = createAppRouter(
    startInGuestMode: widget.startInGuestMode,
    startAuthenticated: widget.startAuthenticated,
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSessionChange>>(authSessionChangesProvider, (
      previous,
      next,
    ) {
      next.whenData((change) {
        unawaited(_persistAuthenticatedSession(change));
        unawaited(_adoptThenSync(change));
        _handleAuthChange(change);
      });
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }

  Future<void> _persistAuthenticatedSession(AuthSessionChange change) async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .handleSessionChange(change);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'authentication',
          context: ErrorDescription('while persisting authenticated session'),
        ),
      );
    }
  }

  /// Links CVs from the user's other account id, then backs everything up
  /// silently. Sync keeps the newer copy and never deletes local data.
  Future<void> _adoptThenSync(AuthSessionChange change) async {
    await _adoptLinkedAccountCvs(change);
    final user = change.user;
    final relevant =
        change.event == AuthSessionEvent.signedIn ||
        change.event == AuthSessionEvent.initial;
    if (!relevant || user == null) return;
    try {
      await ref
          .read(dashboardSyncControllerProvider.notifier)
          .synchronize(user.id);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'sync',
          context: ErrorDescription('while syncing after sign-in'),
        ),
      );
    }
  }

  /// Keeps CVs created with the same email on the other Supabase project
  /// visible after a project switch.
  Future<void> _adoptLinkedAccountCvs(AuthSessionChange change) async {
    final user = change.user;
    final relevant =
        change.event == AuthSessionEvent.signedIn ||
        change.event == AuthSessionEvent.initial;
    if (!relevant || user == null || user.email.isEmpty) return;
    try {
      await ref
          .read(linkedAccountCvAdopterProvider)
          .adopt(userId: user.id, email: user.email);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'authentication',
          context: ErrorDescription('while linking CVs from another project'),
        ),
      );
    }
  }

  void _handleAuthChange(AuthSessionChange change) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uri = _router.routeInformationProvider.value.uri;
      final path = uri.path;
      final redirectPath = safeAuthRedirect(uri.queryParameters['redirect']);
      if (change.event == AuthSessionEvent.passwordRecovery) {
        _router.go('/reset-password');
        return;
      }
      if (change.event == AuthSessionEvent.signedOut &&
          path != '/login' &&
          path != '/forgot-password') {
        _router.go('/login');
        return;
      }
      final isAuthEntry =
          path == '/login' || path == '/register' || path == '/forgot-password';
      if ((change.event == AuthSessionEvent.signedIn ||
              change.event == AuthSessionEvent.initial) &&
          change.user != null &&
          isAuthEntry) {
        _router.go(redirectPath ?? '/home');
      }
    });
  }
}
