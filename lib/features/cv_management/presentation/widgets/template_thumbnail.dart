import 'package:flutter/material.dart';

import '../../../cv_editor/domain/models/cv_template.dart';

/// Lightweight, code-rendered A4 thumbnail. It avoids shipping large preview
/// images while still showing the layout users will get from each template.
class TemplateThumbnail extends StatelessWidget {
  const TemplateThumbnail({
    super.key,
    required this.template,
    this.borderRadius = 10,
  });

  final CvTemplate template;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final accent = _hexColor(template.accentHex);
    return AspectRatio(
      aspectRatio: 210 / 297,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 1),
          // Compose every preview on the same small A4 canvas, then scale the
          // canvas as one unit. The thumbnail is also reused in compact CV
          // cards, where laying out the internal rows at their natural size
          // would otherwise overflow.
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: 140,
              height: 198,
              child: switch (template.layout) {
                CvTemplateLayout.sidebar => _SidebarPreview(accent: accent),
                CvTemplateLayout.creative => _CreativePreview(accent: accent),
                CvTemplateLayout.cleanPhoto ||
                CvTemplateLayout.freshPhoto => _PhotoPreview(
                  accent: accent,
                  fresh: template.layout == CvTemplateLayout.freshPhoto,
                ),
                CvTemplateLayout.executive => _ExecutivePreview(accent: accent),
                CvTemplateLayout.academic => _AcademicPreview(accent: accent),
                CvTemplateLayout.classic ||
                CvTemplateLayout.modern => _ClassicPreview(
                  accent: accent,
                  centered: template.layout == CvTemplateLayout.classic,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassicPreview extends StatelessWidget {
  const _ClassicPreview({required this.accent, required this.centered});

  final Color accent;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          _MiniLine(width: centered ? 72 : 84, height: 7, color: accent),
          const SizedBox(height: 4),
          const _MiniLine(width: 58, height: 3),
          const SizedBox(height: 7),
          Divider(height: 1, thickness: 1, color: accent),
          const SizedBox(height: 8),
          ..._sections(accent, count: 4),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.accent, required this.fresh});

  final Color accent;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 49,
          padding: const EdgeInsets.all(8),
          color: accent.withValues(alpha: fresh ? 0.16 : 0.09),
          child: Row(
            children: [
              _AvatarDot(color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniLine(width: 64, height: 6, color: accent),
                    const SizedBox(height: 4),
                    const _MiniLine(width: 44, height: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(children: _sections(accent, count: 3)),
          ),
        ),
      ],
    );
  }
}

class _CreativePreview extends StatelessWidget {
  const _CreativePreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.68)],
            ),
          ),
          child: Row(
            children: [
              const _AvatarDot(color: Colors.white),
              const SizedBox(width: 7),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniLine(width: 66, height: 6, color: Colors.white),
                  SizedBox(height: 4),
                  _MiniLine(width: 46, height: 3, color: Color(0xCCFFFFFF)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(children: _sections(accent, count: 3)),
          ),
        ),
      ],
    );
  }
}

class _SidebarPreview extends StatelessWidget {
  const _SidebarPreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
          color: accent.withValues(alpha: 0.16),
          child: Column(
            children: [
              _AvatarDot(color: accent),
              const SizedBox(height: 10),
              ...List.generate(
                6,
                (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: _MiniLine(width: 28, height: 3),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniLine(width: 66, height: 7, color: accent),
                const SizedBox(height: 4),
                const _MiniLine(width: 46, height: 3),
                const SizedBox(height: 8),
                ..._sections(accent, count: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExecutivePreview extends StatelessWidget {
  const _ExecutivePreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _MiniLine(width: 76, height: 8, color: accent)),
              Container(width: 18, height: 3, color: accent),
            ],
          ),
          const SizedBox(height: 5),
          const _MiniLine(width: 60, height: 3),
          const SizedBox(height: 8),
          Container(height: 2, color: accent),
          const SizedBox(height: 8),
          ..._sections(accent, count: 4),
        ],
      ),
    );
  }
}

class _AcademicPreview extends StatelessWidget {
  const _AcademicPreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _MiniLine(width: 76, height: 7, color: accent),
          const SizedBox(height: 4),
          const _MiniLine(width: 54, height: 3),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(child: Divider(color: accent, thickness: 1)),
              const SizedBox(width: 5),
              Icon(Icons.school_rounded, size: 10, color: accent),
              const SizedBox(width: 5),
              Expanded(child: Divider(color: accent, thickness: 1)),
            ],
          ),
          const SizedBox(height: 7),
          ..._sections(accent, count: 4),
        ],
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: color == Colors.white ? 0.22 : 0.18),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Icon(Icons.person_rounded, size: 18, color: color),
    );
  }
}

class _MiniLine extends StatelessWidget {
  const _MiniLine({
    required this.width,
    required this.height,
    this.color = const Color(0xFFCBD5E1),
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

List<Widget> _sections(Color accent, {required int count}) {
  return List.generate(
    count,
    (index) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniLine(width: 44 + index * 4, height: 4, color: accent),
          const SizedBox(height: 4),
          const _MiniLine(width: double.infinity, height: 2.5),
          const SizedBox(height: 3),
          const _MiniLine(width: 82, height: 2.5),
        ],
      ),
    ),
  );
}

Color _hexColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  return Color(int.parse('FF$normalized', radix: 16));
}
