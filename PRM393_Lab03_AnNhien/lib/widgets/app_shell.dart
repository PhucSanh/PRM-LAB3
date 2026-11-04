import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/suggestion/suggestion_popup_listener.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Bottom nav 4 tab: Hôm nay · Lịch tuần · Thói quen · Gia đình (rule.md R-NAV-01; Figma S03 › Nav `1:451`).
/// Nền trắng, viền trên; 4 ô rộng đều cách nhau 20; mỗi ô icon 32 + nhãn 20 đậm **2 dòng** ("Hôm / nay") để
/// 4 nhãn luôn cùng kiểu; ô đang chọn có nền `primaryContainer` bo 12 bọc cả icon lẫn nhãn, chữ `primary`.
/// Chữ phóng to quá thì nhãn thu nhỏ vừa ô (không cắt "…", không vỡ chữ giữa từ).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  /// (icon, nhãn hiển thị 2 dòng, nhãn đọc cho TalkBack)
  static const _tabs = [
    (AppIcons.tabToday, 'Hôm\nnay', 'Hôm nay'),
    (AppIcons.tabWeek, 'Lịch\ntuần', 'Lịch tuần'),
    (AppIcons.tabHabits, 'Thói\nquen', 'Thói quen'),
    (AppIcons.tabFamily, 'Gia\nđình', 'Gia đình'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Không có AppBar riêng: "Tài khoản" gộp vào "Cài đặt" của từng tab
    // (Hôm nay → Cài đặt → Tài khoản). TODO(Sanh, F8): S10 có lối vào /account.
    return Scaffold(
      // F12: popup G10 / G11 "có gợi ý mới" – chỉ hiện ở tab Hôm nay, một lần (người dùng đồng ý 04/11).
      body: SuggestionPopupListener(
        active: navigationShell.currentIndex == 0,
        child: navigationShell,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.navBar),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
              child: Row(children: [
                for (final (i, (icon, label, spoken)) in _tabs.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.betweenTargets),
                  Expanded(
                    child: _NavTab(
                      icon: icon,
                      label: label,
                      semanticLabel: spoken,
                      selected: i == navigationShell.currentIndex,
                      onTap: () => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: AppSizes.icon, color: color),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
