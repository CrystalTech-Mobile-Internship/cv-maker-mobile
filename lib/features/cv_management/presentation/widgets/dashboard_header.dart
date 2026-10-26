import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.isSignedIn,
    this.displayName,
  });

  final bool isSignedIn;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final name = displayName?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSignedIn && name != null && name.isNotEmpty
              ? 'Chào $name,'
              : 'Chào mừng bạn,',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isSignedIn
                  ? Icons.cloud_done_rounded
                  : Icons.person_outline_rounded,
              size: 15,
              color: isSignedIn ? AppTheme.successGreen : AppTheme.mutedText,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isSignedIn ? 'Đã kết nối tài khoản' : 'Đang dùng chế độ khách',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
