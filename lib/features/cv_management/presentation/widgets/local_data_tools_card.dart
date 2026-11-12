import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.brandIndigo),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Sao lưu dữ liệu trên máy',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Xuất hoặc khôi phục CV bằng tệp sao lưu.',
            style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('export-all-cvs'),
                  onPressed: onExport,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Xuất sao lưu'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('restore-cv-backup'),
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_page_outlined, size: 18),
                  label: const Text('Khôi phục'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
