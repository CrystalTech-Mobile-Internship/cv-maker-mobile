import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class UpcomingToolsRow extends StatelessWidget {
  const UpcomingToolsRow({
    super.key,
    required this.onOpenAts,
    required this.onOpenPro,
  });

  final VoidCallback onOpenAts;
  final VoidCallback onOpenPro;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToolTile(
            title: 'Chấm điểm ATS',
            subtitle: 'So khớp JD',
            icon: Icons.analytics_outlined,
            iconColor: AppTheme.brandIndigo,
            iconBackground: AppTheme.indigoSurface,
            onTap: onOpenAts,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolTile(
            title: 'Nâng cấp Pro',
            subtitle: 'VietQR • Mẫu VIP',
            icon: Icons.workspace_premium_rounded,
            iconColor: AppTheme.warningAmber,
            iconBackground: AppTheme.amberSurface,
            onTap: onOpenPro,
          ),
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.softBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
