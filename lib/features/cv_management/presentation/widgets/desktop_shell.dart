import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/i18n/app_language.dart';

/// One entry of the desktop sidebar.
class DesktopNavItem {
  const DesktopNavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A shortcut in the sidebar's tools list; opens another screen.
class DesktopToolLink {
  const DesktopToolLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.key,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Short tag such as "Miễn phí" or "AI".
  final String? badge;
  final Key? key;

  /// True for the tool whose page is open.
  final bool selected;
}

/// The four main sections, shared by the home screen and tool pages.
List<DesktopNavItem> get desktopDestinations => [
  DesktopNavItem(
    Icons.folder_copy_outlined,
    Icons.folder_copy_rounded,
    tr('CV của tôi', 'My CVs'),
  ),
  DesktopNavItem(
    Icons.palette_outlined,
    Icons.palette_rounded,
    tr('Mẫu CV', 'Templates'),
  ),
  DesktopNavItem(
    Icons.forum_outlined,
    Icons.forum_rounded,
    tr('Cộng đồng', 'Community'),
  ),
  DesktopNavItem(
    Icons.account_circle_outlined,
    Icons.account_circle_rounded,
    tr('Tài khoản', 'Account'),
  ),
];

/// Computer layout: fixed sidebar on the left, page header on top and the
/// page content below. Phones keep the bottom navigation instead.
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCreate,
    required this.title,
    required this.child,
    this.actions = const [],
    this.accountName,
    this.accountDetail,
    this.onAccount,
    this.tools = const [],
    this.showHeader = true,
  });

  /// Tool pages bring their own app bar, so they hide the shell header.
  final bool showHeader;
  final List<DesktopNavItem> items;
  final List<DesktopToolLink> tools;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;
  final String title;
  final List<Widget> actions;
  final Widget child;
  final String? accountName;
  final String? accountDetail;
  final VoidCallback? onAccount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Sidebar(
          items: items,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          onCreate: onCreate,
          accountName: accountName,
          accountDetail: accountDetail,
          onAccount: onAccount,
          tools: tools,
        ),
        const VerticalDivider(width: 1, color: AppTheme.softBorder),
        Expanded(
          child: Column(
            children: [
              if (showHeader)
                Container(
                  key: const Key('desktop-page-header'),
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.softBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              Expanded(
                child: _ContentEntrance(
                  // A new section or tool replays the entrance.
                  key: ValueKey(
                    '$selectedIndex/${tools.indexWhere((t) => t.selected)}',
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Short fade and lift for the content area only; the sidebar stays still.
class _ContentEntrance extends StatefulWidget {
  const _ContentEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<_ContentEntrance> createState() => _ContentEntranceState();
}

class _ContentEntranceState extends State<_ContentEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCreate,
    this.accountName,
    this.accountDetail,
    this.onAccount,
    this.tools = const [],
  });

  final List<DesktopNavItem> items;
  final List<DesktopToolLink> tools;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;
  final String? accountName;
  final String? accountDetail;
  final VoidCallback? onAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('desktop-sidebar'),
      width: 248,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  'assets/brand/logo.png',
                  width: 34,
                  height: 34,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Smart CV Maker',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const Key('desktop-create-cv'),
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(tr('Tạo CV mới', 'New CV')),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _NavTile(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                  ),
                if (tools.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                    child: Text(
                      tr('CÔNG CỤ', 'TOOLS'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                  for (final tool in tools)
                    _ToolTile(key: tool.key, tool: tool),
                ],
              ],
            ),
          ),
          const Divider(height: 24, color: AppTheme.softBorder),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onAccount,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppTheme.indigoSurface,
                    child: Text(
                      (accountName?.trim().isNotEmpty ?? false)
                          ? accountName!.trim()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brandIndigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountName ?? tr('Chưa đăng nhập', 'Not signed in'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        if (accountDetail != null)
                          Text(
                            accountDetail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
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
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({super.key, required this.tool});

  final DesktopToolLink tool;

  @override
  Widget build(BuildContext context) {
    final ai = tool.badge == 'AI';
    final selected = tool.selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppTheme.indigoSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppTheme.indigoSurface,
          onTap: tool.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  tool.icon,
                  size: 19,
                  color: selected ? AppTheme.brandIndigo : AppTheme.mutedText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tool.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected
                          ? AppTheme.brandIndigo
                          : AppTheme.primarySlate,
                    ),
                  ),
                ),
                if (tool.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ai ? AppTheme.indigoSurface : AppTheme.tealSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tool.badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ai
                            ? AppTheme.brandIndigo
                            : AppTheme.successGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final DesktopNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.brandIndigo : AppTheme.mutedText;
    return Material(
      color: selected ? AppTheme.indigoSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? AppTheme.brandIndigo
                        : AppTheme.primarySlate,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
