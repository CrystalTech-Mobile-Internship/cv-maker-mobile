import 'dart:typed_data';

import 'package:flutter/material.dart';
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
  });

  final Future<Uint8List> pdfBytes;
  final bool isEnglish;
  final VoidCallback onRetry;

  @override
  State<A4PdfPreview> createState() => _A4PdfPreviewState();
}

class _A4PdfPreviewState extends State<A4PdfPreview> {
  late LayoutCallback _buildDocument;

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
      maxPageWidth: 550,
      previewPageMargin: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
