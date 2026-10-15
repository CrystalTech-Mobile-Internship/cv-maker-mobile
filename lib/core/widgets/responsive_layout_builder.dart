import 'package:flutter/material.dart';

/// Standard breakpoint definitions for multiplatform adaptive layouts.
class Breakpoints {
  const Breakpoints._();

  /// Below 600dp: Compact phone screens (e.g. Samsung A11, Pixel 5).
  static const double mobile = 600;

  /// 600dp to 899dp: Tablets / Foldables in portrait.
  static const double tablet = 900;

  /// 900dp and above: Desktop, Web wide screen, Tablets in landscape.
  /// Activates Web Split-Screen layout per design specification.
  static const double desktop = 900;
}

/// A responsive builder widget that adapts between Mobile, Tablet, and Desktop/Web layouts.
class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Widget displayed on mobile screens (< 600dp or < 900dp if tablet/desktop not provided).
  final Widget Function(BuildContext context, BoxConstraints constraints)
  mobile;

  /// Optional widget displayed on tablet screens (600dp <= width < 900dp).
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  tablet;

  /// Widget displayed on desktop / wide web browsers (width >= 900dp).
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  desktop;

  /// Check whether the current screen context is Desktop/Web wide layout.
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  /// Check whether the current screen context is Tablet layout.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }

  /// Check whether the current screen context is Mobile layout.
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.desktop && desktop != null) {
          return desktop!(context, constraints);
        }

        if (constraints.maxWidth >= Breakpoints.mobile && tablet != null) {
          return tablet!(context, constraints);
        }

        return mobile(context, constraints);
      },
    );
  }
}

/// Utility wrapper that constrains web/desktop content to a maximum width
/// and centers it horizontally for a premium aesthetic on wide displays.
class WebConstrainedWidth extends StatelessWidget {
  const WebConstrainedWidth({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
