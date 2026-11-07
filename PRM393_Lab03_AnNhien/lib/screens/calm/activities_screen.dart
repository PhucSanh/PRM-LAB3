import '../../models/guided_activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_icons.dart';
import '../../viewmodels/calm_feature_providers.dart';
import '../../viewmodels/task_form_view_model.dart';
import '../../widgets/assistant_bubble.dart';
import '../../widgets/calm_parts.dart';
import '../../widgets/habit_photo_cards.dart';
import '../../widgets/velora_parts.dart';
import '../../widgets/app_button.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/state_views.dart';

/// Tab Khám phá: một trang duy nhất gồm hoạt động có hướng dẫn và các nhóm
/// thói quen (trước đây tách 2 chip "Khám phá" / "Thói quen" nhưng nội dung
/// gần như trùng nhau). [section] giữ lại để link cũ `?section=` vẫn mở được.
class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key, this.section = 'explore'});
  final String section;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        body: SafeArea(
            child: ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.screen,
          AppSpacing.screen, AssistantBubble.clearance),
      children: [
        const CalmPageHeader(
            title: 'Hoạt động',
            subtitle: 'Dành thời gian cho những điều mình yêu thích.'),
        const SizedBox(height: AppSpacing.lg),
        ref.watch(habitsListProvider).when(
              loading: () => const LoadingView(message: 'Đang tải thói quen…'),
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
                          HabitPhotoFeature(
                              habitKey: habits.first.key,
                              eyebrow: 'Gợi ý mỗi ngày',
                              title: habits.first.name,
                              subtitle: habits.first.description,
                              onTap: () =>
                                  _openHabit(context, habits.first.key)),
                          const SizedBox(height: AppSpacing.xl),
                          Text('Các nhóm thói quen',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.md),
                          // Lưới ảnh 2 cột; chữ phóng to thì 1 cột cho dễ đọc.
                          Builder(builder: (context) {
                            final columns =
                                MediaQuery.textScalerOf(context).scale(20) <= 26
                                    ? 2
                                    : 1;
                            final rest = habits.skip(1).toList();
                            return Column(children: [
                              for (var i = 0; i < rest.length; i += columns)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md),
                                  child: IntrinsicHeight(
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          for (var j = i;
                                              j < i + columns;
                                              j++) ...[
                                            if (j > i)
                                              const SizedBox(
                                                  width: AppSpacing.md),
                                            Expanded(
                                                child: j < rest.length
                                                    ? HabitPhotoTile(
                                                        habitKey: rest[j].key,
                                                        title: rest[j].name,
                                                        onTap: () => _openHabit(
                                                            context,
                                                            rest[j].key))
                                                    : const SizedBox()),
                                          ],
                                        ]),
                                  ),
                                ),
                            ]);
                          }),
                        ]),
            ),
        const SizedBox(height: AppSpacing.xl),
        Text('Một việc nhỏ cho hôm nay',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        const Text(
            'Có hướng dẫn ngắn, thời lượng rõ và có thể thêm ngay vào lịch.'),
        for (final activity in guidedActivities)
          CalmListRow(
              title: activity.title,
              subtitle: '${activity.minutes} phút · Xem cách làm',
              icon: HabitStyle.iconOf(activity.habitKey),
              onTap: () => context.push('/activities/guides/${activity.id}')),
      ],
    )));
  }

  static void _openHabit(BuildContext context, String key) =>
      context.push('/activities/habits/${Uri.encodeComponent(key)}');
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
                              label: 'Thêm vào lịch',
                              icon: AppIcons.tabWeek,
                              onPressed: () {
                                ref
                                    .read(taskFormViewModelProvider.notifier)
                                    .startCreate(
                                        day: ref.read(calendarDateProvider),
                                        activity: habit.key,
                                        title: habit.name);
                                context.push('/today/add/time');
                              }),
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
                              for (final activity in guidedActivities
                                  .where((a) => a.habitKey == habit.key))
                                CalmListRow(
                                    title: activity.title,
                                    subtitle:
                                        '${activity.minutes} phút · Có hướng dẫn',
                                    icon: HabitStyle.iconOf(habit.key),
                                    onTap: () => context.push(
                                        '/activities/guides/${activity.id}')),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                  'Bạn có thể chọn hoạt động phù hợp và đặt giờ trong lịch của mình.',
                                  style: text.bodyMedium),
                              const SizedBox(height: AppSpacing.lg),
                            ]),
                )));
  }
}
