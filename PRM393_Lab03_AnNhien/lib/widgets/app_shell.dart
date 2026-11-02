import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_icons.dart';

/// Bottom nav 4 tab: Hôm nay · Lịch tuần · Thói quen · Gia đình (rule.md R-NAV-01).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (AppIcons.tabToday, 'Hôm nay'),
    (AppIcons.tabWeek, 'Lịch tuần'),
    (AppIcons.tabHabits, 'Thói quen'),
    (AppIcons.tabFamily, 'Gia đình'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        destinations: [
          for (final (icon, label) in _tabs) NavigationDestination(icon: Icon(icon), label: label, tooltip: label),
        ],
      ),
    );
  }
}
