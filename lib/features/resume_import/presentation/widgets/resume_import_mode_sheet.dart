import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

enum ResumeImportMode { onDevice, ai }

/// Lets the user choose between the free offline parser and AI extraction
/// after a DOCX/PDF has been read on the device.
Future<ResumeImportMode?> showResumeImportModeSheet(
  BuildContext context, {
  required String fileName,
  required int characterCount,
  required bool isSignedIn,
  required int aiCost,
}) {
  return showModalBottomSheet<ResumeImportMode>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đã đọc "$fileName"',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$characterCount ký tự được trích xuất ngay trên máy. Chọn cách bóc tách:',
              style: const TextStyle(color: AppTheme.mutedText),
            ),
            const SizedBox(height: 14),
            _ModeTile(
              key: const ValueKey('import-mode-ai'),
              icon: Icons.auto_awesome_outlined,
              title: 'Bóc tách bằng AI (khuyên dùng)',
              subtitle: isSignedIn
                  ? 'Nhận diện chính xác mục, thời gian và gạch đầu dòng. Tốn $aiCost lượt AI.'
                  : 'Cần đăng nhập. Tài khoản Free có lượt AI miễn phí mỗi ngày.',
              onTap: () => Navigator.pop(context, ResumeImportMode.ai),
            ),
            const SizedBox(height: 10),
            _ModeTile(
              key: const ValueKey('import-mode-local'),
              icon: Icons.phone_android_outlined,
              title: 'Bóc tách nhanh trên máy',
              subtitle:
                  'Miễn phí, không cần mạng, dữ liệu không rời thiết bị. Phù hợp CV bố cục đơn giản.',
              onTap: () => Navigator.pop(context, ResumeImportMode.onDevice),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.indigoSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.brandIndigo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
