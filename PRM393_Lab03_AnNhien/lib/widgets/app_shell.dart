import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/suggestion/suggestion_popup_listener.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Reference-style five-item navigation for Bác; caregiver keeps its work areas.
/// Explorer and habits share their existing branch, with explicit query state.
class AppShell extends StatelessWidget {
  const AppShell(
      {super.key,
      required this.navigationShell,
      this.caregiver = false,
      this.legacyToday = false});
  final StatefulNavigationShell navigationShell;
  final bool caregiver, legacyToday;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final uri = GoRouterState.of(context).uri;
    final destinations = caregiver
        ? [
            (AppIcons.tabWeek, 'Lịch'),
            (Icons.lightbulb_outline_rounded, 'Gợi ý'),
            (AppIcons.tabFamily, 'Gia đình'),
          ]
        : [
            (Icons.home_rounded, 'Trang chủ'),
            (Icons.search_rounded, 'Khám phá'),
            (Icons.timer_outlined, 'Thói quen'),
            (Icons.favorite_border_rounded, 'Gia đình'),
            (Icons.account_circle_outlined, 'Cá nhân'),
          ];
    final selected = caregiver
        ? navigationShell.currentIndex
        : switch (navigationShell.currentIndex) {
            1 => uri.queryParameters['section'] == 'habits' ||
                    uri.path.contains('/habits/')
                ? 2
                : 1,
            2 => 3,
            _ => 0,
          };
    void select(int index) {
      if (caregiver) {
        navigationShell.goBranch(index,
            initialLocation: index == navigationShell.currentIndex);
      } else {
        switch (index) {
          case 0:
            navigationShell.goBranch(0,
                initialLocation: navigationShell.currentIndex == 0);
          case 1:
            context.go('/activities?section=explore');
          case 2:
            context.go('/activities?section=habits');
          case 3:
            navigationShell.goBranch(2,
                initialLocation: navigationShell.currentIndex == 2);
          case 4:
            context.push('/account');
        }
      }
    }

    final content = caregiver
        ? navigationShell
        : SuggestionPopupListener(active: legacyToday, child: navigationShell);
    if (uri.path.startsWith('/activities/habits/') ||
        uri.path.startsWith('/calendar/task/') ||
        uri.path.startsWith('/today/task/')) {
      return content;
    }
    if (MediaQuery.sizeOf(context).width >= 600) {
      return Scaffold(
          body: Row(children: [
        SafeArea(
            child: NavigationRail(
                selectedIndex: selected,
                onDestinationSelected: select,
                labelType: NavigationRailLabelType.all,
                destinations: [
              for (final (icon, label) in destinations)
                NavigationRailDestination(icon: Icon(icon), label: Text(label))
            ])),
        const VerticalDivider(width: 1),
        Expanded(child: content)
      ]));
    }
    return Scaffold(
        body: content,
        bottomNavigationBar: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
                top: false,
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (index, (icon, label))
                              in destinations.indexed)
                            Expanded(
                                child: Semantics(
                                    button: true,
                                    selected: index == selected,
                                    label: label,
                                    onTap: () => select(index),
                                    excludeSemantics: true,
                                    child: InkWell(
                                        onTap: () => select(index),
                                        borderRadius: AppRadius.mdAll,
                                        child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                minHeight: AppSizes.minTarget),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal:
                                                            AppSpacing.xs),
                                                child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(icon,
                                                          color: index ==
                                                                  selected
                                                              ? colors.primary
                                                              : colors
                                                                  .onSurfaceVariant,
                                                          size: AppSizes.icon),
                                                      const SizedBox(
                                                          height:
                                                              AppSpacing.sm),
                                                      Text(label,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                  color: index ==
                                                                          selected
                                                                      ? colors
                                                                          .primary
                                                                      : colors
                                                                          .onSurfaceVariant)),
                                                    ])))))),
                        ])))));
  }
}
