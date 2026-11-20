import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_language.dart';
import 'side_panel_card.dart';

/// Other tools, listed as simple lines in one card.
class UpcomingToolsRow extends StatelessWidget {
  const UpcomingToolsRow({
    super.key,
    required this.onOpenAts,
    required this.onOpenPro,
    this.onPractice,
  });

  final VoidCallback onOpenAts;
  final VoidCallback onOpenPro;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) {
    return SidePanelCard(
      title: tr('Công cụ', 'Tools'),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Column(
        children: [
          SidePanelLink(
            icon: Icons.analytics_outlined,
            title: tr('Chấm điểm CV', 'Score my CV'),
            subtitle: tr(
              'So với tin tuyển dụng · miễn phí',
              'Against a job posting · free',
            ),
            onTap: onOpenAts,
          ),
          SidePanelLink(
            key: const ValueKey('open-job-tracker'),
            icon: Icons.work_history_outlined,
            title: tr('Theo dõi ứng tuyển', 'Job tracker'),
            subtitle: tr(
              'Việc đã nộp, lịch phỏng vấn',
              'Applications and interviews',
            ),
            onTap: () => GoRouter.of(context).push('/job-tracker'),
          ),
          if (onPractice != null)
            SidePanelLink(
              key: const ValueKey('open-interview-practice'),
              icon: Icons.record_voice_over_outlined,
              title: tr('Luyện phỏng vấn', 'Interview practice'),
              subtitle: tr('Từ 1 lượt AI', 'From 1 AI use'),
              onTap: onPractice!,
            ),
          SidePanelLink(
            icon: Icons.workspace_premium_outlined,
            title: tr('Nâng cấp Pro', 'Upgrade to Pro'),
            subtitle: tr(
              'Thêm mẫu, phông chữ và lượt AI',
              'More templates, fonts and AI uses',
            ),
            onTap: onOpenPro,
          ),
        ],
      ),
    );
  }
}
