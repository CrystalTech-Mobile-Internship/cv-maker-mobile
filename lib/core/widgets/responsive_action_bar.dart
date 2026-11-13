import 'package:flutter/material.dart';

/// Bottom action buttons: full-width halves on phones, compact buttons
/// aligned to the right on computers.
class ResponsiveActionBar extends StatelessWidget {
  const ResponsiveActionBar({
    super.key,
    required this.children,
    this.wideButtonWidth = 240,
  });

  final List<Widget> children;
  final double wideButtonWidth;

  static const double wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        final items = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0) items.add(const SizedBox(width: 12));
          items.add(
            wide
                ? SizedBox(width: wideButtonWidth, child: children[i])
                : Expanded(child: children[i]),
          );
        }
        return Row(
          mainAxisAlignment: wide
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: items,
        );
      },
    );
  }
}
