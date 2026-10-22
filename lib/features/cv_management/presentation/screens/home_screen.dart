import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../auth/data/guest_session_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/domain/models/models.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../controllers/dashboard_sync_controller.dart';
import '../widgets/create_cv_dialog.dart';
import '../widgets/home_dialogs.dart';
import '../widgets/my_cvs_view.dart';
import '../widgets/template_catalog_view.dart';

final cvListStreamProvider = StreamProvider.autoDispose<List<CvModel>>((ref) {
  final repository = ref.watch(cvRepositoryProvider);
  final user = ref.watch(currentAuthUserProvider);
  return repository.watchAll().map((cvs) {
    if (user == null) {
      return cvs.where((cv) => cv.userId == null).toList(growable: false);
    }
    return cvs
        .where((cv) => cv.userId == null || cv.userId == user.id)
        .toList(growable: false);
  });
});

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
    final request = await showCreateCvDialog(
      context,
      initialTemplate: initialTemplate,
    );
    if (request == null) return;

    final now = DateTime.now().toUtc();
    final cv = CvModel(
      id: 'local-${now.microsecondsSinceEpoch}',
      userId: ref.read(currentAuthUserProvider)?.id,
      title: request.title,
      templateId: request.templateId,
      language: request.language,
      primaryColor: CvTemplateCatalog.byId(request.templateId).accentHex,
      fontSizeScale: 1,
      summary: '',
      personalInfo: const PersonalInfoModel(),
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
      final newId = 'local-${DateTime.now().microsecondsSinceEpoch}';
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
          .duplicate(
            cv.id,
            newId: 'backup-${now.microsecondsSinceEpoch}',
            now: now.toUtc(),
          );
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

  Future<void> _syncAll() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) return _openLogin();

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
          ? 'Chưa có CV đã lưu để đồng bộ. Mẫu CV chỉ là thiết kế.'
          : 'Đã tải ${result.uploadedCount} CV lên và '
                '${result.downloadedCount} CV về máy.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAuthUserProvider);
    final cvsAsync = ref.watch(cvListStreamProvider);
    final syncState = ref.watch(dashboardSyncControllerProvider);
    final isMyCvs = _selectedIndex == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMyCvs ? Icons.description_rounded : Icons.palette_rounded,
              color: AppTheme.brandIndigo,
            ),
            const SizedBox(width: 8),
            Text(isMyCvs ? 'CV của tôi' : 'Mẫu CV'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: user == null ? 'Đăng nhập' : 'Tài khoản',
            onPressed: user == null
                ? _openLogin
                : () => context.push('/account'),
            icon: Icon(
              user == null ? Icons.login_rounded : Icons.account_circle_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isMyCvs
            ? MyCvsView(
                cvsAsync: cvsAsync,
                isSignedIn: user != null,
                displayName: user?.displayName,
                isSyncing: syncState.isSyncing,
                lastSyncedAt: syncState.lastSyncedAt,
                onSync: _syncAll,
                onLogin: _openLogin,
                onCreate: _createCv,
                onRetry: () => ref.invalidate(cvListStreamProvider),
                onEdit: _openEditor,
                onPreview: (cv) => context.push('/preview', extra: cv),
                onRename: _renameCv,
                onDuplicate: _duplicateCv,
                onBackup: _createBackup,
                onDelete: _deleteCv,
              )
            : TemplateCatalogView(
                onUseTemplate: (template) =>
                    _createCv(initialTemplate: template.id),
                onPremiumTap: (template) =>
                    showPremiumTemplateInfo(context, template),
              ),
      ),
      floatingActionButton: isMyCvs
          ? FloatingActionButton.extended(
              onPressed: _createCv,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo CV mới'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index < 2) {
            setState(() => _selectedIndex = index);
            return;
          }
          user == null ? _openLogin() : context.push('/account');
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
