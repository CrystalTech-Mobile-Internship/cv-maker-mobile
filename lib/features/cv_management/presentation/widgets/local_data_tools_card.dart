import 'package:flutter/material.dart';

import '../../../../core/i18n/app_language.dart';
import 'side_panel_card.dart';

/// Save all CVs to a file on this device, or bring them back from one.
class LocalDataToolsCard extends StatelessWidget {
  const LocalDataToolsCard({
    super.key,
    required this.onExport,
    required this.onRestore,
  });

  final VoidCallback onExport;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return SidePanelCard(
      title: tr('Sao lưu ra tệp', 'Backup file'),
      subtitle: tr(
        'Lưu tất cả CV vào một tệp trên máy.',
        'Save all CVs to a file on this device.',
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('export-all-cvs'),
              onPressed: onExport,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(tr('Xuất tệp', 'Export')),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('restore-cv-backup'),
              onPressed: onRestore,
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: Text(tr('Khôi phục', 'Restore')),
            ),
          ),
        ],
      ),
    );
  }
}
