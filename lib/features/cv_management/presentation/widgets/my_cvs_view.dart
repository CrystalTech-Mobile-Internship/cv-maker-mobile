import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../cv_editor/domain/models/cv_model.dart';
import '../../../cv_editor/domain/models/cv_template.dart';
import '../../../cv_editor/domain/services/cv_completion_service.dart';
import 'cloud_sync_card.dart';
import 'cv_completion_sheet.dart';
import 'cv_library_section.dart';
import 'dashboard_header.dart';
import 'ai_assistant_card.dart';
import 'local_data_tools_card.dart';
import 'template_thumbnail.dart';
import 'upcoming_tools_row.dart';

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
    return ResponsiveLayoutBuilder(
      mobile: (context, constraints) => _content(context, isDesktop: false),
      desktop: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _content(context, isDesktop: true),
        ),
      ),
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
        104,
      ),
      children: [
        DashboardHeader(isSignedIn: isSignedIn, displayName: displayName),
        const SizedBox(height: 20),
        _sectionHeader(context, cvs.length),
        const SizedBox(height: 14),
        cvsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _MessageCard(
            icon: Icons.error_outline_rounded,
            title: 'Không thể tải danh sách hồ sơ',
            message: error.toString(),
            action: 'Thử lại',
            onPressed: onRetry,
          ),
          data: (items) {
            if (items.isEmpty) {
              return _MessageCard(
                icon: Icons.note_add_outlined,
                title: 'Chưa có hồ sơ CV nào',
                message: 'Chọn một mẫu phù hợp và bắt đầu hồ sơ đầu tiên.',
                action: 'Tạo CV đầu tiên',
                onPressed: onCreate,
              );
            }
            return CvLibrarySection(
              items: items,
              isDesktop: isDesktop,
              itemBuilder: _cvCard,
            );
          },
        ),
        const SizedBox(height: 18),
        _ImportResumeCard(onImport: onImport),
        const SizedBox(height: 12),
        AiAssistantCard(
          onChat: onOpenAiInterview,
          onImport: onImport,
          onPractice: () => context.push('/interview-practice'),
        ),
        const SizedBox(height: 12),
        LocalDataToolsCard(onExport: onExportAll, onRestore: onRestoreBackup),
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
        const SizedBox(height: 12),
        UpcomingToolsRow(onOpenAts: onOpenAts, onOpenPro: onOpenPro),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'CV của tôi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
        ),
        IconButton.filledTonal(
          key: const Key('create-cv-header'),
          tooltip: 'Tạo CV mới',
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(AppTheme.brandIndigo),
            foregroundColor: WidgetStatePropertyAll(Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count hồ sơ',
            style: const TextStyle(
              color: AppTheme.brandIndigo,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
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
                              'Hoàn thiện $completion%',
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
                    label: const Text('Chỉnh sửa'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Xem trước PDF',
                  onPressed: () => onPreview(cv),
                  icon: const Icon(Icons.visibility_outlined),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  key: ValueKey('cv-checklist-${cv.id}'),
                  tooltip: 'Checklist hoàn thiện',
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

class _ImportResumeCard extends StatelessWidget {
  const _ImportResumeCard({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.tealSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('import-existing-resume'),
        onTap: onImport,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentTeal.withValues(alpha: 0.22),
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.accentTeal,
                child: Icon(Icons.upload_file_outlined),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhập CV Word hoặc PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Lấy nhanh thông tin, kiểm tra rồi đổi sang mẫu mới.',
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.accentTeal),
            ],
          ),
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
          isSynced ? 'Đã sao lưu' : 'Trên máy',
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
      tooltip: 'Tùy chọn',
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
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
        PopupMenuItem(value: 'preview', child: Text('Xem trước PDF')),
        PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
        PopupMenuItem(value: 'duplicate', child: Text('Nhân bản')),
        PopupMenuItem(value: 'backup', child: Text('Tạo bản sao dự phòng')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'delete', child: Text('Xoá hồ sơ')),
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
