import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../controllers/offline_pdf_export_controller.dart';
import '../../domain/services/cv_sample_content_service.dart';
import '../providers/pdf_export_provider.dart';
import '../providers/docx_export_provider.dart';
import '../../data/services/pdf_platform_storage.dart';
import '../widgets/a4_pdf_preview.dart';
import '../widgets/cv_preview_controls.dart';
import '../widgets/export_pdf_dialog.dart';

class CvPreviewScreen extends ConsumerStatefulWidget {
  const CvPreviewScreen({super.key, this.cv});

  final CvModel? cv;

  @override
  ConsumerState<CvPreviewScreen> createState() => _CvPreviewScreenState();
}

class _CvPreviewScreenState extends ConsumerState<CvPreviewScreen> {
  late CvModel _workingCv;
  late Future<Uint8List> _pdfBytes;
  bool _isExporting = false;
  late bool _showSampleContent;

  bool get _isEnglish => _workingCv.language == 'en';
  bool get _isEphemeralPreview =>
      widget.cv == null || _workingCv.id.startsWith('template-preview-');

  @override
  void initState() {
    super.initState();
    _workingCv = widget.cv ?? CvModel.empty(id: 'preview-sample');
    _showSampleContent = CvSampleContentService.hasMissingSections(_workingCv);
    _pdfBytes = _generatePdf(_previewCv);
  }

  CvModel get _previewCv => _showSampleContent
      ? CvSampleContentService.fillMissing(_workingCv)
      : _workingCv;

  Future<Uint8List> _generatePdf(CvModel cv) {
    return ref
        .read(pdfExportServiceProvider)
        .generateCvPdf(
          cv: cv,
          language: cv.language,
          templateId: cv.templateId,
        );
  }

  Future<void> _updateDocumentSettings({
    String? language,
    String? templateId,
    double? fontSizeScale,
  }) async {
    final updated = _workingCv.copyWith(
      language: language,
      templateId: templateId,
      fontSizeScale: fontSizeScale,
      isSynced: false,
      updatedAt: DateTime.now().toUtc(),
    );

    setState(() {
      _workingCv = updated;
      _pdfBytes = _generatePdf(_previewCv);
    });

    if (_isEphemeralPreview) return;

    try {
      await ref.read(cvRepositoryProvider).save(updated);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        _isEnglish
            ? 'The preview changed, but the setting could not be saved locally.'
            : 'Bản xem trước đã thay đổi nhưng chưa thể lưu thiết lập vào máy.',
        isError: true,
      );
    }
  }

  void _retryPreview() {
    setState(() => _pdfBytes = _generatePdf(_previewCv));
  }

  void _toggleSampleContent(bool value) {
    setState(() {
      _showSampleContent = value;
      _pdfBytes = _generatePdf(_previewCv);
    });
  }

  Future<void> _handleExportPdf() async {
    final fullName = _workingCv.personalInfo.fullName.trim();
    final defaultBaseName = fullName.isNotEmpty
        ? 'CV_${fullName.replaceAll(RegExp(r'\s+'), '_')}'
        : (_isEnglish ? 'CV_My_Resume' : 'CV_Nguyen_Tuan_Anh');

    final chosenFileName = await ExportPdfDialog.show(
      context: context,
      initialFileName: '$defaultBaseName.pdf',
      isEnglish: _isEnglish,
      fontSizeScale: _workingCv.fontSizeScale,
    );

    if (chosenFileName == null || !mounted) return;
    setState(() => _isExporting = true);

    try {
      if (chosenFileName.toLowerCase().endsWith('.docx')) {
        final docxService = ref.read(docxExportServiceProvider);
        final docxBytes = await docxService.generateDocx(
          cv: _previewCv,
          language: _workingCv.language,
        );
        final savedPath = await savePdfBytes(docxBytes, chosenFileName);
        await sharePdfBytes(docxBytes, chosenFileName);
        if (!mounted) return;
        _showMessage(
          _isEnglish
              ? 'Saved Word document "$chosenFileName" locally ($savedPath).'
              : 'Đã lưu tệp Word "$chosenFileName" tại $savedPath.',
        );
        return;
      }
      final bytes = await _pdfBytes;
      final pdfService = ref.read(pdfExportServiceProvider);
      final result =
          await OfflinePdfExportController(
            cvRepository: ref.read(cvRepositoryProvider),
            pdfService: pdfService,
          ).export(
            cv: _workingCv,
            pdfBytes: bytes,
            fileName: chosenFileName,
            persistCv: !_isEphemeralPreview,
          );
      _workingCv = result.cv;

      if (!result.sharingOpened) {
        if (!mounted) return;
        _showMessage(
          _isEnglish
              ? 'Saved offline at ${result.localPath}. Sharing is currently unavailable.'
              : 'Đã lưu offline tại ${result.localPath}. Hiện chưa thể mở chia sẻ.',
        );
        return;
      }

      if (!mounted) return;
      _showMessage(
        kIsWeb
            ? (_isEnglish
                  ? 'The browser is downloading "$chosenFileName".'
                  : 'Trình duyệt đang tải "$chosenFileName".')
            : (_isEnglish
                  ? 'Saved offline and opened sharing for "$chosenFileName".'
                  : 'Đã lưu offline và mở chia sẻ "$chosenFileName".'),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        _isEnglish
            ? 'Could not export the PDF: $error'
            : 'Không thể xuất tệp PDF: $error',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.dangerRose : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEnglish ? 'Resume Preview' : 'Xem trước CV'),
        actions: [
          if (!_isEphemeralPreview)
            IconButton(
              tooltip: _isEnglish ? 'Edit content' : 'Chỉnh nội dung',
              onPressed: () => context.push('/editor', extra: _workingCv),
              icon: const Icon(Icons.edit_outlined),
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _workingCv.templateId,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppTheme.primarySlate,
              ),
              items: CvTemplateCatalog.freeTemplates
                  .map(
                    (template) => DropdownMenuItem(
                      value: template.id,
                      child: Text(template.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null && value != _workingCv.templateId) {
                  _updateDocumentSettings(templateId: value);
                }
              },
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          CvPreviewControls(
            language: _workingCv.language,
            fontSizeScale: _workingCv.fontSizeScale,
            showSampleContent: _showSampleContent,
            onSampleContentChanged: _toggleSampleContent,
            onLanguageChanged: (value) {
              if (value != _workingCv.language) {
                _updateDocumentSettings(language: value);
              }
            },
            onFontSizeScaleChanged: (value) {
              if ((value - _workingCv.fontSizeScale).abs() >= 0.02) {
                _updateDocumentSettings(fontSizeScale: value);
              }
            },
            onResetFormatting: () => _updateDocumentSettings(
              language: 'vi',
              templateId: 'harvard_ats',
              fontSizeScale: 1,
            ),
          ),
          Expanded(
            child: A4PdfPreview(
              pdfBytes: _pdfBytes,
              isEnglish: _isEnglish,
              onRetry: _retryPreview,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _isExporting ? null : _handleExportPdf,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              _isExporting
                  ? (_isEnglish ? 'Exporting PDF...' : 'Đang xuất PDF...')
                  : (_isEnglish
                        ? 'Download this A4 PDF'
                        : 'Tải đúng bản A4 này'),
            ),
          ),
        ),
      ),
    );
  }
}
