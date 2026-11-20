import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../../../cv_editor/domain/services/cv_completion_service.dart';
import 'cloud_sync_card.dart';
import 'cv_completion_sheet.dart';
import 'cv_library_section.dart';
import 'ai_assistant_card.dart';
import 'local_data_tools_card.dart';
import 'template_thumbnail.dart';
import 'upcoming_tools_row.dart';
import '../../../../core/i18n/app_language.dart';

class MyCvsView extends StatelessWidget {
  const MyCvsView({
    super.key,
    required this.cvsAsync,
    required this.isSignedIn,
    required this.displayName,
    required this.backendLabel,
    required this.isSyncing,
    required this.lastSyncedAt,
    required this.onSync,
    required this.onLogin,
    required this.onCreate,
    required this.onImport,
    required this.onExportAll,
    required this.onRestoreBackup,
    required this.onOpenAts,
    required this.onOpenAiInterview,
    this.onBackupGuestCvs,
    required this.onOpenPro,
    required this.onRetry,
    required this.onEdit,
    required this.onPreview,
    required this.onRename,
    required this.onDuplicate,
    required this.onBackup,
    required this.onDelete,
  });

  final AsyncValue<List<CvModel>> cvsAsync;
  final bool isSignedIn;
  final String? displayName;
  final String backendLabel;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final VoidCallback onSync;
  final VoidCallback onLogin;
  final VoidCallback onCreate;
  final VoidCallback onImport;
  final VoidCallback onExportAll;
  final VoidCallback onRestoreBackup;
  final VoidCallback onOpenAts;
  final VoidCallback onOpenAiInterview;

  /// Assigns CVs created without an account to the signed-in account.
  final VoidCallback? onBackupGuestCvs;
  final VoidCallback onOpenPro;
  final VoidCallback onRetry;
  final ValueChanged<CvModel> onEdit;
  final ValueChanged<CvModel> onPreview;
  final ValueChanged<CvModel> onRename;
  final ValueChanged<CvModel> onDuplicate;
  final ValueChanged<CvModel> onBackup;
  final ValueChanged<CvModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 860) return _desktopContent(context);
        if (width < 640) return _content(context, isDesktop: false);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _content(context, isDesktop: false),
          ),
        );
      },
    );
  }

  /// Computer layout: CV library on the left, tools in a side column.
  Widget _desktopContent(BuildContext context) {
    final cvs = cvsAsync.asData?.value ?? const <CvModel>[];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            key: const PageStorageKey('my-cvs'),
            padding: const EdgeInsets.fromLTRB(32, 24, 24, 48),
            children: [_library(context, isDesktop: true)],
          ),
        ),
        Container(
          key: const Key('my-cvs-side-panel'),
          width: 360,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppTheme.softBorder)),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 24, 150),
            children: _tools(context, cvs),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, {required bool isDesktop}) {
    final cvs = cvsAsync.asData?.value ?? const <CvModel>[];
    return ListView(
      key: const PageStorageKey('my-cvs'),
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 16,
        isDesktop ? 24 : 16,
        isDesktop ? 32 : 16,
        150,
      ),
      children: [
        _library(context, isDesktop: isDesktop),
        const SizedBox(height: 18),
        ..._tools(context, cvs),
      ],
    );
  }

  Widget _library(BuildContext context, {required bool isDesktop}) {
    return cvsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _MessageCard(
        icon: Icons.error_outline_rounded,
        title: tr('Không thể tải danh sách hồ sơ', 'Could not load your CVs'),
        message: tr(
          'Không đọc được CV trên máy. Hãy tải lại trang hoặc mở lại ứng dụng.',
          'Could not read CVs on this device. Reload the page or reopen the app.',
        ),
        action: tr('Thử lại', 'Try again'),
        onPressed: onRetry,
      ),
      data: (items) {
        if (items.isEmpty) {
          return _MessageCard(
            icon: Icons.note_add_outlined,
            title: tr('Chưa có hồ sơ CV nào', 'No CVs yet'),
            message: tr(
              'Chọn một mẫu phù hợp và bắt đầu hồ sơ đầu tiên.',
              'Pick a template and start your first CV.',
            ),
            action: tr('Tạo CV đầu tiên', 'Create first CV'),
            onPressed: onCreate,
          );
        }
        final guestCount = isSignedIn
            ? items.where((cv) => cv.userId == null).length
            : 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (guestCount > 0 && onBackupGuestCvs != null) ...[
              _GuestBackupCard(count: guestCount, onBackup: onBackupGuestCvs!),
              const SizedBox(height: 12),
            ],
            CvLibrarySection(
              items: items,
              isDesktop: isDesktop,
              itemBuilder: _cvCard,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _tools(BuildContext context, List<CvModel> cvs) {
    return [
      AiAssistantCard(onChat: onOpenAiInterview, onImport: onImport),
      const SizedBox(height: 12),
      UpcomingToolsRow(
        onOpenAts: onOpenAts,
        onOpenPro: onOpenPro,
        onPractice: () => context.push('/interview-practice'),
      ),
      // On the web every save goes straight to the account and a full sync
      // runs at sign-in, so the manual button is only kept on phones.
      if (!kIsWeb) ...[
        const SizedBox(height: 12),
        CloudSyncCard(
          isSignedIn: isSignedIn,
          localCount: cvs.length,
          pendingCount: cvs.where((cv) => !cv.isSynced).length,
          backendLabel: backendLabel,
          isSyncing: isSyncing,
          lastSyncedAt: lastSyncedAt,
          onSync: onSync,
          onLogin: onLogin,
        ),
      ],
      const SizedBox(height: 12),
      LocalDataToolsCard(onExport: onExportAll, onRestore: onRestoreBackup),
    ];
  }

  Widget _cvCard(BuildContext context, CvModel cv) {
    final completion = CvCompletionService.evaluate(cv).percentage;
    final template = CvTemplateCatalog.byId(cv.templateId);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 54,
                  child: TemplateThumbnail(template: template, borderRadius: 6),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cv.personalInfo.targetRole.isEmpty
                            ? template.name
                            : cv.personalInfo.targetRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$completion%',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _SyncBadge(isSynced: cv.isSynced),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: AppTheme.brandIndigo,
                        ),
                      ),
                    ],
                  ),
                ),
                _CvActionsMenu(
                  cv: cv,
                  onEdit: onEdit,
                  onPreview: onPreview,
                  onRename: onRename,
                  onDuplicate: onDuplicate,
                  onBackup: onBackup,
                  onDelete: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onEdit(cv),
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: Text(tr('Chỉnh sửa', 'Edit')),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: tr('Xem trước PDF', 'Preview PDF'),
                  onPressed: () => onPreview(cv),
                  icon: const Icon(Icons.visibility_outlined),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  key: ValueKey('cv-checklist-${cv.id}'),
                  tooltip: tr('Checklist hoàn thiện', 'Checklist'),
                  onPressed: () => showCvCompletionSheet(
                    context,
                    cv,
                    onContinueEditing: () => onEdit(cv),
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.isSynced});

  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    final color = isSynced ? const Color(0xFF15803D) : const Color(0xFFB45309);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSynced ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          isSynced
              ? tr('Đã sao lưu', 'Backed up')
              : tr('Trên máy', 'On device'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CvActionsMenu extends StatelessWidget {
  const _CvActionsMenu({
    required this.cv,
    required this.onEdit,
    required this.onPreview,
    required this.onRename,
    required this.onDuplicate,
    required this.onBackup,
    required this.onDelete,
  });

  final CvModel cv;
  final ValueChanged<CvModel> onEdit;
  final ValueChanged<CvModel> onPreview;
  final ValueChanged<CvModel> onRename;
  final ValueChanged<CvModel> onDuplicate;
  final ValueChanged<CvModel> onBackup;
  final ValueChanged<CvModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tr('Tùy chọn', 'Options'),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit(cv);
            break;
          case 'preview':
            onPreview(cv);
            break;
          case 'rename':
            onRename(cv);
            break;
          case 'duplicate':
            onDuplicate(cv);
            break;
          case 'backup':
            onBackup(cv);
            break;
          case 'delete':
            onDelete(cv);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(tr('Chỉnh sửa', 'Edit'))),
        PopupMenuItem(
          value: 'preview',
          child: Text(tr('Xem trước PDF', 'Preview PDF')),
        ),
        PopupMenuItem(value: 'rename', child: Text(tr('Đổi tên', 'Rename'))),
        PopupMenuItem(
          value: 'duplicate',
          child: Text(tr('Nhân bản', 'Duplicate')),
        ),
        PopupMenuItem(
          value: 'backup',
          child: Text(tr('Tạo bản sao dự phòng', 'Make a backup copy')),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Text(tr('Xoá hồ sơ', 'Delete CV')),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppTheme.primarySlate),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onPressed,
            style: AppTheme.createCvButton,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(action),
          ),
        ],
      ),
    );
  }
}

class _GuestBackupCard extends StatelessWidget {
  const _GuestBackupCard({required this.count, required this.onBackup});

  final int count;
  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('guest-backup-card'),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.indigoSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tr(
                '$count CV tạo khi chưa đăng nhập chưa được sao lưu vào tài khoản.',
                '$count CVs made before signing in are not backed up to your account yet.',
              ),
              style: const TextStyle(height: 1.35),
            ),
          ),
          TextButton(
            onPressed: onBackup,
            child: Text(tr('Sao lưu ngay', 'Back up now')),
          ),
        ],
      ),
    );
  }
}
