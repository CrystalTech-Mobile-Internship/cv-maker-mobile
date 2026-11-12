import '../../../cv_editor/domain/models/cv_section_definition.dart';
import '../../../cv_editor/domain/services/cv_item_order_service.dart';
import '../../../cv_editor/domain/services/cv_quality_auto_fixer.dart';
import '../../../cv_editor/domain/services/cv_quality_checker.dart';
import '../../../billing/data/supabase_billing_repository.dart';
import '../widgets/cv_item_reorder_sheet.dart';
import '../widgets/cv_quality_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/services/cv_completion_service.dart';
import '../../../cv_management/presentation/widgets/cv_completion_sheet.dart';
import '../controllers/offline_pdf_export_controller.dart';
import '../../domain/services/cv_sample_content_service.dart';
import '../providers/pdf_export_provider.dart';
import '../providers/docx_export_provider.dart';
import '../../data/services/pdf_platform_storage.dart';
import '../widgets/a4_pdf_preview.dart';
import '../widgets/export_pdf_dialog.dart';
import '../widgets/cv_interactive_section_reorder.dart';
import '../widgets/template_gallery_sheet.dart';
import '../widgets/cv_preview_color_sheet.dart';
import '../widgets/cv_page_fit_sheet.dart';
import '../widgets/cv_jd_matcher_sheet.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../../../core/widgets/home_fallback_leading.dart';

enum _PreviewMode { pdfA4, interactiveReorder }

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
  _PreviewMode _mode = _PreviewMode.pdfA4;
  bool _isGrayscaleSimulation = false;

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

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF1E293B);
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  Future<void> _updateDocumentSettings({
    String? language,
    String? templateId,
    double? fontSizeScale,
    String? primaryColor,
    List<String>? sectionOrder,
    List<String>? hiddenSections,
  }) async {
    final updated = _workingCv.copyWith(
      language: language,
      templateId: templateId,
      fontSizeScale: fontSizeScale,
      primaryColor: primaryColor,
      sectionOrder: sectionOrder,
      hiddenSections: hiddenSections,
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
            : 'Chưa lưu được thay đổi. Hãy thử lại.',
        isError: true,
      );
    }
  }

  /// Persists a content change made from the preview (e.g. item order).
  Future<void> _saveContent(CvModel updated) async {
    final stamped = updated.copyWith(
      isSynced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    setState(() {
      _workingCv = stamped;
      _pdfBytes = _generatePdf(_previewCv);
    });
    if (_isEphemeralPreview) return;
    try {
      await ref.read(cvRepositoryProvider).save(stamped);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        _isEnglish
            ? 'The preview changed, but it could not be saved locally.'
            : 'Chưa lưu được thay đổi. Hãy thử lại.',
        isError: true,
      );
    }
  }

  Future<void> _reorderSectionItems(String section) async {
    final definition = CvSectionDefinition.findById(section);
    final order = await showCvItemReorderSheet(
      context,
      sectionTitle: definition?.title(_isEnglish ? 'en' : 'vi') ?? section,
      items: CvItemOrderService.itemsFor(_workingCv, section),
      isEnglish: _isEnglish,
    );
    if (order == null || !mounted) return;
    await _saveContent(CvItemOrderService.reorder(_workingCv, section, order));
    if (!mounted) return;
    _showMessage(
      _isEnglish ? 'Updated entry order.' : 'Đã cập nhật thứ tự các mục.',
    );
  }

  void _showQualityCheck() {
    final autoFix = CvQualityAutoFixer.fix(_workingCv);
    showCvQualitySheet(
      context,
      report: CvQualityChecker.check(_workingCv),
      autoFixChanges: autoFix.changes,
      onAutoFix: _isEphemeralPreview
          ? null
          : () async {
              await _saveContent(autoFix.cv);
              if (!mounted) return;
              _showMessage(
                _isEnglish
                    ? 'Applied ${autoFix.changes.length} formatting fixes.'
                    : 'Đã sửa nhanh ${autoFix.changes.length} lỗi trình bày.',
              );
            },
      onEdit: _isEphemeralPreview
          ? null
          : () => context.push('/editor', extra: _workingCv),
    );
  }

  void _openJobMatch() {
    CvJdMatcherSheet.show(
      context: context,
      cv: _workingCv,
      isEnglish: _isEnglish,
      onAddMissingSkill: (newSkill) {
        final updatedSkills = List<SkillModel>.from(_workingCv.skills)
          ..add(newSkill);
        final updated = _workingCv.copyWith(skills: updatedSkills);
        setState(() {
          _workingCv = updated;
          _pdfBytes = _generatePdf(_previewCv);
        });
        _updateDocumentSettings();
      },
    );
  }

  void _onMenuSelected(_PreviewMenu item) {
    switch (item) {
      case _PreviewMenu.jobMatch:
        _openJobMatch();
      case _PreviewMenu.pageFit:
        CvPageFitSheet.show(
          context: context,
          currentScale: _workingCv.fontSizeScale,
          isEnglish: _isEnglish,
          onScaleChanged: (value) =>
              _updateDocumentSettings(fontSizeScale: value),
        );
      case _PreviewMenu.language:
        _updateDocumentSettings(language: _isEnglish ? 'vi' : 'en');
      case _PreviewMenu.sample:
        _toggleSampleContent(!_showSampleContent);
      case _PreviewMenu.grayscale:
        setState(() => _isGrayscaleSimulation = !_isGrayscaleSimulation);
      case _PreviewMenu.reset:
        _updateDocumentSettings(
          templateId: 'harvard_ats',
          fontSizeScale: 1,
          primaryColor: '#1E293B',
          sectionOrder: List.of(CvModel.defaultSectionOrder),
        );
      case _PreviewMenu.edit:
        context.push('/editor', extra: _workingCv);
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

  void _toggleSectionVisibility(String sectionKey) {
    final currentHidden = List<String>.from(_workingCv.hiddenSections);
    if (currentHidden.contains(sectionKey)) {
      currentHidden.remove(sectionKey);
    } else {
      currentHidden.add(sectionKey);
    }
    _updateDocumentSettings(hiddenSections: currentHidden);
    _showMessage(
      currentHidden.contains(sectionKey)
          ? (_isEnglish
                ? 'Section hidden from PDF/Word export.'
                : 'Đã ẩn mục khỏi bản in PDF/Word.')
          : (_isEnglish
                ? 'Section restored to PDF/Word export.'
                : 'Đã hiện lại mục trên bản in.'),
    );
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
              ? 'Saved on this device at ${result.localPath}. Sharing is currently unavailable.'
              : 'Đã lưu tệp tại ${result.localPath}.',
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
                  ? 'Saved on this device and opened sharing for "$chosenFileName".'
                  : 'Đã lưu trên máy và mở chia sẻ "$chosenFileName".'),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        _isEnglish
            ? 'Could not export the file: $error'
            : 'Không thể xuất tệp: $error',
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

  Widget _buildAtsBadge() {
    // Score the user's real content, never the sample filler.
    final report = CvCompletionService.evaluate(_workingCv);
    final pct = report.percentage;
    final color = pct >= 80
        ? const Color(0xFF15803D)
        : (pct >= 50 ? Colors.amber.shade800 : AppTheme.brandIndigo);
    final bgColor = pct >= 80
        ? const Color(0xFFF0FDF4)
        : (pct >= 50 ? Colors.amber.shade50 : AppTheme.indigoSurface);

    return InkWell(
      key: const Key('preview-ats-badge'),
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showCvCompletionSheet(
          context,
          _workingCv,
          onContinueEditing: () => Navigator.of(context).pop(),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPdfMode = _mode == _PreviewMode.pdfA4;

    return Scaffold(
      appBar: AppBar(
        leading: homeFallbackLeading(context),
        titleSpacing: 0,
        title: Text(
          _isEnglish ? 'Preview' : 'Xem trước',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.fade,
        ),
        actions: [
          _buildAtsBadge(),
          // Template Gallery Picker
          IconButton(
            key: const Key('preview-template-gallery-btn'),
            tooltip: _isEnglish ? 'Template gallery' : 'Đổi mẫu CV',
            icon: const Icon(Icons.style_outlined),
            onPressed: () {
              TemplateGallerySheet.show(
                context: context,
                selectedTemplateId: _workingCv.templateId,
                isEnglish: _isEnglish,
                isPro: ref.read(isProProvider),
                onSelectTemplate: (newId) {
                  _updateDocumentSettings(templateId: newId);
                },
              );
            },
          ),
          // Quick Color Theme Picker
          IconButton(
            key: const Key('preview-color-theme-btn'),
            tooltip: _isEnglish ? 'Color theme' : 'Màu chủ đạo',
            icon: Stack(
              alignment: Alignment.bottomRight,
              children: [
                const Icon(Icons.palette_outlined),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _parseHex(_workingCv.primaryColor),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ],
            ),
            onPressed: () {
              CvPreviewColorSheet.show(
                context: context,
                currentColor: _workingCv.primaryColor,
                isEnglish: _isEnglish,
                onColorSelected: (newColor) {
                  _updateDocumentSettings(primaryColor: newColor);
                },
              );
            },
          ),
          PopupMenuButton<_PreviewMenu>(
            key: const Key('preview-more-menu'),
            tooltip: _isEnglish ? 'More' : 'Thêm',
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                key: const Key('preview-jd-matcher-btn'),
                value: _PreviewMenu.jobMatch,
                child: Text(
                  _isEnglish ? 'Match a job posting' : 'So khớp tin tuyển dụng',
                ),
              ),
              PopupMenuItem(
                key: const Key('preview-page-fit-btn'),
                value: _PreviewMenu.pageFit,
                child: Text(
                  _isEnglish ? 'Text size & page fit' : 'Cỡ chữ, vừa trang',
                ),
              ),
              PopupMenuItem(
                value: _PreviewMenu.language,
                child: Text(
                  _isEnglish
                      ? 'Switch CV to Vietnamese'
                      : 'Chuyển CV sang tiếng Anh',
                ),
              ),
              PopupMenuItem(
                value: _PreviewMenu.sample,
                child: Text(
                  _showSampleContent
                      ? (_isEnglish ? 'Hide sample text' : 'Ẩn nội dung mẫu')
                      : (_isEnglish ? 'Show sample text' : 'Hiện nội dung mẫu'),
                ),
              ),
              PopupMenuItem(
                key: const Key('preview-bw-filter-btn'),
                value: _PreviewMenu.grayscale,
                child: Text(
                  _isGrayscaleSimulation
                      ? (_isEnglish ? 'Colour view' : 'Xem bản màu')
                      : (_isEnglish
                            ? 'Black & white print'
                            : 'Xem bản in đen trắng'),
                ),
              ),
              PopupMenuItem(
                value: _PreviewMenu.reset,
                child: Text(_isEnglish ? 'Reset layout' : 'Khôi phục mặc định'),
              ),
              if (!_isEphemeralPreview)
                PopupMenuItem(
                  value: _PreviewMenu.edit,
                  child: Text(_isEnglish ? 'Edit content' : 'Chỉnh nội dung'),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Segmented Switcher: A4 Page View vs Interactive Drag-and-Drop Layout
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_PreviewMode>(
                key: const Key('preview-mode-segmented'),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppTheme.brandIndigo.withAlpha(25),
                  selectedForegroundColor: AppTheme.brandIndigo,
                  visualDensity: VisualDensity.compact,
                ),
                segments: [
                  ButtonSegment(
                    value: _PreviewMode.pdfA4,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: Text(_isEnglish ? 'Print view' : 'Bản in'),
                  ),
                  ButtonSegment(
                    value: _PreviewMode.interactiveReorder,
                    icon: const Icon(Icons.drag_indicator_rounded, size: 16),
                    label: Text(_isEnglish ? 'Arrange' : 'Sắp xếp'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (set) {
                  setState(() => _mode = set.first);
                },
              ),
            ),
          ),

          // Main View Body
          if (isPdfMode) ...[
            Expanded(
              child: _isGrayscaleSimulation
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: A4PdfPreview(
                        pdfBytes: _pdfBytes,
                        isEnglish: _isEnglish,
                        onRetry: _retryPreview,
                      ),
                    )
                  : A4PdfPreview(
                      pdfBytes: _pdfBytes,
                      isEnglish: _isEnglish,
                      onRetry: _retryPreview,
                    ),
            ),
          ] else ...[
            Expanded(
              child: CvInteractiveSectionReorder(
                cv: _previewCv,
                language: _workingCv.language,
                onToggleVisibility: _toggleSectionVisibility,
                onReorderItems: _reorderSectionItems,
                contentCv: _workingCv,
                onCheckQuality: _showQualityCheck,
                onOrderChanged: (newOrder) {
                  _updateDocumentSettings(sectionOrder: newOrder);
                  _showMessage(
                    _isEnglish
                        ? 'Updated section order for A4 export.'
                        : 'Đã đổi thứ tự các mục.',
                  );
                },
                onResetToDefault: () {
                  _updateDocumentSettings(
                    sectionOrder: List.of(CvModel.defaultSectionOrder),
                  );
                  _showMessage(
                    _isEnglish
                        ? 'Reset to the recommended layout.'
                        : 'Đã khôi phục bố cục khuyến nghị.',
                  );
                },
                onSwitchToPdfView: () =>
                    setState(() => _mode = _PreviewMode.pdfA4),
                onEditSection: (sectionKey) {
                  context.push('/editor', extra: _workingCv);
                },
              ),
            ),
          ],
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
          child: Row(
            children: [
              if (!isPdfMode) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _mode = _PreviewMode.pdfA4),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(_isEnglish ? 'View A4 PDF' : 'Xem bản in A4'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: isPdfMode ? 1 : 1,
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
                        ? (_isEnglish ? 'Exporting...' : 'Đang xuất tệp...')
                        : (_isEnglish
                              ? 'Download (PDF / Word)'
                              : 'Tải PDF/Word'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PreviewMenu {
  jobMatch,
  pageFit,
  language,
  sample,
  grayscale,
  reset,
  edit,
}
