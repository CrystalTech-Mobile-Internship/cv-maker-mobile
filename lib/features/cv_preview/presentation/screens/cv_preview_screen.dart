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
import '../widgets/cv_font_sheet.dart';
import '../../../cv_editor/domain/models/cv_font.dart';
import '../widgets/cv_page_fit_sheet.dart';
import '../widgets/cv_jd_matcher_sheet.dart';
import '../../../cv_editor/domain/models/skill_model.dart';
import '../../../../core/widgets/home_fallback_leading.dart';
import '../../../../core/widgets/responsive_action_bar.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../widgets/cv_a4_design_board.dart';
import '../widgets/preview_section_panel.dart';
import '../../domain/models/pdf_section_region.dart';
import '../../../ai_tools/presentation/widgets/cv_ai_edit_panel.dart';
import 'package:flutter/services.dart';

enum _PreviewMode { pdfA4, interactiveReorder, designA4 }

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

  // Desktop workspace state.
  String? _selectedSection;
  String? _aiSection;
  List<PdfSectionRegion> _regions = [];
  bool _showAiPanel = true;
  bool _designOnPage = false;
  final List<CvModel> _undo = [];
  final _shortcutFocus = FocusNode(debugLabel: 'preview-shortcuts');

  @override
  void dispose() {
    _shortcutFocus.dispose();
    super.dispose();
  }

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
    // A fresh list per build; the page view reads it once the PDF is ready.
    _regions = [];
    return ref
        .read(pdfExportServiceProvider)
        .generateCvPdf(
          cv: cv,
          language: cv.language,
          templateId: cv.templateId,
          sectionRegions: _regions,
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
    String? fontFamily,
    String? primaryColor,
    List<String>? sectionOrder,
    List<String>? hiddenSections,
  }) async {
    _remember();
    final updated = _workingCv.copyWith(
      language: language,
      templateId: templateId,
      fontSizeScale: fontSizeScale,
      fontFamily: fontFamily,
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
    _remember();
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

  void _remember() {
    _undo.add(_workingCv);
    if (_undo.length > 30) _undo.removeAt(0);
  }

  Future<void> _undoLast() async {
    if (_undo.isEmpty) {
      _showMessage(
        _isEnglish ? 'Nothing to undo.' : 'Không còn gì để hoàn tác.',
      );
      return;
    }
    final previous = _undo.removeLast();
    setState(() {
      _workingCv = previous;
      _pdfBytes = _generatePdf(_previewCv);
    });
    if (!_isEphemeralPreview) {
      try {
        await ref.read(cvRepositoryProvider).save(previous);
      } catch (_) {
        if (!mounted) return;
        _showMessage(
          _isEnglish
              ? 'Could not save the undo.'
              : 'Chưa lưu được thao tác hoàn tác.',
          isError: true,
        );
        return;
      }
    }
    if (!mounted) return;
    _showMessage(_isEnglish ? 'Undone.' : 'Đã hoàn tác.');
  }

  void _setVisibleOrder(List<String> visible) {
    final order = [
      ...visible,
      ..._workingCv.effectiveSectionOrder.where((id) => !visible.contains(id)),
    ];
    _updateDocumentSettings(sectionOrder: order);
  }

  void _moveSelected(int delta) {
    final id = _selectedSection;
    final visible = _workingCv.visibleSectionOrder;
    final from = id == null ? -1 : visible.indexOf(id);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= visible.length) return;
    final order = [...visible]..removeAt(from);
    order.insert(to, id!);
    _setVisibleOrder(order);
  }

  void _selectSection(String id) {
    setState(() {
      _selectedSection = id;
      _aiSection = id;
      _showAiPanel = true;
    });
  }

  void _changeFontScale(double delta) {
    final next = ((_workingCv.fontSizeScale + delta) * 100).round() / 100;
    _updateDocumentSettings(fontSizeScale: next.clamp(0.75, 1.4).toDouble());
  }

  void _openTemplates() {
    TemplateGallerySheet.show(
      context: context,
      selectedTemplateId: _workingCv.templateId,
      isEnglish: _isEnglish,
      isPro: ref.read(isProProvider),
      onSelectTemplate: (newId) => _updateDocumentSettings(templateId: newId),
    );
  }

  void _openFonts() {
    CvFontSheet.show(
      context: context,
      currentFontId: _workingCv.fontFamily,
      isPro: ref.read(isProProvider),
      isEnglish: _isEnglish,
      onSelected: (id) => _updateDocumentSettings(fontFamily: id),
      onLocked: () => context.push('/upgrade-pro'),
    );
  }

  void _openColors() {
    CvPreviewColorSheet.show(
      context: context,
      currentColor: _workingCv.primaryColor,
      isEnglish: _isEnglish,
      onColorSelected: (newColor) =>
          _updateDocumentSettings(primaryColor: newColor),
    );
  }

  void _openEditor() {
    if (_isEphemeralPreview) return;
    context.push('/editor', extra: _workingCv);
  }

  void _showShortcuts() {
    final rows = [
      ('Ctrl + S', _isEnglish ? 'Download PDF / Word' : 'Tải PDF/Word'),
      ('Ctrl + E', _isEnglish ? 'Edit content' : 'Chỉnh nội dung'),
      ('Ctrl + Z', _isEnglish ? 'Undo layout change' : 'Hoàn tác'),
      (
        'Ctrl + K',
        _isEnglish ? 'Show / hide edit chat' : 'Mở/đóng khung nhờ sửa',
      ),
      (
        'Ctrl + D',
        _isEnglish
            ? 'Print view / drag on page'
            : 'Bản in / kéo thả trên trang',
      ),
      (
        'Alt + ↑ / ↓',
        _isEnglish ? 'Move selected section' : 'Di chuyển mục đang chọn',
      ),
      (
        'Ctrl + ] / [',
        _isEnglish ? 'Bigger / smaller text' : 'Tăng/giảm cỡ chữ',
      ),
      (
        _isEnglish ? 'Ctrl + wheel' : 'Ctrl + cuộn chuột',
        _isEnglish ? 'Zoom the page' : 'Phóng to/thu nhỏ trang',
      ),
    ];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEnglish ? 'Keyboard shortcuts' : 'Phím tắt'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 130,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.softBorder),
                        ),
                        child: Text(
                          row.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(row.$2)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_isEnglish ? 'Close' : 'Đóng'),
          ),
        ],
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
    const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
      if (!_isExporting) _handleExportPdf();
    },
    const SingleActivator(LogicalKeyboardKey.keyE, control: true): _openEditor,
    const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undoLast,
    const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
        setState(() => _showAiPanel = !_showAiPanel),
    const SingleActivator(LogicalKeyboardKey.keyD, control: true): () =>
        setState(() => _designOnPage = !_designOnPage),
    const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () =>
        _moveSelected(-1),
    const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () =>
        _moveSelected(1),
    const SingleActivator(LogicalKeyboardKey.bracketRight, control: true): () =>
        _changeFontScale(0.05),
    const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true): () =>
        _changeFontScale(-0.05),
  };

  Widget _printView({bool fitPage = false, bool clickable = false}) {
    final preview = A4PdfPreview(
      fitPage: fitPage,
      sectionRegions: _regions,
      selectedSection: clickable ? _aiSection : null,
      onSectionTap: clickable ? _selectSection : null,
      pdfBytes: _pdfBytes,
      isEnglish: _isEnglish,
      onRetry: _retryPreview,
    );
    if (!_isGrayscaleSimulation) return preview;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0, 0, 0, 1, 0,
      ]),
      child: preview,
    );
  }

  /// Computer layout: sections | print view | edit chat, all on one screen.
  Widget _desktopBody() {
    final en = _isEnglish;
    final selected =
        _selectedSection ??
        (_workingCv.visibleSectionOrder.isEmpty
            ? null
            : _workingCv.visibleSectionOrder.first);
    return Listener(
      // After a click, give the keyboard back to the page shortcuts unless
      // the user is typing in a field (a pressed button may have taken
      // focus and then disappeared).
      onPointerUp: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final focused = FocusManager.instance.primaryFocus?.context;
        final typing =
            focused != null &&
            (focused.widget is EditableText ||
                focused.findAncestorWidgetOfExactType<EditableText>() != null);
        if (!typing) _shortcutFocus.requestFocus();
      }),
      child: CallbackShortcuts(
        bindings: _shortcuts,
        child: Focus(
          focusNode: _shortcutFocus,
          autofocus: true,
          child: Column(
            children: [
              _DesktopToolbar(
                isEnglish: en,
                cv: _workingCv,
                designOnPage: _designOnPage,
                showAiPanel: _showAiPanel,
                canUndo: _undo.isNotEmpty,
                onTemplates: _openTemplates,
                onColors: _openColors,
                onFonts: _openFonts,
                onFontScale: _changeFontScale,
                onLanguage: () =>
                    _updateDocumentSettings(language: en ? 'vi' : 'en'),
                onCheck: _showQualityCheck,
                onJobMatch: _openJobMatch,
                onUndo: _undoLast,
                onToggleDesign: () =>
                    setState(() => _designOnPage = !_designOnPage),
                onToggleAi: () => setState(() => _showAiPanel = !_showAiPanel),
                onShortcuts: _showShortcuts,
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_designOnPage) ...[
                      SizedBox(
                        width: 280,
                        child: PreviewSectionPanel(
                          key: const Key('preview-section-panel'),
                          cv: _workingCv,
                          selected: selected,
                          onSelect: _selectSection,
                          onVisibleOrderChanged: _setVisibleOrder,
                          onToggleVisibility: _toggleSectionVisibility,
                          onReorderItems: _reorderSectionItems,
                        ),
                      ),
                      const VerticalDivider(
                        width: 1,
                        color: AppTheme.softBorder,
                      ),
                    ],
                    Expanded(
                      child: _designOnPage
                          ? CvA4DesignBoard(
                              key: const Key('preview-design-board'),
                              cv: _workingCv,
                              onLayoutChanged: (order, hidden) =>
                                  _updateDocumentSettings(
                                    sectionOrder: order,
                                    hiddenSections: hidden,
                                  ),
                            )
                          : _printView(fitPage: true, clickable: true),
                    ),
                    if (_showAiPanel) ...[
                      const VerticalDivider(
                        width: 1,
                        color: AppTheme.softBorder,
                      ),
                      SizedBox(
                        width: 340,
                        child: CvAiEditPanel(
                          cv: _workingCv,
                          section: _aiSection,
                          onSectionChanged: (id) => setState(() {
                            _aiSection = id;
                            if (id != null) _selectedSection = id;
                          }),
                          onApply: (updated) async {
                            await _saveContent(updated);
                            if (!mounted) return;
                            _showMessage(
                              en
                                  ? 'Applied. Ctrl + Z to undo.'
                                  : 'Đã áp dụng. Bấm Ctrl + Z để hoàn tác.',
                            );
                          },
                          onClose: () => setState(() => _showAiPanel = false),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      case _PreviewMenu.font:
        _openFonts();
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
          fontFamily: CvFontCatalog.defaultId,
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
        : (_isEnglish ? 'CV_My_Resume' : 'CV_cua_toi');

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
        // Sample lines only guide on screen; files contain real content.
        final docxBytes = await docxService.generateDocx(
          cv: _workingCv,
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
      final bytes = _showSampleContent
          ? await _generatePdf(_workingCv)
          : await _pdfBytes;
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
    // The A4 designer needs room for the palette and a full-size sheet.
    final canDesign = MediaQuery.sizeOf(context).width >= 1100;
    if (!canDesign && _mode == _PreviewMode.designA4) {
      _mode = _PreviewMode.pdfA4;
    }
    final isPdfMode = _mode == _PreviewMode.pdfA4;
    final isDesktop = canDesign && !_isEphemeralPreview;

    final downloadButton = FilledButton.icon(
      key: const Key('preview-download'),
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
            : (_isEnglish ? 'Download (PDF / Word)' : 'Tải PDF/Word'),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceLight,
        appBar: AppBar(
          leading: homeFallbackLeading(context),
          titleSpacing: 0,
          title: Text(
            _isEnglish ? 'Preview' : 'Xem trước',
            maxLines: 1,
            overflow: TextOverflow.fade,
          ),
          actions: [
            _buildAtsBadge(),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Ctrl + E',
              child: OutlinedButton.icon(
                onPressed: _openEditor,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(_isEnglish ? 'Edit content' : 'Chỉnh nội dung'),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(message: 'Ctrl + S', child: downloadButton),
            const SizedBox(width: 12),
          ],
        ),
        body: _desktopBody(),
      );
    }

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
                key: const Key('preview-font-btn'),
                value: _PreviewMenu.font,
                child: Text(_isEnglish ? 'Font' : 'Phông chữ'),
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
            // Full width on phones, a compact centred switch on computers.
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: canDesign ? 560 : 420),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_PreviewMode>(
                    key: const Key('preview-mode-segmented'),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppTheme.brandIndigo.withAlpha(
                        25,
                      ),
                      selectedForegroundColor: AppTheme.brandIndigo,
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: [
                      ButtonSegment(
                        value: _PreviewMode.pdfA4,
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 16,
                        ),
                        label: Text(_isEnglish ? 'Print view' : 'Bản in'),
                      ),
                      ButtonSegment(
                        value: _PreviewMode.interactiveReorder,
                        icon: const Icon(
                          Icons.drag_indicator_rounded,
                          size: 16,
                        ),
                        label: Text(_isEnglish ? 'Arrange' : 'Sắp xếp'),
                      ),
                      if (canDesign)
                        ButtonSegment(
                          value: _PreviewMode.designA4,
                          icon: const Icon(
                            Icons.dashboard_customize_outlined,
                            size: 16,
                          ),
                          label: Text(_isEnglish ? 'Design' : 'Thiết kế'),
                        ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (set) {
                      setState(() => _mode = set.first);
                    },
                  ),
                ),
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
          ] else if (_mode == _PreviewMode.designA4) ...[
            Expanded(
              child: CvA4DesignBoard(
                key: const Key('preview-design-board'),
                cv: _workingCv,
                onLayoutChanged: (order, hidden) => _updateDocumentSettings(
                  sectionOrder: order,
                  hiddenSections: hidden,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: WebConstrainedWidth(
                maxWidth: 760,
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
          child: ResponsiveActionBar(
            children: [
              if (!isPdfMode)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _mode = _PreviewMode.pdfA4),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(_isEnglish ? 'View A4 PDF' : 'Xem bản in A4'),
                ),
              downloadButton,
            ],
          ),
        ),
      ),
    );
  }
}

enum _PreviewMenu {
  jobMatch,
  font,
  pageFit,
  language,
  sample,
  grayscale,
  reset,
  edit,
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.isEnglish,
    required this.cv,
    required this.designOnPage,
    required this.showAiPanel,
    required this.canUndo,
    required this.onTemplates,
    required this.onColors,
    required this.onFonts,
    required this.onFontScale,
    required this.onLanguage,
    required this.onCheck,
    required this.onJobMatch,
    required this.onUndo,
    required this.onToggleDesign,
    required this.onToggleAi,
    required this.onShortcuts,
  });

  final bool isEnglish;
  final CvModel cv;
  final bool designOnPage;
  final bool showAiPanel;
  final bool canUndo;
  final VoidCallback onTemplates;
  final VoidCallback onColors;
  final VoidCallback onFonts;
  final ValueChanged<double> onFontScale;
  final VoidCallback onLanguage;
  final VoidCallback onCheck;
  final VoidCallback onJobMatch;
  final VoidCallback onUndo;
  final VoidCallback onToggleDesign;
  final VoidCallback onToggleAi;
  final VoidCallback onShortcuts;

  @override
  Widget build(BuildContext context) {
    final en = isEnglish;
    final scale = (cv.fontSizeScale * 100).round();
    Color swatch;
    try {
      swatch = Color(
        int.parse('FF${cv.primaryColor.replaceAll('#', '')}', radix: 16),
      );
    } catch (_) {
      swatch = AppTheme.primarySlate;
    }
    const gap = SizedBox(width: 4);
    Widget divider() => const SizedBox(
      height: 24,
      child: VerticalDivider(width: 17, color: AppTheme.softBorder),
    );

    return Container(
      key: const Key('preview-desktop-toolbar'),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.softBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton.icon(
                    key: const Key('preview-template-gallery-btn'),
                    onPressed: onTemplates,
                    icon: const Icon(Icons.style_outlined, size: 18),
                    label: Text(en ? 'Template' : 'Mẫu CV'),
                  ),
                  TextButton.icon(
                    key: const Key('preview-color-theme-btn'),
                    onPressed: onColors,
                    icon: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: Text(en ? 'Colour' : 'Màu CV'),
                  ),
                  TextButton.icon(
                    key: const Key('preview-font-btn'),
                    onPressed: onFonts,
                    icon: const Icon(Icons.text_fields_rounded, size: 18),
                    label: Text(CvFontCatalog.byId(cv.fontFamily).name),
                  ),
                  divider(),
                  Text(
                    en ? 'Text size' : 'Cỡ chữ',
                    style: const TextStyle(color: AppTheme.mutedText),
                  ),
                  IconButton(
                    tooltip: en ? 'Smaller (Ctrl + [)' : 'Nhỏ hơn (Ctrl + [)',
                    visualDensity: VisualDensity.compact,
                    onPressed: cv.fontSizeScale > 0.75
                        ? () => onFontScale(-0.05)
                        : null,
                    icon: const Icon(Icons.remove_rounded, size: 18),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '$scale%',
                      key: const Key('preview-font-scale'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: en ? 'Bigger (Ctrl + ])' : 'Lớn hơn (Ctrl + ])',
                    visualDensity: VisualDensity.compact,
                    onPressed: cv.fontSizeScale < 1.4
                        ? () => onFontScale(0.05)
                        : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                  divider(),
                  TextButton(
                    onPressed: onLanguage,
                    child: Text(
                      en ? 'EN → VI' : 'VI → EN',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onCheck,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: Text(en ? 'Check' : 'Kiểm tra lỗi'),
                  ),
                  TextButton.icon(
                    key: const Key('preview-jd-matcher-btn'),
                    onPressed: onJobMatch,
                    icon: const Icon(Icons.work_outline_rounded, size: 18),
                    label: Text(en ? 'Match a job' : 'So khớp tin tuyển dụng'),
                  ),
                  gap,
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: en ? 'Undo (Ctrl + Z)' : 'Hoàn tác (Ctrl + Z)',
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo_rounded, size: 20),
          ),
          Tooltip(
            message: 'Ctrl + D',
            child: TextButton.icon(
              key: const Key('preview-design-toggle'),
              onPressed: onToggleDesign,
              icon: Icon(
                designOnPage
                    ? Icons.picture_as_pdf_outlined
                    : Icons.dashboard_customize_outlined,
                size: 18,
              ),
              label: Text(
                designOnPage
                    ? (en ? 'Print view' : 'Xem bản in')
                    : (en ? 'Drag on page' : 'Kéo thả trên trang'),
              ),
            ),
          ),
          Tooltip(
            message: 'Ctrl + K',
            child: TextButton.icon(
              key: const Key('preview-ai-toggle'),
              style: showAiPanel
                  ? TextButton.styleFrom(
                      backgroundColor: AppTheme.indigoSurface,
                    )
                  : null,
              onPressed: onToggleAi,
              icon: const Icon(Icons.smart_toy_outlined, size: 18),
              label: Text(en ? 'Ask to edit' : 'Nhờ sửa'),
            ),
          ),
          IconButton(
            key: const Key('preview-shortcuts'),
            tooltip: en ? 'Keyboard shortcuts' : 'Phím tắt',
            onPressed: onShortcuts,
            icon: const Icon(Icons.keyboard_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
