import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../viewmodels/calm_feature_providers.dart';
import '../../widgets/calm_parts.dart';
import '../../widgets/velora_parts.dart';
import '../../widgets/app_button.dart';
import '../../widgets/botanical_scene.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/state_views.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key, this.section = 'explore'});
  final String section;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = const ['explore', 'saved', 'habits'].contains(section)
        ? section
        : 'explore';
    return Scaffold(
        body: SafeArea(
            child: ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        const CalmPageHeader(
            title: 'Hoạt động',
            subtitle: 'Dành thời gian cho những điều mình yêu thích.'),
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final entry in const {
                'explore': 'Khám phá',
                'saved': 'Đã lưu',
                'habits': 'Thói quen'
              }.entries)
                Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                        label: Text(entry.value),
                        selected: selected == entry.key,
                        onSelected: (_) =>
                            context.go('/activities?section=${entry.key}'))),
            ])),
        const SizedBox(height: AppSpacing.lg),
        if (selected != 'saved')
          ref.watch(habitsListProvider).when(
                loading: () =>
                    const LoadingView(message: 'Đang tải thói quen…'),
                error: (_, __) => ErrorView(
                    message: 'Chưa thể tải thói quen.',
                    onRetry: () => ref.invalidate(habitsListProvider)),
                data: (habits) => habits.isEmpty
                    ? const EmptyView(
                        icon: AppIcons.tabHabits,
                        title: 'Chưa có nhóm thói quen',
                        message:
                            'Các nhóm thói quen sẽ xuất hiện khi thư viện được cập nhật.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            VeloraFeaturedCard(
                                eyebrow: 'MỖI NGÀY',
                                title: habits.first.name,
                                label: 'Xem',
                                onPressed: () => context.push(
                                    '/activities/habits/${Uri.encodeComponent(habits.first.key)}')),
                            const SizedBox(height: 24),
                            LayoutBuilder(builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 340 &&
                                      MediaQuery.textScalerOf(context)
                                              .scale(20) <=
                                          26
                                  ? 3
                                  : 1;
                              return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (var i = 0;
                                        i < habits.take(3).length;
                                        i++)
                                      SizedBox(
                                          width: (constraints.maxWidth -
                                                  12 * (columns - 1)) /
                                              columns,
                                          child: VeloraCategoryTile(
                                              label: habits[i].name,
                                              icon: HabitStyle.iconOf(
                                                  habits[i].key),
                                              tint: AppColors.categoryTints[i],
                                              onTap: () => context.push(
                                                  '/activities/habits/${Uri.encodeComponent(habits[i].key)}'))),
                                  ]);
                            }),
                            const SizedBox(height: 28),
                            Text('Các nhóm thói quen',
                                style: Theme.of(context).textTheme.titleLarge),
                            for (final habit in habits) ...[
                              CalmListRow(
                                  title: habit.name,
                                  subtitle: habit.description,
                                  icon: HabitStyle.iconOf(habit.key),
                                  onTap: () => context.push(
                                      '/activities/habits/${Uri.encodeComponent(habit.key)}')),
                              const Divider(height: 1),
                            ]
                          ]),
              )
        else ...[
          const BotanicalScene(height: 210, round: true, branch: false),
          const SizedBox(height: AppSpacing.lg),
          EmptyView(
              icon: selected == 'saved'
                  ? Icons.bookmark_rounded
                  : Icons.explore_rounded,
              title: selected == 'saved'
                  ? 'Thư viện đã lưu chưa khả dụng'
                  : 'Khám phá đang được chuẩn bị',
              message: selected == 'saved'
                  ? 'Phiên bản hiện tại chưa hỗ trợ lưu hoạt động. Bạn có thể xem các nhóm thói quen để bắt đầu.'
                  : 'Phiên bản hiện tại chưa có danh mục khám phá. Các nhóm thói quen đã có sẵn để bạn tìm hiểu.',
              action: AppButton(
                  label: 'Xem Thói quen',
                  icon: AppIcons.repeat,
                  kind: AppButtonKind.secondary,
                  onPressed: () => context.go('/activities?section=habits'))),
        ],
      ],
    )));
  }
}

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitKey});
  final String habitKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
        body: SafeArea(
            child: ref.watch(habitDetailProvider(habitKey)).when(
                  loading: () =>
                      const LoadingView(message: 'Đang tải thói quen…'),
                  error: (_, __) => ErrorView(
                      message: 'Chưa thể tải thói quen.',
                      onRetry: () =>
                          ref.invalidate(habitDetailProvider(habitKey))),
                  data: (habit) => habit == null
                      ? const EmptyView(
                          icon: AppIcons.tabHabits,
                          title: 'Nội dung này không còn khả dụng.')
                      : VeloraDetailBody(
                          footer: AppButton(
                              label: 'Chọn hoạt động để lên lịch',
                              icon: AppIcons.tabWeek,
                              onPressed: () => context.push('/today/add')),
                          onBack: () => context.canPop()
                              ? context.pop()
                              : context.go('/activities?section=habits'),
                          children: [
                              Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: HabitBadge(habitKey: habit.key)),
                              const SizedBox(height: AppSpacing.base),
                              Text(habit.name, style: text.headlineMedium),
                              const SizedBox(height: AppSpacing.base),
                              Text(habit.description, style: text.bodyLarge),
                              const SizedBox(height: AppSpacing.xl),
                              Text('Bắt đầu từ một việc nhỏ',
                                  style: text.titleLarge),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                  'Bạn có thể chọn hoạt động phù hợp và đặt giờ trong lịch của mình.',
                                  style: text.bodyMedium),
                              const SizedBox(height: AppSpacing.lg),
                            ]),
                )));
  }
}
