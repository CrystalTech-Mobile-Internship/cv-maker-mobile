import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'routes.dart';
import 'theme.dart';

/// Root application widget
class CvMakerApp extends StatelessWidget {
  CvMakerApp({super.key, required bool startInGuestMode})
      : _router = createAppRouter(startInGuestMode: startInGuestMode);

  final RouterConfig<Object> _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
