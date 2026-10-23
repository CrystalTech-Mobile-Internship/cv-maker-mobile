import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class CloudSyncCard extends StatelessWidget {
  const CloudSyncCard({
    super.key,
    required this.isSignedIn,
    required this.localCount,
    required this.pendingCount,
    required this.isSyncing,
    required this.onSync,
    required this.onLogin,
    this.lastSyncedAt,
  });

  final bool isSignedIn;
  final int localCount;
  final int pendingCount;
  final bool isSyncing;
  final VoidCallback onSync;
  final VoidCallback onLogin;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSignedIn
                      ? Icons.cloud_sync_rounded
                      : Icons.cloud_off_rounded,
                  color: AppTheme.brandIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSignedIn ? 'Đồng bộ CV' : 'Sao lưu lên Cloud',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSignedIn
                          ? '$localCount CV đã lưu • $pendingCount chờ đồng bộ'
                          : 'Đăng nhập để sao lưu CV đang có trên máy.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSyncing ? null : (isSignedIn ? onSync : onLogin),
              icon: isSyncing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isSignedIn ? Icons.sync_rounded : Icons.login_rounded),
              label: Text(
                isSyncing
                    ? 'Đang đồng bộ...'
                    : isSignedIn
                    ? 'Đồng bộ ngay'
                    : 'Đăng nhập để đồng bộ',
              ),
            ),
          ),
          if (lastSyncedAt != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Lần cuối ${_formatTime(lastSyncedAt!)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
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
