import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom nav 4 tab: Hôm nay · Lịch tuần · Thói quen · Gia đình (rule.md R-NAV-01).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (Icons.wb_sunny_outlined, 'Hôm nay'),
    (Icons.calendar_month_outlined, 'Lịch tuần'),
    (Icons.eco_outlined, 'Thói quen'),
    (Icons.people_outline, 'Gia đình'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, actions: [
        TextButton.icon(
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Tài khoản')),
      ]),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i,
            initialLocation: i == navigationShell.currentIndex),
        destinations: [
          for (final (icon, label) in _tabs)
            NavigationDestination(
                icon: Icon(icon), label: label, tooltip: label),
        ],
      ),
    );
  }
}
