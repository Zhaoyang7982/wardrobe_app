import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

/// 主导航规格（底部栏与宽屏侧栏共用，避免分叉维护）
class _NavDest {
  const _NavDest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const List<_NavDest> _kNavDestinations = [
  _NavDest(Icons.checkroom_outlined, Icons.checkroom, '衣橱'),
  _NavDest(Icons.style_outlined, Icons.style, '搭配'),
  _NavDest(Icons.calendar_month_outlined, Icons.calendar_month, '日历'),
  _NavDest(Icons.bar_chart_outlined, Icons.bar_chart, '统计'),
  _NavDest(Icons.person_outline, Icons.person, '我的'),
];

/// 主框架：窄屏底部 [NavigationBar]；宽屏（≥900）左侧 [NavigationRail]。
/// 各 Tab 子栈仍由 [StatefulNavigationShell] 托管。
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppConstants.layoutDesktopMinWidth;

    if (useRail) {
      final theme = Theme.of(context);
      return Scaffold(
        body: Row(
          children: [
            NavigationRailTheme(
              data: NavigationRailThemeData(
                backgroundColor: theme.colorScheme.surfaceContainerLow,
                indicatorColor: theme.colorScheme.primaryContainer,
                selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
                selectedLabelTextStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              child: NavigationRail(
                extended: false,
                labelType: NavigationRailLabelType.all,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: navigationShell.goBranch,
                destinations: [
                  for (final d in _kNavDestinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          for (final d in _kNavDestinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
