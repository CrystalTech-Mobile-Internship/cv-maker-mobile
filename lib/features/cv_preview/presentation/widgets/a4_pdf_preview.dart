import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../app/theme.dart';

/// Displays the exact PDF bytes that are later saved/shared by the app.
///
/// Using [PdfPreview] keeps the on-screen paper size, whitespace and page
/// breaks identical to the exported A4 document instead of approximating them
/// with a second Flutter layout.
class A4PdfPreview extends StatefulWidget {
  const A4PdfPreview({
    super.key,
    required this.pdfBytes,
    required this.isEnglish,
    required this.onRetry,
    this.fitPage = false,
  });

  final Future<Uint8List> pdfBytes;
  final bool isEnglish;
  final VoidCallback onRetry;

  /// Size the sheet so a whole A4 page fits the available height at 100%.
  /// Ctrl + mouse wheel (or the zoom buttons) changes the size from there.
  final bool fitPage;

  static const minZoom = 0.5;
  static const maxZoom = 3.0;

  @override
  State<A4PdfPreview> createState() => _A4PdfPreviewState();
}

class _A4PdfPreviewState extends State<A4PdfPreview> {
  late LayoutCallback _buildDocument;
  double _zoom = 1;

  static const _margin = EdgeInsets.fromLTRB(16, 12, 16, 20);

  void _setZoom(double value) {
    final next = value.clamp(A4PdfPreview.minZoom, A4PdfPreview.maxZoom);
    if ((next - _zoom).abs() < 0.001) return;
    setState(() => _zoom = next.toDouble());
  }

  void _onPointerSignal(PointerSignalEvent event) {
    // Web turns Ctrl + wheel into a scale event; desktop apps send a scroll
    // event while Ctrl is held.
    if (event is PointerScaleEvent) {
      GestureBinding.instance.pointerSignalResolver.register(
        event,
        (event) => _setZoom(
          _zoom * (event as PointerScaleEvent).scale.clamp(0.9, 1.1),
        ),
      );
    } else if (event is PointerScrollEvent &&
        HardwareKeyboard.instance.isControlPressed) {
      GestureBinding.instance.pointerSignalResolver.register(event, (event) {
        final dy = (event as PointerScrollEvent).scrollDelta.dy;
        _setZoom(_zoom * (dy > 0 ? 0.9 : 1.1));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _bindDocumentBuilder();
  }

  @override
  void didUpdateWidget(covariant A4PdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pdfBytes, widget.pdfBytes)) {
      _bindDocumentBuilder();
    }
  }

  void _bindDocumentBuilder() {
    final currentPdf = widget.pdfBytes;
    _buildDocument = (_) => currentPdf;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 100% = the whole first page visible without scrolling.
        final fitWidth = widget.fitPage
            ? ((constraints.maxHeight - _margin.vertical) /
                      PdfPageFormat.a4.height *
                      PdfPageFormat.a4.width)
                  .clamp(200.0, constraints.maxWidth - _margin.horizontal)
            : 550.0;
        final pageWidth = (fitWidth * _zoom).toDouble();
        return Listener(
          onPointerSignal: _onPointerSignal,
          child: Stack(
            children: [
              Positioned.fill(child: _preview(context, pageWidth)),
              Positioned(
                right: 12,
                bottom: 12,
                child: _ZoomControls(
                  zoom: _zoom,
                  isEnglish: widget.isEnglish,
                  onZoom: _setZoom,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _preview(BuildContext context, double pageWidth) {
    final isEnglish = widget.isEnglish;

    return PdfPreview(
      build: _buildDocument,
      initialPageFormat: PdfPageFormat.a4,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: false,
      allowSharing: false,
      useActions: false,
      dynamicLayout: false,
      maxPageWidth: pageWidth,
      previewPageMargin: _margin,
      padding: EdgeInsets.zero,
      scrollViewDecoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
      pdfPreviewPageDecoration: BoxDecoration(
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
      loadingWidget: const Center(child: CircularProgressIndicator()),
      onError: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 48,
                color: AppTheme.primarySlate,
              ),
              const SizedBox(height: 12),
              Text(
                isEnglish
                    ? 'The A4 preview could not be generated.'
                    : 'Không thể tạo bản xem trước A4.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isEnglish ? 'Try again' : 'Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.zoom,
    required this.isEnglish,
    required this.onZoom,
  });

  final double zoom;
  final bool isEnglish;
  final ValueChanged<double> onZoom;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('a4-zoom-out'),
              tooltip: isEnglish
                  ? 'Zoom out (Ctrl + wheel)'
                  : 'Thu nhỏ (Ctrl + cuộn chuột)',
              visualDensity: VisualDensity.compact,
              onPressed: zoom > A4PdfPreview.minZoom
                  ? () => onZoom(zoom - 0.1)
                  : null,
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            Tooltip(
              message: isEnglish ? 'Fit page' : 'Vừa trang',
              child: InkWell(
                key: const Key('a4-zoom-reset'),
                onTap: () => onZoom(1),
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 48,
                  child: Text(
                    '${(zoom * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              key: const Key('a4-zoom-in'),
              tooltip: isEnglish
                  ? 'Zoom in (Ctrl + wheel)'
                  : 'Phóng to (Ctrl + cuộn chuột)',
              visualDensity: VisualDensity.compact,
              onPressed: zoom < A4PdfPreview.maxZoom
                  ? () => onZoom(zoom + 0.1)
                  : null,
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
