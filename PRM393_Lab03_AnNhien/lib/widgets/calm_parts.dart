import 'read_aloud_region.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_spacing.dart';
import '../theme/app_icons.dart';
import 'botanical_scene.dart';

class CalmPageHeader extends StatelessWidget {
  const CalmPageHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.art = false,
      this.actions = true});
  final String title;
  final String? subtitle;
  final bool art, actions;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineMedium))),
        if (actions) ...[
          IconButton(
              tooltip: 'Hộp thông báo',
              onPressed: () => context.push('/inbox'),
              icon: const Icon(AppIcons.bell)),
          IconButton(
              tooltip: 'Cài đặt',
              onPressed: () => context.push('/settings'),
              icon: const Icon(AppIcons.settings)),
        ],
      ]),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle!,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
      if (art) ...[
        const SizedBox(height: AppSpacing.lg),
        const BotanicalScene(height: 140, branch: false),
      ],
    ]);
  }
}

/// A list surface with no stacked cards or colored side rails.
class CalmListRow extends StatelessWidget {
  const CalmListRow(
      {super.key,
      required this.title,
      this.subtitle,
      this.icon = AppIcons.tabHabits,
      this.onTap,
      this.trailing});
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.cardAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
            child: ReadAloudRegion(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  ExcludeSemantics(
                      child: Container(
                          width: AppSizes.habitIcon,
                          height: AppSizes.habitIcon,
                          decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: AppRadius.mdAll),
                          child: Icon(icon,
                              color: colors.onPrimaryContainer,
                              size: AppSizes.icon))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(subtitle!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                        if (trailing != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          trailing!,
                        ],
                      ])),
                  if (onTap != null) const Icon(AppIcons.chevronRight),
                ])),
          ),
        ));
  }
}
