import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export '../controllers/cv_list_provider.dart' show cvListStreamProvider;

import '../../../../app/theme.dart';
import '../../../auth/data/guest_session_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/screens/account_screen.dart';
import '../../../cv_backup/data/repositories/cv_backup_provider.dart';
import '../../../cv_backup/domain/repositories/cv_backup_repository.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/data/repositories/cv_sync_repository.dart';
import '../../../cv_editor/domain/models/models.dart';
import '../../../resume_import/data/repositories/resume_import_provider.dart';
import '../../../resume_import/domain/repositories/resume_import_repository.dart';
import '../../../resume_import/domain/models/resume_import_draft.dart';
import '../../../resume_import/presentation/resume_draft_saver.dart';
import '../../../resume_import/presentation/widgets/resume_import_mode_sheet.dart';
import '../../../ai_tools/domain/models/ai_assistant_models.dart';
import '../../../community/presentation/screens/community_view.dart';
import '../../../community/presentation/widgets/community_actions.dart';
import '../../../ai_tools/domain/repositories/ai_assistant_repository.dart';
import '../../../ai_tools/presentation/controllers/ai_assistant_providers.dart';
import '../../../ai_tools/presentation/widgets/ai_access_guard.dart';
import '../../../billing/data/supabase_billing_repository.dart';
import '../controllers/cv_list_provider.dart';
import '../controllers/dashboard_sync_controller.dart';
import '../widgets/cloud_sync_preview_sheet.dart';
import '../widgets/create_cv_dialog.dart';
import '../widgets/home_dialogs.dart';
import '../widgets/my_cvs_view.dart';
import '../widgets/template_catalog_view.dart';
import '../../../../core/utils/cv_id.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _openEditor([CvModel? cv]) async {
    await context.push('/editor', extra: cv);
  }

  Future<void> _createCv({String initialTemplate = 'harvard_ats'}) async {
    final existingCvs =
        ref.read(cvListStreamProvider).asData?.value ?? const [];
    final request = await showCreateCvDialog(
      context,
      initialTemplate: initialTemplate,
      existingCvs: existingCvs,
      isPro: ref.read(isProProvider),
    );
    if (request == null) return;

    final now = DateTime.now().toUtc();
    final source = request.sourceCv;
    final cv = CvModel(
      id: newCvId(),
      userId: ref.read(currentAuthUserProvider)?.id,
      title: request.title,
      templateId: request.templateId,
      language: request.language,
      primaryColor: CvTemplateCatalog.byId(request.templateId).accentHex,
      fontSizeScale: 1,
      summary: source?.summary ?? '',
      personalInfo: source?.personalInfo ?? const PersonalInfoModel(),
      educations: source?.educations ?? const [],
      experiences: source?.experiences ?? const [],
      skills: source?.skills ?? const [],
      projects: source?.projects ?? const [],
      certifications: source?.certifications ?? const [],
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(cvRepositoryProvider).save(cv);
      if (!mounted) return;
      setState(() => _selectedIndex = 0);
      _showMessage('Đã tạo CV mới thành công.');
      await _openEditor(cv);
    } catch (_) {
      if (mounted) _showMessage('Không thể tạo CV. Hãy thử lại.');
    }
  }

  Future<void> _importResume() async {
    final importer = ref.read(resumeImportRepositoryProvider);
    try {
      final source = await importer.pickAndExtractText();
      if (source == null || !mounted) return;
      final mode = await showResumeImportModeSheet(
        context,
        fileName: source.fileName,
        characterCount: source.text.length,
        isSignedIn: ref.read(currentAuthUserProvider) != null,
        aiCost: AiCreditCost.parseResume,
      );
      if (mode == null || !mounted) return;

      ResumeImportDraft? draft;
      if (mode == ResumeImportMode.ai) {
        draft = await _parseWithAi(source);
        if (draft == null) return;
      } else {
        draft = importer.parseText(source);
      }
      if (!mounted) return;
      final cv = await reviewAndSaveResumeDraft(context, ref, draft);
      if (cv == null || !mounted) return;
      _showMessage('Đã nhập CV và lưu an toàn trên thiết bị.');
      await _openEditor(cv);
    } on ResumeImportException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Không thể nhập CV. Hãy kiểm tra lại tệp.');
    }
  }

  /// AI extraction with an automatic offline fallback so an AI outage never
  /// blocks the import.
  Future<ResumeImportDraft?> _parseWithAi(ResumeTextSource source) async {
    if (!await ensureAiAccess(context, ref)) return null;
    if (!mounted) return null;
    try {
      return await runWithAiProgress(
        context,
        'Đang đọc CV...',
        () => ref
            .read(aiAssistantRepositoryProvider)
            .parseResume(
              sourceName: source.fileName,
              text: source.text,
              language: 'vi',
            ),
      );
    } on AiWritingFailure catch (failure) {
      if (!mounted) return null;
      _showMessage(
        '${describeAiFailure(failure)} Đã chuyển sang đọc trên máy.',
      );
      return ref.read(resumeImportRepositoryProvider).parseText(source);
    }
  }

  Future<void> _exportAllCvs() async {
    final cvs = ref.read(cvListStreamProvider).asData?.value ?? const [];
    if (cvs.isEmpty) {
      _showMessage('Chưa có CV nào để sao lưu.');
      return;
    }
    try {
      final uri = await ref.read(cvBackupRepositoryProvider).exportBackup(cvs);
      if (!mounted || uri == null) return;
      _showMessage('Đã xuất bản sao của ${cvs.length} CV.');
    } catch (_) {
      if (mounted) _showMessage('Không thể xuất bản sao dữ liệu.');
    }
  }

  Future<void> _restoreCvBackup() async {
    try {
      final imported = await ref
          .read(cvBackupRepositoryProvider)
          .importBackup();
      if (imported == null || !mounted) return;
      final userId = ref.read(currentAuthUserProvider)?.id;
      final baseTime = DateTime.now().toUtc();
      for (var index = 0; index < imported.length; index++) {
        final source = imported[index];
        final restoredAt = baseTime.add(Duration(microseconds: index));
        await ref
            .read(cvRepositoryProvider)
            .save(
              source.copyWith(
                id: 'restored-${restoredAt.microsecondsSinceEpoch}-$index',
                userId: userId,
                title: '${source.title} — Khôi phục',
                isSynced: false,
                createdAt: restoredAt,
                updatedAt: restoredAt,
              ),
            );
      }
      if (mounted) {
        _showMessage(
          'Đã khôi phục ${imported.length} CV thành bản mới trên thiết bị.',
        );
      }
    } on CvBackupException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Không thể khôi phục tệp sao lưu.');
    }
  }

  Future<void> _renameCv(CvModel cv) async {
    final title = await showRenameCvDialog(context, cv);
    if (title == null) return;

    try {
      await ref
          .read(cvRepositoryProvider)
          .save(cv.copyWith(title: title, updatedAt: DateTime.now().toUtc()));
      if (mounted) _showMessage('Đã đổi tên CV thành công.');
    } catch (_) {
      if (mounted) _showMessage('Không thể đổi tên CV.');
    }
  }

  Future<void> _duplicateCv(CvModel cv) async {
    try {
      final newId = newCvId();
      await ref.read(cvRepositoryProvider).duplicate(cv.id, newId: newId);
      if (mounted) _showMessage('Đã nhân bản CV thành công.');
    } catch (_) {
      if (mounted) _showMessage('Không thể nhân bản CV.');
    }
  }

  Future<void> _createBackup(CvModel cv) async {
    try {
      final now = DateTime.now();
      final copy = await ref
          .read(cvRepositoryProvider)
          .duplicate(cv.id, newId: newCvId(), now: now.toUtc());
      final stamp =
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';
      await ref
          .read(cvRepositoryProvider)
          .save(copy.copyWith(title: '${cv.title} — Sao lưu $stamp'));
      if (mounted) _showMessage('Đã tạo bản sao dự phòng trên thiết bị.');
    } catch (_) {
      if (mounted) _showMessage('Không thể tạo bản sao dự phòng.');
    }
  }

  Future<void> _deleteCv(CvModel cv) async {
    if (!await showDeleteCvConfirmation(context, cv)) return;

    try {
      await ref.read(cvRepositoryProvider).deleteById(cv.id);
      if (mounted) _showMessage('Đã xoá CV thành công.');
    } catch (_) {
      if (mounted) _showMessage('Không thể xoá CV.');
    }
  }

  Future<void> _openLogin() async {
    await ref.read(guestSessionServiceProvider).setGuestMode(false);
    if (mounted) context.go('/login');
  }

  /// Moves CVs created without an account into the signed-in account
  /// (after the user taps the button) and backs them up.
  Future<void> _backupGuestCvs() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return _openLogin();
    final cvs = ref.read(cvListStreamProvider).asData?.value ?? const [];
    final guest = cvs.where((cv) => cv.userId == null).toList();
    if (guest.isEmpty) return;
    final repository = ref.read(cvRepositoryProvider);
    for (final cv in guest) {
      await repository.save(cv.copyWith(userId: user.id), now: cv.updatedAt);
    }
    final result = await ref
        .read(dashboardSyncControllerProvider.notifier)
        .synchronize(user.id);
    if (!mounted) return;
    _showMessage(
      result.isSuccess
          ? 'Đã sao lưu ${guest.length} CV vào tài khoản.'
          : 'CV đã được gắn vào tài khoản; sẽ sao lưu lại khi có mạng.',
    );
  }

  Future<void> _syncAll() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return _openLogin();

    final backendLabel = ref.read(authRepositoryProvider).backendLabel;
    final preview = await ref
        .read(cvSyncRepositoryProvider)
        .inspectSyncPreview(
          userId: user.id,
          userEmail: user.email,
          backendLabel: backendLabel,
        );

    if (!mounted) return;

    final confirmed = await CloudSyncPreviewSheet.show(
      context,
      preview: preview,
      onExportBackup: () {
        _exportAllCvs();
      },
    );

    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(dashboardSyncControllerProvider.notifier)
        .synchronize(user.id);
    if (!mounted) return;
    if (!result.isSuccess) {
      _showMessage(result.errorMessage ?? 'Một số CV chưa thể đồng bộ.');
      return;
    }
    _showMessage(
      result.synchronizedCount == 0
          ? 'Chưa có CV nào để đồng bộ.'
          : _syncSuccessMessage(result),
    );
  }

  String _syncSuccessMessage(CvSyncResult result) {
    final actions = <String>[
      if (result.uploadedCount > 0) '${result.uploadedCount} tải lên',
      if (result.downloadedCount > 0) '${result.downloadedCount} tải về',
      if (result.deletedCount > 0) '${result.deletedCount} xoá trên tài khoản',
    ];
    final conflicts = result.conflictCount > 0
        ? ' • ${result.conflictCount} CV sửa ở hai nơi, đã giữ bản mới nhất'
        : '';
    return 'Đồng bộ xong: ${actions.join(', ')}$conflicts.';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    final backendLabel = ref.watch(authRepositoryProvider).backendLabel;
    final cvsAsync = ref.watch(cvListStreamProvider);
    final syncState = ref.watch(dashboardSyncControllerProvider);
    final title = switch (_selectedIndex) {
      0 => 'CV của tôi',
      1 => 'Mẫu CV',
      2 => 'Cộng đồng',
      _ => 'Tài khoản',
    };
    final titleIcon = switch (_selectedIndex) {
      0 => Icons.description_rounded,
      1 => Icons.palette_rounded,
      2 => Icons.forum_outlined,
      _ => Icons.account_circle_outlined,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(titleIcon, color: AppTheme.primarySlate),
            const SizedBox(width: 8),
            Flexible(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              key: const Key('home-create-cv'),
              tooltip: 'Tạo CV',
              onPressed: _createCv,
              icon: const Icon(Icons.add_rounded),
            ),
          if (_selectedIndex == 2 && user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                key: const ValueKey('community-create-post'),
                onPressed: () => createCommunityPost(context, ref),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Đăng bài'),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: switch (_selectedIndex) {
          0 => MyCvsView(
            cvsAsync: cvsAsync,
            isSignedIn: user != null,
            displayName: user?.displayName,
            backendLabel: backendLabel,
            isSyncing: syncState.isSyncing,
            lastSyncedAt: syncState.lastSyncedAt,
            onSync: _syncAll,
            onLogin: _openLogin,
            onCreate: _createCv,
            onImport: _importResume,
            onExportAll: _exportAllCvs,
            onRestoreBackup: _restoreCvBackup,
            onOpenAts: () => context.push('/ats-scorer'),
            onOpenAiInterview: () => context.push('/ai-interview'),
            onBackupGuestCvs: _backupGuestCvs,
            onOpenPro: () => context.push('/upgrade-pro'),
            onRetry: () => ref.invalidate(cvListStreamProvider),
            onEdit: _openEditor,
            onPreview: (cv) => context.push('/preview', extra: cv),
            onRename: _renameCv,
            onDuplicate: _duplicateCv,
            onBackup: _createBackup,
            onDelete: _deleteCv,
          ),
          1 => TemplateCatalogView(
            isPro: ref.watch(isProProvider),
            onUseTemplate: (template) =>
                _createCv(initialTemplate: template.id),
            onPreviewTemplate: (template) {
              final sample =
                  CvModel.empty(id: 'template-preview-${template.id}').copyWith(
                    title: template.name,
                    templateId: template.id,
                    primaryColor: template.accentHex,
                  );
              context.push('/preview', extra: sample);
            },
            onPremiumTap: (template) => showPremiumTemplateInfo(
              context,
              template,
              onViewProPlans: () => context.push('/upgrade-pro'),
            ),
          ),
          2 => const CommunityView(),
          _ => const AccountScreen(embedded: true),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_copy_outlined),
            selectedIcon: Icon(Icons.folder_copy_rounded),
            label: 'CV của tôi',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette_rounded),
            label: 'Mẫu CV',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Cộng đồng',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
