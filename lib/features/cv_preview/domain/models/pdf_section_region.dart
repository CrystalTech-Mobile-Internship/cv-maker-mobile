/// Where one CV section was drawn on a page of the generated PDF.
///
/// Values are PDF points measured from the top-left corner of the page, so
/// the preview can scale them onto the page image and let users click a
/// section directly on the A4 sheet.
class PdfSectionRegion {
  const PdfSectionRegion({
    required this.section,
    required this.page,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Section id such as `experience` or `skills`.
  final String section;

  /// Zero-based page index.
  final int page;
  final double left;
  final double top;
  final double width;
  final double height;

  /// A4 size in PDF points.
  static const pageWidth = 595.28;
  static const pageHeight = 841.89;

  @override
  String toString() =>
      'PdfSectionRegion($section, page $page, top $top, height $height)';
}
