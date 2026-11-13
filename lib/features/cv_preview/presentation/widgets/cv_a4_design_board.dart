import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/cv_section_definition.dart';
import '../../../cv_editor/domain/services/cv_bullet_cleaner.dart';

/// Computer-only layout designer: a palette of CV sections on the left and
/// an A4 sheet in the middle. Sections are dragged onto the sheet, moved
/// between other sections, or dragged back to the palette to leave the CV.
///
/// The result is saved as the CV's section order and hidden sections, so
/// the printed PDF and Word files follow exactly the same layout.
class CvA4DesignBoard extends StatefulWidget {
  const CvA4DesignBoard({
    super.key,
    required this.cv,
    required this.onLayoutChanged,
  });

  final CvModel cv;

  /// Called with the new section order and the sections left off the page.
  final void Function(List<String> order, List<String> hidden) onLayoutChanged;

  @override
  State<CvA4DesignBoard> createState() => _CvA4DesignBoardState();
}

class _CvA4DesignBoardState extends State<CvA4DesignBoard> {
  /// Index of the gap the dragged section would land in (null = none).
  int? _hoverGap;
  bool _hoverPalette = false;

  String get _lang => widget.cv.language;
  List<String> get _onPage => widget.cv.visibleSectionOrder;

  List<String> get _offPage => CvModel.defaultSectionOrder
      .where((id) => !_onPage.contains(id))
      .toList(growable: false);

  void _placeAt(String section, int gap) {
    final page = List<String>.from(_onPage);
    final from = page.indexOf(section);
    var target = gap;
    if (from >= 0) {
      page.removeAt(from);
      if (from < gap) target -= 1;
    }
    page.insert(target.clamp(0, page.length), section);
    _emit(page);
  }

  void _removeFromPage(String section) {
    _emit(_onPage.where((id) => id != section).toList());
  }

  void _emit(List<String> page) {
    // Keep sections that are off the page at the end of the full order so
    // they come back in a sensible place when shown again.
    final order = [
      ...page,
      ...CvModel.defaultSectionOrder.where((id) => !page.contains(id)),
    ];
    final hidden = CvModel.defaultSectionOrder
        .where((id) => !page.contains(id))
        .toList();
    widget.onLayoutChanged(order, hidden);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 280, child: _palette()),
        const VerticalDivider(width: 1),
        Expanded(
          child: Container(
            color: const Color(0xFFEEF2F6),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              child: Center(child: _sheet()),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Palette

  Widget _palette() {
    return DragTarget<String>(
      key: const Key('design-palette'),
      onWillAcceptWithDetails: (details) {
        final accept = _onPage.contains(details.data);
        if (accept) setState(() => _hoverPalette = true);
        return accept;
      },
      onLeave: (_) => setState(() => _hoverPalette = false),
      onAcceptWithDetails: (details) {
        setState(() => _hoverPalette = false);
        _removeFromPage(details.data);
      },
      builder: (context, _, _) => Container(
        color: _hoverPalette ? AppTheme.indigoSurface : Colors.white,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            const Text(
              'Khối nội dung',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kéo khối vào trang A4. Kéo ra đây để gỡ khỏi CV.',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
            ),
            const SizedBox(height: 14),
            if (_offPage.isEmpty)
              _hintBox('Tất cả các khối đang có trên trang.')
            else
              for (final id in _offPage) ...[
                _paletteTile(id),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 14),
            const Text(
              'Trên trang',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primarySlate,
              ),
            ),
            const SizedBox(height: 8),
            for (final id in _onPage) ...[
              _pageListTile(id),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hintBox(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.softBorder),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
    ),
  );

  Widget _paletteTile(String id) {
    final def = CvSectionDefinition.findById(id);
    final tile = _tileBody(
      icon: def?.icon ?? Icons.article_outlined,
      label: def?.title(_lang) ?? id,
      trailing: Icons.drag_indicator_rounded,
    );
    return Draggable<String>(
      key: ValueKey('design-palette-$id'),
      data: id,
      feedback: _dragFeedback(def?.title(_lang) ?? id),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: tile),
    );
  }

  Widget _pageListTile(String id) {
    final def = CvSectionDefinition.findById(id);
    return Row(
      children: [
        Icon(
          def?.icon ?? Icons.article_outlined,
          size: 16,
          color: AppTheme.mutedText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            def?.title(_lang) ?? id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.primarySlate,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tileBody({
    required IconData icon,
    required String label,
    required IconData trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.brandIndigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
              ),
            ),
          ),
          Icon(trailing, size: 18, color: AppTheme.mutedText),
        ],
      ),
    );
  }

  Widget _dragFeedback(String label) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.brandIndigo),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppTheme.brandIndigo,
        ),
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // A4 sheet

  static const double _sheetWidth = 595; // A4 at 72 dpi, like the PDF.
  static const double _pageHeight = _sheetWidth * 1.4142;

  Color get _accent {
    final hex = widget.cv.primaryColor.replaceFirst('#', '');
    final value = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return value == null ? AppTheme.primarySlate : Color(value);
  }

  Widget _sheet() {
    final page = _onPage;
    return Container(
      key: const Key('design-sheet'),
      width: _sheetWidth,
      constraints: const BoxConstraints(minHeight: _pageHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Where a second page would start when printed.
          for (var i = 1; i <= 3; i++)
            Positioned(
              top: _pageHeight * i,
              left: 0,
              right: 0,
              child: _pageBreak(i + 1),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 36, 40, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 10),
                _gap(0),
                for (var i = 0; i < page.length; i++) ...[
                  _block(page[i]),
                  _gap(i + 1),
                ],
                if (page.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: _hintBox('Kéo các khối từ bên trái vào đây.'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBreak(int page) => Row(
    children: [
      Expanded(child: Container(height: 1, color: const Color(0xFFCBD5E1))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'Trang $page',
          style: const TextStyle(fontSize: 10, color: AppTheme.mutedText),
        ),
      ),
      Expanded(child: Container(height: 1, color: const Color(0xFFCBD5E1))),
    ],
  );

  Widget _header() {
    final info = widget.cv.personalInfo;
    final contact = [
      info.address,
      info.phone,
      info.email,
    ].where((v) => v.trim().isNotEmpty).join('  •  ');
    return Column(
      children: [
        Text(
          info.fullName.trim().isEmpty
              ? 'HỌ VÀ TÊN'
              : info.fullName.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _accent,
          ),
        ),
        if (info.targetRole.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            info.targetRole.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.primarySlate,
            ),
          ),
        ],
        if (contact.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            contact,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8.5, color: AppTheme.mutedText),
          ),
        ],
        const SizedBox(height: 8),
        Container(height: 1.5, color: _accent),
      ],
    );
  }

  /// Drop zone between sections; grows into a visible line while hovered.
  Widget _gap(int index) {
    return DragTarget<String>(
      key: ValueKey('design-gap-$index'),
      onWillAcceptWithDetails: (_) {
        setState(() => _hoverGap = index);
        return true;
      },
      onLeave: (_) {
        if (_hoverGap == index) setState(() => _hoverGap = null);
      },
      onAcceptWithDetails: (details) {
        setState(() => _hoverGap = null);
        _placeAt(details.data, index);
      },
      builder: (context, candidates, _) {
        final active = _hoverGap == index && candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: active ? 26 : 12,
          alignment: Alignment.center,
          child: active
              ? Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.brandIndigo,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _block(String id) {
    final def = CvSectionDefinition.findById(id);
    final title = (def?.title(_lang) ?? id).toUpperCase();
    final body = _BlockShell(
      title: title,
      accent: _accent,
      onRemove: () => _removeFromPage(id),
      child: _content(id),
    );
    return Draggable<String>(
      key: ValueKey('design-block-$id'),
      data: id,
      feedback: _dragFeedback(def?.title(_lang) ?? id),
      childWhenDragging: Opacity(opacity: 0.3, child: body),
      child: MouseRegion(cursor: SystemMouseCursors.grab, child: body),
    );
  }

  // ---------------------------------------------------------------------------
  // Section content (a faithful but compact version of the printed text)

  static const _text = TextStyle(
    fontSize: 9,
    height: 1.45,
    color: Color(0xFF1F2937),
  );
  static const _bold = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w800,
    color: Color(0xFF0F172A),
  );
  static const _muted = TextStyle(fontSize: 8.5, color: AppTheme.mutedText);

  String _date(DateTime? d) =>
      d == null ? '' : '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _range(DateTime? start, DateTime? end, {bool current = false}) {
    final from = _date(start);
    final to = current ? (_lang == 'en' ? 'Present' : 'Hiện tại') : _date(end);
    if (from.isEmpty && to.isEmpty) return '';
    return [from, to].where((v) => v.isNotEmpty).join(' - ');
  }

  Widget _empty() => Text(
    _lang == 'en'
        ? 'No content yet — add it in the editor.'
        : 'Chưa có nội dung — thêm trong phần Chỉnh sửa.',
    style: _muted.copyWith(fontStyle: FontStyle.italic),
  );

  Widget _entry({
    required String heading,
    String sub = '',
    String period = '',
    List<String> lines = const [],
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(heading, style: _bold)),
              if (period.isNotEmpty) Text(period, style: _muted),
            ],
          ),
          if (sub.isNotEmpty) Text(sub, style: _muted),
          for (final line in lines.take(3))
            Text('•  ${CvBulletCleaner.line(line)}', style: _text),
          if (lines.length > 3)
            Text('+ ${lines.length - 3} dòng nữa', style: _muted),
        ],
      ),
    );
  }

  Widget _content(String id) {
    final cv = widget.cv;
    switch (id) {
      case 'summary':
        return cv.summary.trim().isEmpty
            ? _empty()
            : Text(
                cv.summary,
                style: _text,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              );
      case 'experience':
        if (cv.experiences.isEmpty) return _empty();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in cv.experiences)
              _entry(
                heading: e.company.toUpperCase(),
                sub: [
                  e.jobTitle,
                  e.location,
                ].where((v) => v.trim().isNotEmpty).join(' • '),
                period: _range(e.startDate, e.endDate, current: e.isCurrent),
                lines: e.bulletPoints,
              ),
          ],
        );
      case 'projects':
        if (cv.projects.isEmpty) return _empty();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in cv.projects)
              _entry(
                heading: p.name,
                sub: [
                  p.role,
                  p.technologies.join(', '),
                ].where((v) => v.trim().isNotEmpty).join(' | '),
                period: _range(
                  p.startDate,
                  p.endDate,
                  current: p.startDate != null && p.endDate == null,
                ),
                lines: p.description
                    .split('\n')
                    .where((l) => l.trim().isNotEmpty)
                    .toList(),
              ),
          ],
        );
      case 'education':
        if (cv.educations.isEmpty) return _empty();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in cv.educations)
              _entry(
                heading: e.institution.toUpperCase(),
                sub: [
                  e.degree,
                  e.fieldOfStudy,
                  if ((e.gpa ?? '').isNotEmpty) 'GPA: ${e.gpa}',
                ].where((v) => v.trim().isNotEmpty).join(' — '),
                period: _range(e.startDate, e.endDate, current: e.isCurrent),
                lines: e.achievements,
              ),
          ],
        );
      case 'skills':
        if (cv.skills.isEmpty) return _empty();
        return Text(cv.skills.map((s) => s.name).join(', '), style: _text);
      case 'certifications':
        if (cv.certifications.isEmpty) return _empty();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in cv.certifications)
              Text(
                '•  ${[c.name, if ((c.score ?? '').isNotEmpty) c.score!, c.issuer].where((v) => v.trim().isNotEmpty).join(' — ')}',
                style: _text,
              ),
          ],
        );
    }
    return _empty();
  }
}

/// A section on the sheet: title rule, hover outline and a remove button.
class _BlockShell extends StatefulWidget {
  const _BlockShell({
    required this.title,
    required this.accent,
    required this.onRemove,
    required this.child,
  });

  final String title;
  final Color accent;
  final VoidCallback onRemove;
  final Widget child;

  @override
  State<_BlockShell> createState() => _BlockShellState();
}

class _BlockShellState extends State<_BlockShell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFFF8FAFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _hover ? AppTheme.brandIndigo : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (_hover)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 14,
                      color: AppTheme.brandIndigo,
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: widget.accent,
                    ),
                  ),
                ),
                if (_hover)
                  InkWell(
                    onTap: widget.onRemove,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Tooltip(
                        message: 'Gỡ khỏi trang',
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Container(height: 0.8, color: widget.accent.withValues(alpha: 0.5)),
            const SizedBox(height: 5),
            widget.child,
          ],
        ),
      ),
    );
  }
}
