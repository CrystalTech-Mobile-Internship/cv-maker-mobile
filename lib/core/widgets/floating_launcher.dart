import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Rounded floating button for the bottom-right corner.
///
/// It lifts slightly on hover, presses in on tap and, on wide screens,
/// shows its label so people know what it does before clicking.
class FloatingLauncher extends StatefulWidget {
  const FloatingLauncher({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.showLabel,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  /// Filled indigo when true; white with an indigo outline otherwise.
  final bool primary;

  /// Forces the label on or off; by default it shows on wide screens.
  final bool? showLabel;

  @override
  State<FloatingLauncher> createState() => _FloatingLauncherState();
}

class _FloatingLauncherState extends State<FloatingLauncher> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final showLabel = widget.showLabel ?? wide;
    final background = widget.primary ? AppTheme.brandIndigo : Colors.white;
    final foreground = widget.primary ? Colors.white : AppTheme.brandIndigo;
    final hoverBackground = widget.primary
        ? const Color(0xFF3730A3)
        : AppTheme.indigoSurface;
    final lifted = _hovered && !_pressed;

    final button = Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : (lifted ? 1.04 : 1),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 52,
              padding: EdgeInsets.symmetric(horizontal: showLabel ? 18 : 14),
              decoration: BoxDecoration(
                color: _hovered ? hoverBackground : background,
                borderRadius: BorderRadius.circular(26),
                border: widget.primary
                    ? null
                    : Border.all(
                        color: AppTheme.brandIndigo.withValues(alpha: 0.35),
                        width: 1.4,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandIndigo.withValues(
                      alpha: lifted ? 0.32 : 0.18,
                    ),
                    blurRadius: lifted ? 22 : 12,
                    offset: Offset(0, lifted ? 8 : 4),
                  ),
                ],
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: foreground, size: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.icon,
                    if (showLabel) ...[
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return showLabel ? button : Tooltip(message: widget.label, child: button);
  }
}
