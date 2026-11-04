import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task_item.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_icons.dart';
import '../../widgets/habit_widgets.dart';
import '../../viewmodels/today_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/undo_snackbar.dart';

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
          UiError(:final message) =>
            ErrorView(message: message, onRetry: vm.load),
          UiEmpty() => const _TodayList(data: TodayData(tasks: [])),
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
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final scheme = theme.colorScheme;
    final next = data.next;
    final now = DateTime.now();
    final weekday = const [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ nhật'
    ][now.weekday - 1];
    final quickActionStyle = TextButton.styleFrom(
      textStyle: t.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    );
    return RefreshIndicator(
      onRefresh: ref.read(todayViewModelProvider.notifier).load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          Text('Chào Bác', style: t.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('$weekday, ${now.day}/${now.month}',
              style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          LayoutBuilder(builder: (context, box) {
            final width = MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? box.maxWidth
                : (box.maxWidth - AppSpacing.betweenTargets) / 2;
            return Wrap(
                spacing: AppSpacing.betweenTargets,
                runSpacing: AppSpacing.xs,
                children: [
                  SizedBox(
                      width: width,
                      child: TextButton.icon(
                          style: quickActionStyle,
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(AppIcons.settings,
                              size: AppSizes.iconInChip),
                          label: const Text('Cài đặt'))),
                  SizedBox(
                      width: width,
                      child: TextButton.icon(
                          style: quickActionStyle,
                          onPressed: () => context.push('/inbox'),
                          icon: const Icon(Icons.notifications_rounded,
                              size: AppSizes.iconInChip),
                          label: const Text('Thông báo'))),
                ]);
          }),
          const SizedBox(height: AppSpacing.lg),
          if (data.total == 0)
            const EmptyView(
              icon: Icons.event_available_rounded,
              title: 'Hôm nay chưa có việc',
              message: 'Bắt đầu nhẹ nhàng với một hoạt động Bác thích.',
            ),
          if (data.total > 0)
            SectionCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Đã xong ${data.doneCount}/${data.total} việc',
                        style: t.titleSmall),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: AppRadius.smAll,
                      child: LinearProgressIndicator(
                        value:
                            data.total == 0 ? 0 : data.doneCount / data.total,
                        minHeight: 10,
                        backgroundColor: scheme.primaryContainer,
                        semanticsLabel:
                            'Tiến độ hôm nay: ${data.doneCount} trên ${data.total} việc',
                      ),
                    ),
                  ]),
            ),
          const SizedBox(height: AppSpacing.xl),
          if (next != null) ...[
            Semantics(
                header: true,
                child: Text('Việc tiếp theo', style: t.titleLarge)),
            const SizedBox(height: AppSpacing.md),
            _TaskTile(task: next, featured: true),
            const SizedBox(height: AppSpacing.xl),
          ],
          AppButton(
              label: 'Thêm việc',
              icon: Icons.add,
              kind:
                  data.total == 0 ? AppButtonKind.primary : AppButtonKind.tonal,
              onPressed: () => context.push('/today/add')),
          if (data.tasks
              .any((task) => task.id != next?.id && !task.isDone)) ...[
            const SizedBox(height: AppSpacing.xl),
            Semantics(
                header: true,
                child: Text('Các việc còn lại', style: t.titleLarge)),
            const SizedBox(height: AppSpacing.md),
            for (final task in data.tasks
                .where((task) => task.id != next?.id && !task.isDone)) ...[
              _TaskTile(task: task),
              const SizedBox(height: AppSpacing.betweenTargets),
            ],
          ],
          if (data.doneCount > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Đã hoàn thành (${data.doneCount})',
                  style: t.titleSmall),
              children: [
                for (final task in data.tasks.where((task) => task.isDone)) ...[
                  _TaskTile(task: task),
                  const SizedBox(height: AppSpacing.base),
                ],
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerStatefulWidget {
  const _TaskTile({required this.task, this.featured = false});
  final TaskItem task;
  final bool featured;

  @override
  ConsumerState<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<_TaskTile> {
  bool _busy = false;

  Future<void> _complete() async {
    if (_busy) return;
    setState(() => _busy = true);
    final vm = ref.read(todayViewModelProvider.notifier);
    final task = widget.task;
    final messenger = ScaffoldMessenger.of(context);
    final pageContext =
        context.findAncestorStateOfType<ScaffoldState>()!.context;
    try {
      await vm.markDone(task.id);
      if (!pageContext.mounted) return;
      showUndoSnackbar(pageContext, title: 'Đã hoàn thành: ${task.title}',
          onUndo: () async {
        try {
          await vm.undo(task.id, previousStatus: task.status);
        } catch (_) {
          messenger.showSnackBar(const SnackBar(
              content: Text('Chưa hoàn tác được. Bác thử lại nhé.')));
        }
      });
    } catch (_) {
      if (pageContext.mounted) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Chưa lưu được. Bác thử lại nhé.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final time =
        '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}';
    final status = switch (task.status) {
      TaskStatus.done => 'Đã xong',
      TaskStatus.pending => 'Chưa làm',
      TaskStatus.postponed => 'Đã dời giờ',
      TaskStatus.skipped => 'Đã bỏ qua',
    };
    return Card(
      color: widget.featured ? scheme.secondaryContainer : scheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(time,
                    style: t.headlineMedium?.copyWith(color: scheme.primary)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      switch (task.status) {
                        TaskStatus.done => AppIcons.checkCircle,
                        TaskStatus.pending => AppIcons.clock,
                        TaskStatus.postponed => AppIcons.later,
                        TaskStatus.skipped => AppIcons.statusSkipped,
                      },
                      color: scheme.primary,
                      size: AppSizes.iconInChip),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: Text(status, style: t.bodyMedium)),
                ]),
              ]),
          const SizedBox(height: AppSpacing.sm),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ExcludeSemantics(child: HabitBadge(habitKey: task.habitKey)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(task.title, style: t.titleLarge)),
          ]),
          const SizedBox(height: AppSpacing.base),
          if (task.status == TaskStatus.pending ||
              task.status == TaskStatus.postponed)
            AppButton(
                label: 'Đã làm xong',
                icon: Icons.check,
                busy: _busy,
                wrapLabel: true,
                kind: widget.featured
                    ? AppButtonKind.primary
                    : AppButtonKind.tonal,
                onPressed: _complete),
          TextButton.icon(
            onPressed: () => context.push('/today/task/${task.id}'),
            icon: const Icon(Icons.arrow_forward, size: AppSizes.iconInChip),
            label: const Text('Xem chi tiết'),
          ),
        ]),
      ),
    );
  }
}
