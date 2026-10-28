import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/auth/domain/models/auth_user.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
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

  void _handleAuthChange(AuthSessionChange change) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final path = _router.routeInformationProvider.value.uri.path;
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
        _router.go('/home');
      }
    });
  }
}
