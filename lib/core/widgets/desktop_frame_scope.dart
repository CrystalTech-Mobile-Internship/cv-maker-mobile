import 'package:flutter/widgets.dart';

/// Marks a page shown inside the computer sidebar layout. Such pages need
/// no back button: the sidebar is always there.
class DesktopFrameScope extends InheritedWidget {
  const DesktopFrameScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopFrameScope>() != null;

  @override
  bool updateShouldNotify(DesktopFrameScope oldWidget) => false;
}
