import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_language.dart';
import 'desktop_shell.dart';

/// Tools listed under the sidebar, shared by the home screen and the tool
/// pages so the sidebar looks the same everywhere. [current] is the route
/// of the open tool, highlighted in the list.
List<DesktopToolLink> desktopToolLinks(
  BuildContext context, {
  required bool isAdmin,
  String? current,
  int adminWaiting = 0,
}) {
  DesktopToolLink link(
    String key,
    String route,
    IconData icon,
    String label, {
    String? badge,
  }) => DesktopToolLink(
    key: Key(key),
    icon: icon,
    label: label,
    badge: badge,
    selected: route == current,
    onTap: () {
      if (route != current) context.go(route);
    },
  );

  return [
    link(
      'tool-ats',
      '/ats-scorer',
      Icons.analytics_outlined,
      tr('Chấm điểm CV', 'Score my CV'),
      badge: tr('Miễn phí', 'Free'),
    ),
    link(
      'tool-job-tracker',
      '/job-tracker',
      Icons.work_history_outlined,
      tr('Theo dõi ứng tuyển', 'Job tracker'),
      badge: tr('Miễn phí', 'Free'),
    ),
    link(
      'tool-interview',
      '/interview-practice',
      Icons.record_voice_over_outlined,
      tr('Luyện phỏng vấn', 'Interview practice'),
      badge: 'AI',
    ),
    link(
      'tool-chat-cv',
      '/ai-interview',
      Icons.chat_bubble_outline_rounded,
      tr('Trò chuyện tạo CV', 'Chat to build a CV'),
      badge: 'AI',
    ),
    link(
      'tool-pro',
      '/upgrade-pro',
      Icons.workspace_premium_outlined,
      tr('Nâng cấp Pro', 'Upgrade to Pro'),
    ),
    if (isAdmin) ...[
      link(
        'tool-admin',
        '/admin',
        Icons.support_agent_outlined,
        tr('Hỗ trợ người dùng', 'User support'),
        badge: adminWaiting > 0 ? '$adminWaiting' : null,
      ),
      link(
        'tool-admin-payments',
        '/admin/payments',
        Icons.receipt_long_outlined,
        tr('Thanh toán', 'Payments'),
      ),
    ] else
      link(
        'tool-support',
        '/support',
        Icons.headset_mic_outlined,
        tr('Hỗ trợ', 'Support'),
      ),
  ];
}
