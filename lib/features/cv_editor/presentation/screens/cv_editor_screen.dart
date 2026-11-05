import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../ai_tools/presentation/controllers/summary_polish_controller.dart';
import '../../../ai_tools/presentation/controllers/summary_polish_flow_coordinator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cv_preview/presentation/providers/pdf_export_provider.dart';
import '../../../cv_preview/presentation/widgets/a4_pdf_preview.dart';
import '../../data/repositories/cv_repository_provider.dart';
import '../../data/services/profile_image_service_impl.dart';
import '../../domain/models/models.dart';
import '../../domain/services/cv_starter_template_service.dart';
import '../widgets/education_tab.dart';
import '../widgets/certifications_tab.dart';
import '../widgets/adaptive_editor_tab.dart';
import '../widgets/experience_tab.dart';
import '../widgets/personal_info_tab.dart';
import '../widgets/projects_tab.dart';
import '../widgets/skills_tab.dart';
import '../widgets/section_reorder_sheet.dart';
import '../widgets/starter_sample_picker_sheet.dart';
import '../widgets/ats_action_verbs_sheet.dart';
import '../widgets/editor_typography_toolbar.dart';
import '../../domain/services/cv_completion_service.dart';
import '../../../cv_management/presentation/widgets/cv_completion_sheet.dart';

class CvEditorScreen extends ConsumerStatefulWidget {
  const CvEditorScreen({super.key, this.initialCv});

  final CvModel? initialCv;

  @override
  ConsumerState<CvEditorScreen> createState() => _CvEditorScreenState();
}

class _CvEditorScreenState extends ConsumerState<CvEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final String _draftId;
  late final DateTime _draftCreatedAt;

  late String _selectedLanguage;

  // Personal Info Form Controllers
  final _titleController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _summaryController = TextEditingController();
  String? _avatarPath;
  String _avatarPosition = 'right';

  // Collections State
  List<EducationModel> _educations = [];
  List<ExperienceModel> _experiences = [];
  List<SkillModel> _skills = [];
  List<ProjectModel> _projects = [];
  List<CertificationModel> _certifications = [];
  List<String> _sectionOrder = List.of(CvModel.defaultSectionOrder);
  double _fontSizeScale = 1.0;
  String _primaryColor = '#1E293B';

  bool _isSaving = false;
  Timer? _debounceTimer;
  Timer? _previewDebounceTimer;
  Future<Uint8List>? _desktopPdfBytes;
  String _syncStatusText = 'Đã lưu trên thiết bị';

  bool get _isEn => _selectedLanguage == 'en';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    final now = DateTime.now().toUtc();
    _draftId = widget.initialCv?.id ?? 'local-${now.microsecondsSinceEpoch}';
    _draftCreatedAt = widget.initialCv?.createdAt ?? now;
    _selectedLanguage = widget.initialCv?.language ?? 'vi';
    _loadInitialCv();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleDesktopPreview(immediate: true);
    });
  }

  void _loadInitialCv() {
    final cv = widget.initialCv;
    _titleController.text = cv?.title ?? '';

    if (cv != null) {
      _fullNameController.text = cv.personalInfo.fullName;
      _roleController.text = cv.personalInfo.targetRole;
      _emailController.text = cv.personalInfo.email;
      _phoneController.text = cv.personalInfo.phone;
      _locationController.text = cv.personalInfo.address;
      _summaryController.text = cv.summary;
      _avatarPath = cv.personalInfo.avatarPath;
      _avatarPosition = cv.personalInfo.avatarPosition;
      _educations = List.of(cv.educations);
      _experiences = List.of(cv.experiences);
      _skills = List.of(cv.skills);
      _projects = List.of(cv.projects);
      _certifications = List.of(cv.certifications);
      _sectionOrder = List.of(cv.effectiveSectionOrder);
      _fontSizeScale = cv.fontSizeScale;
      _primaryColor = cv.primaryColor.isNotEmpty ? cv.primaryColor : '#1E293B';
    }
  }

  void _changeLanguage({required String language, bool notify = true}) {
    final isEn = language == 'en';
    setState(() => _selectedLanguage = language);

    if (notify) {
      _onFieldChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? 'Language changed to English.'
                : 'Đã chuyển sang tiếng Việt.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onFieldChanged([String? _]) {
    _debounceTimer?.cancel();
    _scheduleDesktopPreview();
    if (_syncStatusText != 'Đang tự động lưu...') {
      setState(() => _syncStatusText = 'Đang tự động lưu...');
    }
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      try {
        final model = _buildCvModel();
        await ref.read(cvRepositoryProvider).save(model);
        if (!mounted) return;
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        setState(
          () => _syncStatusText = _isEn
              ? 'Auto-saved ($timeStr)'
              : 'Đã tự động lưu ($timeStr)',
        );
      } catch (_) {
        if (mounted) {
          setState(
            () => _syncStatusText = _isEn
                ? 'Auto-save failed'
                : 'Lỗi tự động lưu',
          );
        }
      }
    });
  }

  void _scheduleDesktopPreview({bool immediate = false}) {
    _previewDebounceTimer?.cancel();
    if (!mounted || MediaQuery.sizeOf(context).width < 1100) return;

    void refresh() {
      if (!mounted) return;
      final cv = _buildCvModel();
      setState(() {
        _desktopPdfBytes = ref
            .read(pdfExportServiceProvider)
            .generateCvPdf(
              cv: cv,
              language: cv.language,
              templateId: cv.templateId,
            );
      });
    }

    if (immediate) {
      refresh();
      return;
    }
    _previewDebounceTimer = Timer(const Duration(milliseconds: 450), refresh);
  }

  void _showInputValidationError(String vietnamese, String english) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isEn ? english : vietnamese),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final path = await ref
          .read(profileImageServiceProvider)
          .pickAndStoreImage();
      if (path == null || !mounted) return;
      setState(() => _avatarPath = path);
      _onFieldChanged();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEn
                ? 'Could not add this photo. Please choose another image.'
                : 'Không thể thêm ảnh này. Vui lòng chọn ảnh khác.',
          ),
        ),
      );
    }
  }

  void _removeProfilePhoto() {
    setState(() => _avatarPath = null);
    _onFieldChanged();
  }

  void _openSectionReorderSheet() {
    SectionReorderSheet.show(
      context: context,
      currentOrder: _sectionOrder,
      language: _selectedLanguage,
      onOrderChanged: (newOrder) {
        setState(() => _sectionOrder = List.of(newOrder));
        _onFieldChanged();
      },
    );
  }

  void _openStarterSamplePicker() {
    StarterSamplePickerSheet.show(
      context: context,
      language: _selectedLanguage,
      onSelectSummary: (summary) {
        setState(() => _summaryController.text = summary);
        _onFieldChanged();
      },
      onAddExperiences: (samples) {
        setState(() => _experiences.addAll(samples));
        _onFieldChanged();
      },
      onAddProjects: (samples) {
        setState(() => _projects.addAll(samples));
        _onFieldChanged();
      },
      onAddSkills: (samples) {
        setState(() => _skills.addAll(samples));
        _onFieldChanged();
      },
      onAddEducation: (samples) {
        setState(() => _educations.addAll(samples));
        _onFieldChanged();
      },
      onAddCertifications: (samples) {
        setState(() => _certifications.addAll(samples));
        _onFieldChanged();
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _previewDebounceTimer?.cancel();
    _tabController.dispose();
    _titleController.dispose();
    _fullNameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  CvModel _buildCvModel() {
    final existing = widget.initialCv;
    final currentUserId = ref.read(currentAuthUserProvider)?.id;
    final title = _titleController.text.trim();
    final now = DateTime.now().toUtc();

    return CvModel(
      id: _draftId,
      userId: existing?.userId ?? currentUserId,
      title: title.isEmpty ? (_isEn ? 'My Resume' : 'CV của tôi') : title,
      templateId: existing?.templateId ?? 'harvard_ats',
      language: _selectedLanguage,
      primaryColor: _primaryColor,
      fontSizeScale: _fontSizeScale,
      sectionOrder: _sectionOrder,
      summary: _summaryController.text.trim(),
      personalInfo: PersonalInfoModel(
        fullName: _fullNameController.text.trim(),
        targetRole: _roleController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _locationController.text.trim(),
        avatarPath: _avatarPath,
        avatarPosition: _avatarPosition,
      ),
      educations: _educations,
      experiences: _experiences,
      skills: _skills,
      projects: _projects,
      certifications: _certifications,
      isSynced: existing?.isSynced ?? false,
      createdAt: _draftCreatedAt,
      updatedAt: now,
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final model = _buildCvModel();
    final userId = ref.read(currentAuthUserProvider)?.id;

    final result = await ref
        .read(cvSyncRepositoryProvider)
        .saveAndSync(model, userId: userId);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEn
                ? 'Saved locally. Cloud sync pending: ${result.errorMessage}'
                : 'Đã lưu trên máy. Chưa đồng bộ cloud: ${result.errorMessage}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result.isSynced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEn
                ? 'Saved and synchronized to Supabase Cloud.'
                : 'Đã lưu và đồng bộ lên Supabase Cloud Singapore.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEn
                ? 'Saved safely on device (Offline Mode).'
                : 'Đã lưu an toàn trên máy (Chế độ Ngoại tuyến).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    context.pop(result.savedCv);
  }

  Future<void> _handleAiOptimizeSummary() async {
    final user = ref.read(currentAuthUserProvider);
    final original = _summaryController.text.trim();
    final targetRole = _roleController.text.trim();
    final notifier = ref.read(summaryPolishControllerProvider.notifier);
    final result = await const SummaryPolishFlowCoordinator().run(
      context: context,
      controller: notifier,
      isAuthenticated: user != null,
      original: original,
      targetRole: targetRole,
      language: _selectedLanguage,
      skills: _skills
          .map((skill) => skill.name.trim())
          .where((name) => name.isNotEmpty)
          .take(20)
          .toList(growable: false),
      onSaving: () {
        if (!mounted) return;
        _debounceTimer?.cancel();
        setState(
          () => _syncStatusText = _isEn
              ? 'Saving AI suggestion locally...'
              : 'Đang lưu gợi ý AI trên máy...',
        );
      },
      persistSuggestion: (suggestion) async {
        final candidate = _buildCvModel().copyWith(summary: suggestion);
        await ref.read(cvRepositoryProvider).save(candidate);
      },
    );
    if (!mounted) return;

    if (result.status == SummaryPolishFlowStatus.failed) {
      setState(
        () => _syncStatusText = _isEn
            ? 'AI suggestion was not applied'
            : 'Chưa áp dụng gợi ý AI',
      );
      _showInputValidationError(
        result.messageVi ?? 'Không thể tối ưu lúc này. Hãy thử lại.',
        result.messageEn ?? 'AI is unavailable. Please try again.',
      );
      return;
    }
    if (result.status == SummaryPolishFlowStatus.applied) {
      setState(() {
        _summaryController.text = result.suggestion!;
        _syncStatusText = _isEn
            ? 'AI suggestion saved on device'
            : 'Đã lưu gợi ý AI trên máy';
      });
      _scheduleDesktopPreview();
    }
  }

  // --- Collection Interactive Dialogs ---

  Future<void> _showAddEducationDialog([EducationModel? editing]) async {
    final isEdit = editing != null;
    final instCtrl = TextEditingController(text: editing?.institution ?? '');
    final degreeCtrl = TextEditingController(text: editing?.degree ?? '');
    final fieldCtrl = TextEditingController(text: editing?.fieldOfStudy ?? '');
    final startYearCtrl = TextEditingController(
      text: editing?.startDate.year.toString() ?? '2020',
    );
    final endYearCtrl = TextEditingController(
      text: editing?.endDate?.year.toString() ?? '2024',
    );
    final gpaCtrl = TextEditingController(text: editing?.gpa ?? '3.5 / 4.0');
    var isCurrent = editing?.isCurrent ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit
                ? (_isEn ? 'Edit Education' : 'Sửa thông tin học vấn')
                : (_isEn ? 'Add Education' : 'Thêm học vấn & bằng cấp'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: instCtrl,
                  decoration: InputDecoration(
                    labelText: _isEn
                        ? 'University / Institution *'
                        : 'Trường đại học / Cao đẳng *',
                    hintText: _isEn
                        ? 'e.g. Stanford University'
                        : 'VD: Đại học Bách Khoa Hà Nội',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: degreeCtrl,
                  decoration: InputDecoration(
                    labelText: _isEn ? 'Degree *' : 'Bằng cấp *',
                    hintText: _isEn ? 'Bachelor of Science' : 'Kỹ sư / Cử nhân',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fieldCtrl,
                  decoration: InputDecoration(
                    labelText: _isEn ? 'Field of Study' : 'Chuyên ngành',
                    hintText: _isEn
                        ? 'Computer Science'
                        : 'Công nghệ Thông tin',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startYearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _isEn ? 'Start Year' : 'Năm bắt đầu',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isCurrent)
                      Expanded(
                        child: TextField(
                          controller: endYearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _isEn ? 'End Year' : 'Năm tốt nghiệp',
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          _isEn ? 'Present' : 'Hiện tại',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isCurrent,
                  onChanged: (value) {
                    setDialogState(() => isCurrent = value ?? false);
                  },
                  title: Text(
                    _isEn ? 'Currently studying here' : 'Đang học tại đây',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gpaCtrl,
                  decoration: InputDecoration(
                    labelText: _isEn
                        ? 'GPA (Optional)'
                        : 'Điểm GPA (Không bắt buộc)',
                    hintText: '3.6 / 4.0',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_isEn ? 'Cancel' : 'Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (instCtrl.text.trim().isEmpty ||
                    degreeCtrl.text.trim().isEmpty) {
                  _showInputValidationError(
                    'Vui lòng nhập tên trường và bằng cấp.',
                    'Enter an institution and degree.',
                  );
                  return;
                }
                final startYear = int.tryParse(startYearCtrl.text.trim());
                final endYear = int.tryParse(endYearCtrl.text.trim());
                if (startYear == null ||
                    startYear < 1900 ||
                    startYear > 2100 ||
                    (!isCurrent &&
                        (endYear == null ||
                            endYear < 1900 ||
                            endYear > 2100))) {
                  _showInputValidationError(
                    'Năm học phải là số từ 1900 đến 2100.',
                    'Enter study years between 1900 and 2100.',
                  );
                  return;
                }
                if (!isCurrent && endYear! < startYear) {
                  _showInputValidationError(
                    'Năm tốt nghiệp không thể trước năm bắt đầu.',
                    'The graduation year cannot precede the start year.',
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(_isEn ? 'Save' : 'Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final startYear = int.parse(startYearCtrl.text.trim());
      final endYear = isCurrent ? null : int.parse(endYearCtrl.text.trim());
      final newItem = EducationModel(
        id: editing?.id ?? 'edu-${DateTime.now().microsecondsSinceEpoch}',
        institution: instCtrl.text.trim(),
        degree: degreeCtrl.text.trim(),
        fieldOfStudy: fieldCtrl.text.trim(),
        startDate: DateTime.utc(startYear, 9, 15),
        endDate: endYear == null ? null : DateTime.utc(endYear, 6, 15),
        isCurrent: isCurrent,
        gpa: gpaCtrl.text.trim().isEmpty ? null : gpaCtrl.text.trim(),
      );

      setState(() {
        if (isEdit) {
          final idx = _educations.indexWhere((e) => e.id == editing.id);
          if (idx != -1) _educations[idx] = newItem;
        } else {
          _educations.add(newItem);
        }
      });
      _onFieldChanged();
    }
  }

  void _deleteEducation(String id) {
    setState(() {
      _educations.removeWhere((e) => e.id == id);
    });
    _onFieldChanged();
  }

  Future<void> _showAddExperienceDialog([ExperienceModel? editing]) async {
    final isEdit = editing != null;
    final roleCtrl = TextEditingController(text: editing?.jobTitle ?? '');
    final compCtrl = TextEditingController(text: editing?.company ?? '');
    final locCtrl = TextEditingController(text: editing?.location ?? '');
    final startMonthCtrl = TextEditingController(
      text: (editing?.startDate.month ?? 1).toString(),
    );
    final startYearCtrl = TextEditingController(
      text: (editing?.startDate.year ?? DateTime.now().year).toString(),
    );
    final endMonthCtrl = TextEditingController(
      text: (editing?.endDate?.month ?? DateTime.now().month).toString(),
    );
    final endYearCtrl = TextEditingController(
      text: (editing?.endDate?.year ?? DateTime.now().year).toString(),
    );
    var isCurrent = editing?.isCurrent ?? true;
    final bulletCtrl = TextEditingController(
      text: editing != null && editing.bulletPoints.isNotEmpty
          ? editing.bulletPoints.join('\n')
          : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit
                ? (_isEn ? 'Edit Experience' : 'Sửa kinh nghiệm làm việc')
                : (_isEn ? 'Add Work Experience' : 'Thêm kinh nghiệm làm việc'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roleCtrl,
                  decoration: InputDecoration(
                    labelText: _isEn
                        ? 'Job Title / Role *'
                        : 'Vị trí / Chức danh *',
                    hintText: _isEn
                        ? 'Mobile Engineer'
                        : 'Kỹ sư phần mềm Flutter',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: compCtrl,
                  decoration: InputDecoration(
                    labelText: _isEn
                        ? 'Company / Organization *'
                        : 'Doanh nghiệp / Công ty *',
                    hintText: _isEn
                        ? 'Tech Innovations Inc.'
                        : 'Công ty Cổ phần Công nghệ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: InputDecoration(
                    labelText: _isEn ? 'Location' : 'Địa điểm làm việc',
                    hintText: _isEn ? 'Hanoi, Vietnam' : 'Hà Nội, Việt Nam',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startMonthCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _isEn ? 'Start month' : 'Tháng bắt đầu',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: startYearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _isEn ? 'Start year' : 'Năm bắt đầu',
                        ),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isCurrent,
                  onChanged: (value) {
                    setDialogState(() => isCurrent = value ?? false);
                  },
                  title: Text(
                    _isEn ? 'Currently working here' : 'Đang làm việc tại đây',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (!isCurrent) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: endMonthCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _isEn ? 'End month' : 'Tháng kết thúc',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: endYearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _isEn ? 'End year' : 'Năm kết thúc',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: bulletCtrl,
                  minLines: 5,
                  maxLines: 7,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    labelText: _isEn
                        ? 'Key Achievements (1 per line)'
                        : 'Mô tả & Thành tích (mỗi dòng 1 ý)',
                    hintText: _isEn
                        ? 'Engineered offline SQLite cache...\nAchieved 60fps UI performance...'
                        : 'Thiết kế kiến trúc Clean Architecture...\nTối ưu hiệu năng ứng dụng di động...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_isEn ? 'Cancel' : 'Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (roleCtrl.text.trim().isEmpty ||
                    compCtrl.text.trim().isEmpty) {
                  _showInputValidationError(
                    'Vui lòng nhập vị trí và tên công ty.',
                    'Enter a job title and company.',
                  );
                  return;
                }
                final startMonth = int.tryParse(startMonthCtrl.text.trim());
                final startYear = int.tryParse(startYearCtrl.text.trim());
                final endMonth = int.tryParse(endMonthCtrl.text.trim());
                final endYear = int.tryParse(endYearCtrl.text.trim());
                if (startMonth == null ||
                    startMonth < 1 ||
                    startMonth > 12 ||
                    startYear == null ||
                    startYear < 1900 ||
                    startYear > 2100 ||
                    (!isCurrent &&
                        (endMonth == null ||
                            endMonth < 1 ||
                            endMonth > 12 ||
                            endYear == null ||
                            endYear < 1900 ||
                            endYear > 2100))) {
                  _showInputValidationError(
                    'Nhập tháng từ 1 đến 12 và năm từ 1900 đến 2100.',
                    'Enter months from 1 to 12 and years from 1900 to 2100.',
                  );
                  return;
                }
                if (!isCurrent &&
                    DateTime(
                      endYear!,
                      endMonth!,
                    ).isBefore(DateTime(startYear, startMonth))) {
                  _showInputValidationError(
                    'Thời gian kết thúc không thể trước thời gian bắt đầu.',
                    'The end date cannot precede the start date.',
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(_isEn ? 'Save' : 'Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final bullets = bulletCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final startMonth = int.parse(startMonthCtrl.text.trim());
      final startYear = int.parse(startYearCtrl.text.trim());
      final endMonth = isCurrent ? null : int.parse(endMonthCtrl.text.trim());
      final endYear = isCurrent ? null : int.parse(endYearCtrl.text.trim());
      final newItem = ExperienceModel(
        id: editing?.id ?? 'exp-${DateTime.now().microsecondsSinceEpoch}',
        jobTitle: roleCtrl.text.trim(),
        company: compCtrl.text.trim(),
        location: locCtrl.text.trim(),
        startDate: DateTime.utc(startYear, startMonth),
        endDate: isCurrent ? null : DateTime.utc(endYear!, endMonth!),
        isCurrent: isCurrent,
        bulletPoints: bullets.isEmpty
            ? [
                _isEn
                    ? 'Built cross-platform features adhering to Clean Architecture principles.'
                    : 'Phát triển tính năng đa nền tảng tuân thủ kiến trúc Clean Architecture.',
              ]
            : bullets,
      );

      setState(() {
        if (isEdit) {
          final idx = _experiences.indexWhere((e) => e.id == editing.id);
          if (idx != -1) _experiences[idx] = newItem;
        } else {
          _experiences.add(newItem);
        }
      });
      _onFieldChanged();
    }
  }

  void _deleteExperience(String id) {
    setState(() {
      _experiences.removeWhere((e) => e.id == id);
    });
    _onFieldChanged();
  }

  Future<void> _showAddSkillDialog([SkillModel? editing]) async {
    final isEdit = editing != null;
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    var category = editing?.category ?? SkillCategory.hard;
    var proficiency = (editing?.proficiency ?? 85).toDouble();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit
                ? (_isEn ? 'Edit Skill' : 'Sửa kỹ năng')
                : (_isEn ? 'Add Skill' : 'Thêm kỹ năng'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: _isEn ? 'Skill Name *' : 'Tên kỹ năng *',
                    hintText: _isEn
                        ? 'e.g. Flutter, Clean Architecture'
                        : 'VD: Flutter & Dart',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEn ? 'Category:' : 'Loại kỹ năng:',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<SkillCategory>(
                  segments: [
                    ButtonSegment(
                      value: SkillCategory.hard,
                      label: Text(_isEn ? 'Technical' : 'Chuyên môn'),
                      icon: const Icon(Icons.code_rounded),
                    ),
                    ButtonSegment(
                      value: SkillCategory.soft,
                      label: Text(_isEn ? 'Soft Skill' : 'Kỹ năng mềm'),
                      icon: const Icon(Icons.psychology_outlined),
                    ),
                  ],
                  selected: {category},
                  onSelectionChanged: (set) {
                    setDialogState(() => category = set.first);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  _isEn
                      ? 'Proficiency: ${proficiency.round()}%'
                      : 'Mức độ thành thạo: ${proficiency.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: proficiency,
                  min: 10,
                  max: 100,
                  divisions: 18,
                  label: '${proficiency.round()}%',
                  onChanged: (val) {
                    setDialogState(() => proficiency = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_isEn ? 'Cancel' : 'Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  _showInputValidationError(
                    'Vui lòng nhập tên kỹ năng.',
                    'Enter a skill name.',
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: Text(
                isEdit ? (_isEn ? 'Save' : 'Lưu') : (_isEn ? 'Add' : 'Thêm'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final newSkill = SkillModel(
        id: editing?.id ?? 'skill-${DateTime.now().microsecondsSinceEpoch}',
        name: nameCtrl.text.trim(),
        category: category,
        proficiency: proficiency.round(),
      );
      setState(() {
        if (isEdit) {
          final index = _skills.indexWhere((skill) => skill.id == editing.id);
          if (index != -1) _skills[index] = newSkill;
        } else {
          _skills.add(newSkill);
        }
      });
      _onFieldChanged();
    }
  }

  void _deleteSkill(String id) {
    setState(() {
      _skills.removeWhere((s) => s.id == id);
    });
    _onFieldChanged();
  }

  Future<void> _showProjectDialog([ProjectModel? editing]) async {
    final name = TextEditingController(text: editing?.name ?? '');
    final role = TextEditingController(text: editing?.role ?? '');
    final team = TextEditingController(
      text: editing?.teamSize?.toString() ?? '',
    );
    final tech = TextEditingController(
      text: editing?.technologies.join(', ') ?? '',
    );
    final source = TextEditingController(text: editing?.sourceUrl ?? '');
    final demo = TextEditingController(text: editing?.demoUrl ?? '');
    final details = TextEditingController(text: editing?.description ?? '');
    final start = TextEditingController(
      text: editing?.startDate == null
          ? ''
          : '${editing!.startDate!.month}/${editing.startDate!.year}',
    );
    final end = TextEditingController(
      text: editing?.endDate == null
          ? ''
          : '${editing!.endDate!.month}/${editing.endDate!.year}',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          editing == null
              ? (_isEn ? 'Add Project' : 'Thêm dự án')
              : (_isEn ? 'Edit Project' : 'Sửa dự án'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: _isEn ? 'Project name *' : 'Tên dự án *',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: role,
                decoration: InputDecoration(
                  labelText: _isEn ? 'Role' : 'Vai trò',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: team,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isEn ? 'Team size' : 'Số người trong nhóm',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tech,
                decoration: InputDecoration(
                  labelText: _isEn
                      ? 'Technologies (comma separated)'
                      : 'Công nghệ (ngăn cách bằng dấu phẩy)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: source,
                decoration: const InputDecoration(
                  labelText: 'GitHub / Source URL',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: demo,
                decoration: const InputDecoration(
                  labelText: 'Website / Demo URL',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: start,
                      decoration: InputDecoration(
                        labelText: _isEn
                            ? 'Start (MM/YYYY)'
                            : 'Bắt đầu (MM/YYYY)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: end,
                      decoration: InputDecoration(
                        labelText: _isEn
                            ? 'End (MM/YYYY)'
                            : 'Kết thúc (MM/YYYY)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: details,
                minLines: 5,
                maxLines: 8,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: _isEn
                      ? 'Tasks (one bullet per line)'
                      : 'Công việc đã làm (mỗi dòng một ý)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isEn ? 'Cancel' : 'Huỷ'),
          ),
          FilledButton(
            onPressed: () =>
                name.text.trim().isEmpty ? null : Navigator.pop(ctx, true),
            child: Text(_isEn ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final item = ProjectModel(
      id: editing?.id ?? 'project-${DateTime.now().microsecondsSinceEpoch}',
      name: name.text.trim(),
      role: role.text.trim(),
      description: details.text.trim(),
      teamSize: int.tryParse(team.text.trim()),
      technologies: tech.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      sourceUrl: source.text.trim().isEmpty ? null : source.text.trim(),
      demoUrl: demo.text.trim().isEmpty ? null : demo.text.trim(),
      startDate: _parseMonthYear(start.text),
      endDate: _parseMonthYear(end.text),
    );
    setState(() {
      final index = _projects.indexWhere((e) => e.id == item.id);
      index < 0 ? _projects.add(item) : _projects[index] = item;
    });
    _onFieldChanged();
  }

  void _deleteProject(String id) {
    setState(() => _projects.removeWhere((e) => e.id == id));
    _onFieldChanged();
  }

  Future<void> _showCertificationDialog([CertificationModel? editing]) async {
    final name = TextEditingController(text: editing?.name ?? '');
    final score = TextEditingController(text: editing?.score ?? '');
    final issuer = TextEditingController(text: editing?.issuer ?? '');
    final url = TextEditingController(text: editing?.credentialUrl ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          editing == null
              ? (_isEn ? 'Add certification' : 'Thêm chứng chỉ')
              : (_isEn ? 'Edit certification' : 'Sửa chứng chỉ'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: _isEn ? 'Certification name *' : 'Tên chứng chỉ *',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: score,
                decoration: InputDecoration(
                  labelText: _isEn ? 'Score / level' : 'Điểm / cấp độ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: issuer,
                decoration: InputDecoration(
                  labelText: _isEn ? 'Issuer' : 'Đơn vị cấp',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: url,
                decoration: const InputDecoration(labelText: 'Credential URL'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isEn ? 'Cancel' : 'Huỷ'),
          ),
          FilledButton(
            onPressed: () =>
                name.text.trim().isEmpty ? null : Navigator.pop(ctx, true),
            child: Text(_isEn ? 'Save' : 'Lưu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final item = CertificationModel(
      id: editing?.id ?? 'cert-${DateTime.now().microsecondsSinceEpoch}',
      name: name.text.trim(),
      score: score.text.trim().isEmpty ? null : score.text.trim(),
      issuer: issuer.text.trim(),
      credentialUrl: url.text.trim().isEmpty ? null : url.text.trim(),
    );
    setState(() {
      final index = _certifications.indexWhere((e) => e.id == item.id);
      index < 0 ? _certifications.add(item) : _certifications[index] = item;
    });
    _onFieldChanged();
  }

  void _deleteCertification(String id) {
    setState(() => _certifications.removeWhere((e) => e.id == id));
    _onFieldChanged();
  }

  DateTime? _parseMonthYear(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 2) return null;
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null || month < 1 || month > 12) return null;
    return DateTime(year, month).toUtc();
  }

  void _openPreview() {
    context.push('/preview', extra: _buildCvModel());
  }

    Widget _buildCompletenessBadge(bool isEn) {
    final cv = _buildCvModel();
    final report = CvCompletionService.evaluate(cv);
    final pct = report.percentage;
    final color = pct >= 80
        ? const Color(0xFF15803D)
        : (pct >= 50 ? Colors.amber.shade800 : AppTheme.brandIndigo);
    final bgColor = pct >= 80
        ? const Color(0xFFF0FDF4)
        : (pct >= 50 ? Colors.amber.shade50 : AppTheme.indigoSurface);

    return InkWell(
      key: const Key('cv-completeness-badge'),
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        showCvCompletionSheet(
          context,
          cv,
          onContinueEditing: () => Navigator.of(context).pop(),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 12,
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
    final summaryPolishState = ref.watch(summaryPolishControllerProvider);
    final isSignedIn = ref.watch(currentAuthUserProvider) != null;
    final isEn = _isEn;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialCv == null
                  ? (isEn ? 'Create New Resume' : 'Tạo CV mới')
                  : (isEn ? 'Edit Resume' : 'Chỉnh sửa CV'),
            ),
            Text(
              _syncStatusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          _buildCompletenessBadge(isEn),
          IconButton(
            tooltip: isEn ? 'Starter Samples' : 'Mẫu gợi ý',
            icon: const Icon(Icons.lightbulb_outline_rounded),
            onPressed: _openStarterSamplePicker,
          ),
          IconButton(
            tooltip: isEn ? 'Reorder Sections' : 'Sắp xếp bố cục',
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: _openSectionReorderSheet,
          ),
          IconButton(
            tooltip: isEn ? 'Preview Vector PDF' : 'Xem trước PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _openPreview,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: AppTheme.accentTeal,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppTheme.accentTeal,
            indicatorWeight: 3.5,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.grey.shade200,
            labelPadding: EdgeInsets.zero,
            tabs: [
              AdaptiveEditorTab(
                controller: _tabController,
                index: 0,
                icon: Icons.person_outline,
                label: isEn ? 'Personal' : 'Cá nhân',
              ),
              AdaptiveEditorTab(
                controller: _tabController,
                index: 1,
                icon: Icons.school_outlined,
                label: isEn ? 'Education' : 'Học vấn',
              ),
              AdaptiveEditorTab(
                controller: _tabController,
                index: 2,
                icon: Icons.work_outline,
                label: isEn ? 'Experience' : 'Kinh nghiệm',
              ),
              AdaptiveEditorTab(
                controller: _tabController,
                index: 3,
                icon: Icons.psychology_outlined,
                label: isEn ? 'Skills' : 'Kỹ năng',
              ),
              AdaptiveEditorTab(
                controller: _tabController,
                index: 4,
                icon: Icons.folder_copy_outlined,
                label: isEn ? 'Projects' : 'Dự án',
              ),
              AdaptiveEditorTab(
                controller: _tabController,
                index: 5,
                icon: Icons.workspace_premium_outlined,
                label: isEn ? 'Certificates' : 'Chứng chỉ',
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, pageConstraints) {
          final editorPane = Column(
            children: [
              // Language Switcher Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final selector = SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'vi', label: Text('VI')),
                        ButtonSegment(value: 'en', label: Text('EN')),
                      ],
                      selected: {_selectedLanguage},
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                      onSelectionChanged: (set) {
                        final newLang = set.first;
                        if (newLang != _selectedLanguage) {
                          _changeLanguage(language: newLang, notify: true);
                        }
                      },
                    );
                    final label = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.language_rounded,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEn ? 'Language:' : 'Ngôn ngữ CV:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 360) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          label,
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: selector,
                          ),
                        ],
                      );
                    }
                    return Row(children: [label, const Spacer(), selector]);
                  },
                ),
              ),

              // Quick formatting, sizing, samples & reorder toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: EditorTypographyToolbar(
                  currentScale: _fontSizeScale,
                  language: _selectedLanguage,
                  currentColor: _primaryColor,
                  onColorChanged: (newColor) {
                    setState(() => _primaryColor = newColor);
                    _onFieldChanged();
                  },
                  onScaleChanged: (scale) {
                    setState(() => _fontSizeScale = scale);
                    _onFieldChanged();
                  },
                  onOpenSectionReorder: _openSectionReorderSheet,
                  onOpenStarterSamples: _openStarterSamplePicker,
                  onOpenActionVerbs: () {
                    AtsActionVerbsSheet.show(
                      context: context,
                      language: _selectedLanguage,
                      onInsertVerb: (verb) {
                        final controller = _tabController.index == 0 ? _summaryController : null;
                        if (controller != null) {
                          final curText = controller.text;
                          final sel = controller.selection;
                          final pos = sel.isValid ? sel.start : curText.length;
                          final prefix = (pos > 0 && !curText.endsWith('\n') && !curText.endsWith(' ')) ? ' ' : '';
                          controller.value = TextEditingValue(
                            text: curText.replaceRange(pos, pos, '$prefix$verb '),
                            selection: TextSelection.collapsed(offset: pos + prefix.length + verb.length + 1),
                          );
                          _onFieldChanged();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn ? 'Inserted action verb "$verb".' : 'Đã chèn từ khóa hành động "$verb".',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                  textController: _tabController.index == 0 ? _summaryController : null,
                ),
              ),

              // Main Tabs Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Personal Info
                    PersonalInfoTab(
                      language: _selectedLanguage,
                      titleController: _titleController,
                      fullNameController: _fullNameController,
                      roleController: _roleController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      locationController: _locationController,
                      summaryController: _summaryController,
                      onFieldChanged: _onFieldChanged,
                      onAiOptimize: _handleAiOptimizeSummary,
                      isAiLoading: summaryPolishState.isLoading,
                      avatarPath: _avatarPath,
                      onPickAvatar: _pickProfilePhoto,
                      onRemoveAvatar: _removeProfilePhoto,
                      avatarPosition: _avatarPosition,
                      onAvatarPositionChanged: (position) {
                        setState(() => _avatarPosition = position);
                        _onFieldChanged();
                      },
                      supportsProfilePhoto:
                          const {
                            AppConstants.templateMinimalistClean,
                            AppConstants.templateCreativeTech,
                            AppConstants.templateProfessionalSidebar,
                          }.contains(
                            widget.initialCv?.templateId ??
                                AppConstants.templateHarvardAts,
                          ),
                    ),

                    // Tab 2: Education
                    EducationTab(
                      language: _selectedLanguage,
                      educations: _educations,
                      onAddEducation: () => _showAddEducationDialog(),
                      onEditEducation: _showAddEducationDialog,
                      onDeleteEducation: _deleteEducation,
                      onUseStarterEducation: () {
                        final starters = CvStarterTemplateService.getStarterEducation(_selectedLanguage);
                        setState(() => _educations.addAll(starters));
                        _onFieldChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn ? 'Added starter education sample.' : 'Đã thêm mẫu học vấn.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    // Tab 3: Experience
                    ExperienceTab(
                      language: _selectedLanguage,
                      experiences: _experiences,
                      onAddExperience: () => _showAddExperienceDialog(),
                      onEditExperience: _showAddExperienceDialog,
                      onDeleteExperience: _deleteExperience,
                      onUseStarterExperience: () {
                        final starters = CvStarterTemplateService.getStarterExperiences(_selectedLanguage);
                        setState(() => _experiences.addAll(starters));
                        _onFieldChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn ? 'Added starter experience sample.' : 'Đã thêm mẫu kinh nghiệm.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),

                    // Tab 4: Skills
                    SkillsTab(
                      language: _selectedLanguage,
                      skills: _skills,
                      onAddSkill: _showAddSkillDialog,
                      onAddSkillModel: (newSkill) {
                        setState(() => _skills.add(newSkill));
                        _onFieldChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn
                                  ? 'Added skill "${newSkill.name}".'
                                  : 'Đã thêm kỹ năng "${newSkill.name}".',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onEditSkill: _showAddSkillDialog,
                      onDeleteSkill: _deleteSkill,
                      onUseStarterSkills: () {
                        final starters = CvStarterTemplateService.getStarterSkills(_selectedLanguage);
                        setState(() => _skills.addAll(starters));
                        _onFieldChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn ? 'Added starter skills sample.' : 'Đã thêm bộ kỹ năng mẫu.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    ProjectsTab(
                      language: _selectedLanguage,
                      projects: _projects,
                      onAdd: () => _showProjectDialog(),
                      onEdit: _showProjectDialog,
                      onDelete: _deleteProject,
                      onUseStarterProjects: () {
                        final starters = CvStarterTemplateService.getStarterProjects(_selectedLanguage);
                        setState(() => _projects.addAll(starters));
                        _onFieldChanged();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isEn ? 'Added starter project sample.' : 'Đã thêm mẫu dự án.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    CertificationsTab(
                      language: _selectedLanguage,
                      items: _certifications,
                      onAdd: () => _showCertificationDialog(),
                      onEdit: _showCertificationDialog,
                      onDelete: _deleteCertification,
                    ),
                  ],
                ),
              ),
            ],
          );

          if (pageConstraints.maxWidth < 1100) return editorPane;

          final pdfBytes = _desktopPdfBytes;
          return Row(
            children: [
              Expanded(flex: 11, child: editorPane),
              const VerticalDivider(width: 1, color: AppTheme.softBorder),
              Expanded(
                flex: 9,
                child: ColoredBox(
                  color: const Color(0xFFF1F5F9),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                        color: Colors.white,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: AppTheme.brandIndigo,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                isEn
                                    ? 'Live A4 preview'
                                    : 'Xem trước A4 trực tiếp',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _openPreview,
                              icon: const Icon(Icons.open_in_full_rounded),
                              label: Text(isEn ? 'Open' : 'Mở rộng'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: pdfBytes == null
                            ? const Center(child: CircularProgressIndicator())
                            : A4PdfPreview(
                                pdfBytes: pdfBytes,
                                isEnglish: isEn,
                                onRetry: () =>
                                    _scheduleDesktopPreview(immediate: true),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isEn
                              ? (isSignedIn ? 'Sync Cloud' : 'Save Locally')
                              : (isSignedIn ? 'Lưu lên Cloud' : 'Lưu vào máy'),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _openPreview,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(isEn ? 'Preview CV' : 'Xem trước CV'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
