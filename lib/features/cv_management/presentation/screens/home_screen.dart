import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/guest_session_service.dart';
import '../../../cv_editor/data/repositories/cv_repository_provider.dart';
import '../../../cv_editor/domain/models/models.dart';
import '../widgets/cv_template_picker.dart';
import '../widgets/offline_storage_summary.dart';

/// Reactive provider that streams all locally stored CVs from Drift SQLite.
final cvListStreamProvider = StreamProvider.autoDispose<List<CvModel>>((ref) {
  final repository = ref.watch(cvRepositoryProvider);
  return repository.watchAll();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool get _isSignedIn => ref.read(authServiceProvider).currentUser != null;

  Future<void> _openEditor([CvModel? cv]) async {
    await context.push('/editor', extra: cv);
  }

  Future<void> _showCreateCvDialog() async {
    final titleController = TextEditingController();
    String selectedTemplate = 'harvard_ats';
    String selectedLanguage = 'vi'; // 'vi' or 'en'

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.post_add_rounded, color: AppTheme.accentTeal),
                  SizedBox(width: 8),
                  Text('Tạo hồ sơ CV mới'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tên hồ sơ:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'VD: CV Flutter Software Engineer',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mẫu CV (Template):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    CvTemplatePicker(
                      selectedId: selectedTemplate,
                      onChanged: (value) {
                        setDialogState(() => selectedTemplate = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ngôn ngữ mặc định:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'vi',
                          label: Text('🇻🇳 Tiếng Việt'),
                        ),
                        ButtonSegment(value: 'en', label: Text('🇬🇧 English')),
                      ],
                      selected: {selectedLanguage},
                      onSelectionChanged: (set) {
                        setDialogState(() => selectedLanguage = set.first);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Huỷ'),
                ),
                FilledButton.icon(
                  onPressed: titleController.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Tạo ngay'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true) return;

    final now = DateTime.now().toUtc();
    final newCv = CvModel(
      id: 'local-${now.microsecondsSinceEpoch}',
      userId: ref.read(authServiceProvider).currentUser?.id,
      title: titleController.text.trim(),
      templateId: selectedTemplate,
      language: selectedLanguage,
      primaryColor: '#1E293B',
      fontSizeScale: 1.0,
      summary: '',
      personalInfo: const PersonalInfoModel(),
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final repository = ref.read(cvRepositoryProvider);
      await repository.save(newCv);
      if (!mounted) return;
      _showMessage('Đã tạo CV mới thành công.');
      await _openEditor(newCv);
    } catch (_) {
      if (mounted) _showMessage('Không thể tạo CV. Hãy thử lại.');
    }
  }

  Future<void> _showRenameDialog(CvModel cv) async {
    final controller = TextEditingController(text: cv.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên CV'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên hồ sơ mới',
            prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu tên'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final newTitle = controller.text.trim();
    if (newTitle.isEmpty || newTitle == cv.title) return;

    try {
      final updatedCv = cv.copyWith(
        title: newTitle,
        updatedAt: DateTime.now().toUtc(),
      );
      await ref.read(cvRepositoryProvider).save(updatedCv);
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

  Future<void> _createOfflineBackup(CvModel cv) async {
    try {
      final now = DateTime.now();
      final newId = 'backup-${now.microsecondsSinceEpoch}';
      final duplicate = await ref
          .read(cvRepositoryProvider)
          .duplicate(cv.id, newId: newId, now: now.toUtc());
      final backupTitle =
          '${cv.title} — Sao lưu '
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.month.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';
      await ref
          .read(cvRepositoryProvider)
          .save(duplicate.copyWith(title: backupTitle));
      if (mounted) {
        _showMessage('Đã tạo bản sao dự phòng trên thiết bị.');
      }
    } catch (_) {
      if (mounted) _showMessage('Không thể tạo bản sao dự phòng.');
    }
  }

  Future<void> _deleteCv(CvModel cv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xoá CV?'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xoá hồ sơ "${cv.title}" không? '
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(cvRepositoryProvider).deleteById(cv.id);
      if (mounted) _showMessage('Đã xoá CV thành công.');
    } catch (_) {
      if (mounted) _showMessage('Không thể xoá CV.');
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
    } finally {
      await ref.read(guestSessionServiceProvider).setGuestMode(false);
      if (mounted) context.go('/login');
    }
  }

  Future<void> _openLogin() async {
    await ref.read(guestSessionServiceProvider).setGuestMode(false);
    if (mounted) context.go('/login');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cvsAsync = ref.watch(cvListStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: _isSignedIn ? 'Đăng xuất' : 'Đăng nhập',
            icon: Icon(
              _isSignedIn ? Icons.logout_rounded : Icons.login_rounded,
            ),
            onPressed: _isSignedIn ? _signOut : _openLogin,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayoutBuilder(
          mobile: (context, constraints) => _buildMobileLayout(cvsAsync),
          desktop: (context, constraints) => _buildDesktopLayout(cvsAsync),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCvDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo CV mới'),
      ),
    );
  }

  Widget _buildMobileLayout(AsyncValue<List<CvModel>> cvsAsync) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildCvsSection(cvsAsync, isDesktop: false),
        const SizedBox(height: 80), // Padding for FloatingActionButton
      ],
    );
  }

  Widget _buildDesktopLayout(AsyncValue<List<CvModel>> cvsAsync) {
    return WebConstrainedWidth(
      maxWidth: 1200,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildCvsSection(cvsAsync, isDesktop: true),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primarySlate, Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.accentCyan,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trợ lý CV Chuẩn ATS (Local-First)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignedIn
                      ? 'Dữ liệu được lưu an toàn trên máy và tự động đồng bộ Cloud.'
                      : 'Chế độ Ngoại tuyến (Guest Mode): Dữ liệu lưu vĩnh viễn trên máy của bạn.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCvsSection(
    AsyncValue<List<CvModel>> cvsAsync, {
    required bool isDesktop,
  }) {
    return cvsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _buildErrorState(error.toString()),
      data: (cvs) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OfflineStorageSummary(
              localCount: cvs.length,
              pendingSyncCount: cvs.where((cv) => !cv.isSynced).length,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Danh sách hồ sơ của bạn',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySlate.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${cvs.length} hồ sơ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cvs.isEmpty)
              _buildEmptyState()
            else if (isDesktop)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisExtent: 170,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: cvs.length,
                itemBuilder: (context, index) => _buildCvCard(cvs[index]),
              )
            else
              ...cvs.map(_buildCvCard),
          ],
        );
      },
    );
  }

  Widget _buildCvCard(CvModel cv) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditor(cv),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppTheme.accentTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cv.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cv.personalInfo.targetRole.isEmpty
                              ? 'Chưa đặt vị trí ứng tuyển'
                              : cv.personalInfo.targetRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Tùy chọn',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _openEditor(cv);
                          break;
                        case 'preview':
                          context.push('/preview', extra: cv);
                          break;
                        case 'rename':
                          _showRenameDialog(cv);
                          break;
                        case 'duplicate':
                          _duplicateCv(cv);
                          break;
                        case 'offline_backup':
                          _createOfflineBackup(cv);
                          break;
                        case 'delete':
                          _deleteCv(cv);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Xem trước PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(
                              Icons.drive_file_rename_outline_rounded,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Đổi tên'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 20),
                            SizedBox(width: 10),
                            Text('Nhân bản'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'offline_backup',
                        child: Row(
                          children: [
                            Icon(Icons.offline_bolt_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Tạo bản sao dự phòng'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Xoá hồ sơ',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cv.isSynced
                          ? Colors.green.shade50
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: cv.isSynced
                            ? Colors.green.shade200
                            : Colors.amber.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cv.isSynced
                              ? Icons.cloud_done_rounded
                              : Icons.phone_android_rounded,
                          size: 13,
                          color: cv.isSynced
                              ? Colors.green.shade700
                              : Colors.amber.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cv.isSynced ? 'Đã đồng bộ' : 'Lưu trên máy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cv.isSynced
                                ? Colors.green.shade800
                                : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Cập nhật: ${_formatDate(cv.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _messageCard(
      icon: Icons.note_add_outlined,
      title: 'Chưa có hồ sơ CV nào',
      message:
          'Bắt đầu tạo hồ sơ đầu tiên của bạn. '
          'Hồ sơ sẽ được lưu an toàn trên máy và hỗ trợ xuất bản PDF chuẩn ATS.',
      action: 'Tạo CV đầu tiên ngay',
      onPressed: _showCreateCvDialog,
    );
  }

  Widget _buildErrorState(String message) {
    return _messageCard(
      icon: Icons.error_outline_rounded,
      title: 'Không thể tải danh sách hồ sơ',
      message: message,
      action: 'Thử lại',
      onPressed: () => ref.invalidate(cvListStreamProvider),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    required String action,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 52, color: AppTheme.accentTeal),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(action),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'chưa lưu';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
