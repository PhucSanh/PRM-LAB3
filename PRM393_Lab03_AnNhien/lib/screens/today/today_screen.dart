import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/today_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

/// S03 Hôm nay – chủ: Khang (F3). Màn MẪU: chỉ vẽ state, mọi xử lý gọi ViewModel.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayViewModelProvider);
    final vm = ref.read(todayViewModelProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang tải việc hôm nay…'),
          UiError(:final message) => ErrorView(message: message, onRetry: vm.load),
          UiEmpty() => EmptyView(
              icon: Icons.event_available_outlined,
              title: 'Hôm nay chưa có việc',
              action: AppButton(label: 'Thêm việc', icon: Icons.add, onPressed: () => context.push('/today/add')),
            ),
          UiData(:final data) => _TodayList(data: data),
        },
      ),
    );
  }
}

class _TodayList extends ConsumerWidget {
  const _TodayList({required this.data});
  final TodayData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Row(children: [
          Expanded(child: Text('Chào Bác', style: t.headlineMedium)),
          TextButton.icon(onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined), label: const Text('Cài đặt')),
        ]),
        Text('Đã xong ${data.doneCount}/${data.total} việc', style: t.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        for (final task in data.tasks) ...[
          _TaskTile(task: task),
          const SizedBox(height: AppSpacing.betweenTargets),
        ],
        AppButton(label: 'Thêm việc', icon: Icons.add, kind: AppButtonKind.secondary, onPressed: () => context.push('/today/add')),
      ],
    );
  }
}

/// TODO(A – Sanh, F0): chuyển thành widget dùng chung `TaskCard` trong lib/widgets/.
class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final colors = HabitPalette.of(task.habitKey);
    final t = Theme.of(context).textTheme;
    final time = '${task.hour}:${task.minute.toString().padLeft(2, '0')}';
    return Semantics(
      button: true,
      label: '$time, ${task.title}, ${task.isDone ? 'đã xong' : 'chưa làm'}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/today/task/${task.id}'),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: colors.accent, width: 6))),
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Icons.spa, color: Colors.white, size: AppSizes.icon),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(time, style: t.bodyMedium),
                  Text(task.title, style: t.titleMedium),
                  Row(children: [
                    Icon(task.isDone ? Icons.check_circle : Icons.radio_button_unchecked, size: AppSizes.iconInChip),
                    const SizedBox(width: AppSpacing.xs),
                    Text(task.isDone ? 'Đã xong' : 'Chưa làm', style: t.labelMedium),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
