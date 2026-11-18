import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme.dart';
import '../../domain/models/pdf_section_region.dart';

/// Shows the PDF pages as images with a clickable box over each section,
/// so users can pick a section straight from the A4 sheet.
class ClickablePdfPages extends StatefulWidget {
  const ClickablePdfPages({
    super.key,
    required this.pdfBytes,
    required this.pageWidth,
    required this.margin,
    required this.regions,
    required this.selectedSection,
    required this.onSectionTap,
    required this.isEnglish,
    required this.errorBuilder,
  });

  final Future<Uint8List> pdfBytes;
  final double pageWidth;
  final EdgeInsets margin;
  final List<PdfSectionRegion> regions;
  final String? selectedSection;
  final ValueChanged<String> onSectionTap;
  final bool isEnglish;
  final Widget Function(BuildContext context, Object error) errorBuilder;

  @override
  State<ClickablePdfPages> createState() => _ClickablePdfPagesState();
}

class _ClickablePdfPagesState extends State<ClickablePdfPages> {
  List<ui.Image> _pages = const [];
  Object? _error;
  bool _loading = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClickablePdfPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pdfBytes, widget.pdfBytes)) _load();
  }

  @override
  void dispose() {
    _generation++;
    for (final page in _pages) {
      page.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await widget.pdfBytes;
      final images = <ui.Image>[];
      // 144 dpi stays sharp up to about twice the fitted size.
      await for (final raster in Printing.raster(bytes, dpi: 144)) {
        images.add(await raster.toImage());
      }
      if (!mounted || generation != _generation) {
        for (final image in images) {
          image.dispose();
        }
        return;
      }
      final old = _pages;
      setState(() {
        _pages = images;
        _loading = false;
      });
      // Free the previous images once the new frame no longer uses them.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final image in old) {
          image.dispose();
        }
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return widget.errorBuilder(context, _error!);
    if (_pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final width = widget.pageWidth;
    final scale = width / PdfSectionRegion.pageWidth;
    final height = PdfSectionRegion.pageHeight * scale;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < _pages.length; index++)
          Padding(
            padding: widget.margin,
            child: Container(
              key: ValueKey('a4-page-$index'),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RawImage(
                      image: _pages[index],
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  for (final region in widget.regions)
                    if (region.page == index)
                      Positioned(
                        left: (region.left - 6) * scale,
                        top: (region.top - 3) * scale,
                        width: (region.width + 12) * scale,
                        height: (region.height + 3) * scale,
                        child: _SectionHitBox(
                          key: ValueKey(
                            'a4-section-${region.section}-${region.page}',
                          ),
                          selected: widget.selectedSection == region.section,
                          isEnglish: widget.isEnglish,
                          onTap: () => widget.onSectionTap(region.section),
                        ),
                      ),
                  if (_loading)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );

    return ColoredBox(
      color: const Color(0xFFF1F5F9),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(child: column),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHitBox extends StatefulWidget {
  const _SectionHitBox({
    super.key,
    required this.selected,
    required this.isEnglish,
    required this.onTap,
  });

  final bool selected;
  final bool isEnglish;
  final VoidCallback onTap;

  @override
  State<_SectionHitBox> createState() => _SectionHitBoxState();
}

class _SectionHitBoxState extends State<_SectionHitBox> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hover;
    return Tooltip(
      message: widget.selected
          ? ''
          : (widget.isEnglish ? 'Click to select' : 'Bấm để chọn mục này'),
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppTheme.brandIndigo.withValues(alpha: 0.07)
                  : (_hover
                        ? AppTheme.brandIndigo.withValues(alpha: 0.04)
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: active
                    ? AppTheme.brandIndigo.withValues(
                        alpha: widget.selected ? 0.9 : 0.4,
                      )
                    : Colors.transparent,
                width: widget.selected ? 1.5 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
