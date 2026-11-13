import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../app/theme.dart';

/// Modal dialog that prompts the user to enter/confirm the PDF export file name
/// before generating and saving/sharing the vector PDF document.
class ExportPdfDialog extends StatefulWidget {
  const ExportPdfDialog({
    super.key,
    required this.initialFileName,
    required this.isEnglish,
    this.fontSizeScale = 1.0,
    required this.onConfirm,
  });

  final String initialFileName;
  final bool isEnglish;
  final double fontSizeScale;
  final ValueChanged<String> onConfirm;

  /// Static helper to display the dialog
  static Future<String?> show({
    required BuildContext context,
    required String initialFileName,
    required bool isEnglish,
    double fontSizeScale = 1.0,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ExportPdfDialog(
        initialFileName: initialFileName,
        isEnglish: isEnglish,
        fontSizeScale: fontSizeScale,
        onConfirm: (name) => Navigator.of(ctx).pop(name),
      ),
    );
  }

  @override
  State<ExportPdfDialog> createState() => _ExportPdfDialogState();
}

class _ExportPdfDialogState extends State<ExportPdfDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  String _format = 'pdf'; // 'pdf' or 'docx'

  @override
  void initState() {
    super.initState();
    var name = widget.initialFileName.trim();
    if (name.toLowerCase().endsWith('.pdf')) {
      name = name.substring(0, name.length - 4);
    } else if (name.toLowerCase().endsWith('.docx')) {
      name = name.substring(0, name.length - 5);
      _format = 'docx';
    }
    _controller = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorText = widget.isEnglish
            ? 'File name cannot be empty'
            : 'Vui lòng nhập tên tệp';
      });
      return;
    }

    final sanitized = text.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final finalFileName = '$sanitized.$_format';
    widget.onConfirm(finalFileName);
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.isEnglish;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.indigoSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    color: AppTheme.brandIndigo,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? 'Download CV' : 'Tải CV về máy',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primarySlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEn
                            ? 'Sharp print quality • Text size: ${widget.fontSizeScale.toStringAsFixed(2)}x'
                            : 'Cỡ chữ ${(widget.fontSizeScale * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Format Selector (PDF vs Word DOCX)
            SegmentedButton<String>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.indigoSurface,
                selectedForegroundColor: AppTheme.brandIndigo,
              ),
              segments: [
                ButtonSegment(
                  value: 'pdf',
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('PDF (A4)'),
                ),
                ButtonSegment(
                  value: 'docx',
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Word (.docx)'),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (set) {
                setState(() => _format = set.first);
              },
            ),
            const SizedBox(height: 14),

            // Form Input Field for Filename
            Text(
              isEn ? 'File name:' : 'Tên tệp:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primarySlate,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: isEn ? 'e.g. My_Resume' : 'Ví dụ: CV_Nguyen_Tuan_Anh',
                errorText: _errorText,
                suffixIcon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  alignment: Alignment.centerRight,
                  width: 52,
                  child: Text(
                    '.$_format',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppTheme.primarySlate,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 14),

            // Storage & Destination Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: AppTheme.mutedText,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      kIsWeb
                          ? (isEn
                                ? 'The CV is saved in this browser first. The PDF will be downloaded through the browser.'
                                : 'Tệp sẽ được tải về máy qua trình duyệt.')
                          : (isEn
                                ? 'The CV and PDF are saved on this device first. Sharing to Drive, email, or messaging apps is optional and may require Internet.'
                                : 'CV và PDF luôn được lưu trên thiết bị trước. Chia sẻ qua Drive, email hoặc ứng dụng nhắn tin là tùy chọn và có thể cần Internet.'),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      isEn ? 'Cancel' : 'Huỷ',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySlate,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      kIsWeb
                          ? (isEn ? 'Download PDF' : 'Tải PDF')
                          : (isEn ? 'Save to device' : 'Lưu vào máy'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
