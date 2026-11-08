import 'read_aloud_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/account_view_model.dart';
import '../viewmodels/calm_feature_providers.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import 'task_widgets.dart';
import 'habit_widgets.dart';
import 'velora_parts.dart';

class VeloraGreeting extends ConsumerWidget {
  const VeloraGreeting({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    final name = profile?.displayName?.trim();
    const greeting = 'Chào ngày mới,';
    final text = Theme.of(context).textTheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(greeting,
            style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xs),
        Text(name == null || name.isEmpty ? 'Bác' : name,
            style: text.headlineMedium),
      ])),
      IconButton.filledTonal(
          tooltip: 'Hộp thông báo',
          onPressed: () => context.push('/inbox'),
          style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              shape:
                  const RoundedRectangleBorder(borderRadius: AppRadius.mdAll)),
          icon: const Icon(AppIcons.bell)),
    ]);
  }
}

class VeloraHomeDiscovery extends ConsumerWidget {
  const VeloraHomeDiscovery({super.key});
  String shortName(Habit h) => switch (h.key) {
        'move' => 'Vận động',
        'downshift' => 'Thư giãn',
        'family' => 'Gia đình',
        'purpose' => 'Ý nghĩa',
        'plant' => 'Ăn xanh',
        _ => h.name,
      };
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsListProvider);
    return habits.when(
        loading: () => const SizedBox(
            height: 120, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => TextButton.icon(
            onPressed: () => ref.invalidate(habitsListProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử tải lại thói quen')),
        data: (items) {
          if (items.isEmpty) return const SizedBox.shrink();
          final featured =
              items.where((h) => h.key == 'downshift').firstOrNull ??
                  items.first;
          final categories = [
            for (final key in ['move', 'downshift', 'family'])
              ...items.where((h) => h.key == key),
            ...items
                .where((h) => !['move', 'downshift', 'family'].contains(h.key)),
          ].take(3).toList();
          void open(Habit h) =>
              context.push('/activities/habits/${Uri.encodeComponent(h.key)}');
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VeloraFeaturedCard(
                    eyebrow: 'DÀNH CHO BÁC',
                    title: featured.name,
                    label: 'Khám phá',
                    onPressed: () => context.push('/activities/discover')),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(
                      child: Text('Nhịp sống an nhiên',
                          style: Theme.of(context).textTheme.titleSmall)),
                  TextButton(
                      onPressed: () => context.go('/activities?section=habits'),
                      child: const Text('Tất cả'))
                ]),
                const SizedBox(height: AppSpacing.sm),
                LayoutBuilder(builder: (context, box) {
                  final count = box.maxWidth < 300 ||
                          MediaQuery.textScalerOf(context).scale(20) > 28
                      ? 1
                      : 3;
                  return Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final (i, habit) in categories.indexed)
                      SizedBox(
                          width: (box.maxWidth - 12 * (count - 1)) / count,
                          child: Semantics(
                              label: habit.name,
                              onTap: () => open(habit),
                              button: true,
                              excludeSemantics: true,
                              child: VeloraCategoryTile(
                                  label: shortName(habit),
                                  icon: HabitStyle.iconOf(habit.key),
                                  tint: AppColors.categoryTints[i],
                                  onTap: () => open(habit)))),
                  ]);
                }),
              ]);
        });
  }
}

/// Compact actual-task surface, matching the reference's single horizontal row.
class VeloraScheduleCard extends StatelessWidget {
  const VeloraScheduleCard(
      {super.key, required this.task, required this.onTap});
  final TaskItem task;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    final time =
        '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}';
    return Material(
        color: colors.secondaryContainer,
        borderRadius: AppRadius.cardAll,
        child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.cardAll,
            child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: ReadAloudRegion(
                    inline: true,
                    child: Row(children: [
                      Container(
                          width: 48,
                          height: 56,
                          decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: AppRadius.mdAll),
                          child: Icon(HabitStyle.iconOf(task.habitKey),
                              color: colors.onPrimary)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(task.title,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                                '$time · ${task.durationMinutes} phút · ${task.status.label}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant)),
                          ])),
                    ])))));
  }
}
