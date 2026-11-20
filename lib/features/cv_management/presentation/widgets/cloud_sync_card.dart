import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/app_language.dart';
import 'side_panel_card.dart';

/// Account sync status with one action: sync now, or sign in.
class CloudSyncCard extends StatelessWidget {
  const CloudSyncCard({
    super.key,
    required this.isSignedIn,
    required this.localCount,
    required this.pendingCount,
    required this.backendLabel,
    required this.isSyncing,
    required this.onSync,
    required this.onLogin,
    this.lastSyncedAt,
  });

  final bool isSignedIn;
  final int localCount;
  final int pendingCount;

  /// Kept for callers; server names are not shown to users.
  final String backendLabel;
  final bool isSyncing;
  final VoidCallback onSync;
  final VoidCallback onLogin;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final status = !isSignedIn
        ? tr(
            'Đăng nhập để lưu CV vào tài khoản.',
            'Sign in to save your CVs to your account.',
          )
        : pendingCount == 0
        ? tr('$localCount CV • Đã đồng bộ', '$localCount CVs • Up to date')
        : tr(
            '$localCount CV • $pendingCount chờ đồng bộ',
            '$localCount CVs • $pendingCount waiting',
          );
    return SidePanelCard(
      title: tr('Đồng bộ', 'Sync'),
      subtitle: status,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: isSyncing ? null : (isSignedIn ? onSync : onLogin),
            icon: isSyncing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isSignedIn ? Icons.sync_rounded : Icons.login_rounded,
                    size: 18,
                  ),
            label: Text(
              isSyncing
                  ? tr('Đang đồng bộ...', 'Syncing...')
                  : isSignedIn
                  ? tr('Đồng bộ ngay', 'Sync now')
                  : tr('Đăng nhập để đồng bộ', 'Sign in to sync'),
            ),
          ),
          if (isSignedIn && lastSyncedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              tr(
                'Lần cuối ${_formatTime(lastSyncedAt!)}',
                'Last synced ${_formatTime(lastSyncedAt!)}',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')} '
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }
}
