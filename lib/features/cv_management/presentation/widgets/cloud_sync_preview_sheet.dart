import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../cv_editor/domain/models/cloud_sync_preview.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/i18n/app_language.dart';

/// Modal bottom sheet presenting a pre-sync preview to the user.
///
/// Ensures transparent visibility into uploads, downloads, deletions, and conflicts
/// before initiating any synchronization with Supabase Cloud.
class CloudSyncPreviewSheet extends StatelessWidget {
  const CloudSyncPreviewSheet({
    super.key,
    required this.preview,
    required this.onConfirmSync,
    required this.onExportBackup,
  });

  final CloudSyncPreview preview;
  final VoidCallback onConfirmSync;
  final VoidCallback onExportBackup;

  static Future<bool?> show(
    BuildContext context, {
    required CloudSyncPreview preview,
    required VoidCallback onExportBackup,
  }) {
    return showAppSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CloudSyncPreviewSheet(
        preview: preview,
        onConfirmSync: () => Navigator.of(ctx).pop(true),
        onExportBackup: onExportBackup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag pill
              AppSheetHandle(margin: const EdgeInsets.only(bottom: 16)),

              // Title and icon row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.indigoSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
                      color: AppTheme.brandIndigo,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Xem trước khi đồng bộ', 'Preview sync'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('Những gì sẽ thay đổi', 'What will change'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: tr('Đóng', 'Close'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Backend and Account target banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          size: 16,
                          color: AppTheme.brandIndigo,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            preview.userEmail.isEmpty
                                ? tr('Người dùng', 'User')
                                : preview.userEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryNavy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.brandIndigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            preview.targetBackend,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandIndigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (preview.hasError) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          preview.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Metrics 2x2 Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.upload_rounded,
                      color: Colors.blue.shade700,
                      bgColor: Colors.blue.shade50,
                      label: tr('Tải lên tài khoản', 'Upload to account'),
                      count: preview.pendingUploadCount,
                      hint: tr('Bản sửa trên máy', 'Edited on this device'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.download_rounded,
                      color: Colors.teal.shade700,
                      bgColor: Colors.teal.shade50,
                      label: tr('Tải về máy', 'Download to device'),
                      count: preview.pendingDownloadCount,
                      hint: tr(
                        'Bản trên tài khoản mới hơn',
                        'Account copy is newer',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.sync_problem_rounded,
                      color: preview.conflictCount > 0
                          ? Colors.orange.shade800
                          : Colors.grey.shade600,
                      bgColor: preview.conflictCount > 0
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                      label: tr('Xung đột', 'Conflict'),
                      count: preview.conflictCount,
                      hint: tr(
                        'Sửa ở cả hai nơi — giữ bản mới hơn',
                        'Edited in both places — keep the newer one',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.delete_outline_rounded,
                      color: preview.pendingDeletionCount > 0
                          ? Colors.red.shade700
                          : Colors.grey.shade600,
                      bgColor: preview.pendingDeletionCount > 0
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                      label: tr('Xóa trên tài khoản', 'Delete from account'),
                      count: preview.pendingDeletionCount,
                      hint: tr('Theo lệnh đã xóa', 'Deleted on this device'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Local safety notice
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr(
                          'CV trên máy luôn được giữ an toàn, kể cả khi đồng bộ gặp lỗi.',
                          'CVs on this device stay safe even if syncing fails.',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              OutlinedButton.icon(
                onPressed: onExportBackup,
                icon: const Icon(Icons.backup_outlined, size: 18),
                label: Text(
                  tr(
                    'Lưu một bản sao ra máy trước',
                    'Save a copy to this device first',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.brandIndigo,
                  side: const BorderSide(color: AppTheme.brandIndigo),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              FilledButton.icon(
                key: const Key('confirm-cloud-sync-btn'),
                onPressed: preview.hasError ? null : onConfirmSync,
                icon: const Icon(Icons.sync_rounded),
                label: Text(
                  preview.hasDeletionsOrOverwrites
                      ? tr('Đồng bộ ngay', 'Sync now')
                      : tr('Bắt đầu đồng bộ', 'Start sync'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: preview.hasDeletionsOrOverwrites
                      ? Colors.orange.shade800
                      : AppTheme.brandIndigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
    required int count,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
