import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// One entry of the desktop sidebar.
class DesktopNavItem {
  const DesktopNavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

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
  });

  final List<DesktopNavItem> items;
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
        ),
        const VerticalDivider(width: 1, color: AppTheme.softBorder),
        Expanded(
          child: Column(
            children: [
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
              Expanded(child: child),
            ],
          ),
        ),
      ],
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
  });

  final List<DesktopNavItem> items;
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
            label: const Text('Tạo CV mới'),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _NavTile(
                item: items[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            ),
          const Spacer(),
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
                          accountName ?? 'Chưa đăng nhập',
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
