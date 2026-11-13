import 'package:flutter/material.dart';

/// A compact editor tab for narrow mobile screens.
///
/// Every tab keeps the same width. Only the selected tab renders its label;
/// inactive tabs render an icon so six sections fit without horizontal scroll.
class AdaptiveEditorTab extends StatelessWidget {
  const AdaptiveEditorTab({
    super.key,
    required this.controller,
    required this.index,
    required this.icon,
    required this.label,
    this.showLabel = false,
  });

  /// Computers have room for every label next to its icon.
  final bool showLabel;

  final TabController controller;
  final int index;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return Tab(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final isSelected = controller.index == index;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    return Tab(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final isSelected = controller.index == index;
          return Semantics(
            label: label,
            selected: isSelected,
            button: true,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isSelected
                  ? Padding(
                      key: ValueKey('editor-tab-label-$index'),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      key: ValueKey('editor-tab-icon-$index'),
                      size: 23,
                    ),
            ),
          );
        },
      ),
    );
  }
}
