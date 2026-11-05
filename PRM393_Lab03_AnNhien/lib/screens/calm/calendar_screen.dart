import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/task_item.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_icons.dart';
import '../../viewmodels/calm_feature_providers.dart';
import '../../viewmodels/caregiver_schedule_view_model.dart' show vietnamToday;
import '../../widgets/calm_parts.dart';
import '../../widgets/velora_home_parts.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/velora_parts.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/state_views.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/undo_snackbar.dart';

String calendarLabel(DateTime date) {
  const days = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật'
  ];
  return '${days[date.weekday - 1]}, ${date.day}/${date.month}/${date.year}';
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.date});
  final DateTime? date;
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.date != null) {
      Future.microtask(() {
        if (mounted) {
          ref.read(calendarDateProvider.notifier).select(widget.date!);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant CalendarScreen old) {
    super.didUpdateWidget(old);
    if (old.date != widget.date) _sync();
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(calendarDateProvider);
    final vm = ref.read(calendarDateProvider.notifier);
    final key = dateKey(date), text = Theme.of(context).textTheme;
    final tasks = ref.watch(calendarTasksProvider(key));
    return Scaffold(
        body: SafeArea(
            child: RefreshIndicator(
      onRefresh: () async => ref.refresh(calendarTasksProvider(key).future),
      child:
          ListView(padding: const EdgeInsets.all(AppSpacing.screen), children: [
        const VeloraGreeting(),
        const SizedBox(height: AppSpacing.lg),
        const VeloraHomeDiscovery(),
        const SizedBox(height: AppSpacing.base),
        LayoutBuilder(builder: (context, box) {
          final action = TextButton(
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm)),
              onPressed: () async {
                final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100));
                if (picked != null) vm.select(picked);
              },
              child: const Text('Xem lịch'));
          if (MediaQuery.textScalerOf(context).scale(20) > 28) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lịch của Bác', style: text.titleLarge),
                  action
                ]);
          }
          return Row(children: [
            Expanded(child: Text('Lịch của Bác', style: text.titleLarge)),
            action
          ]);
        }),
        Text(calendarLabel(date), style: text.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        tasks.when(
          loading: () => const LoadingView(message: 'Đang tải hoạt động…'),
          error: (_, __) => ErrorView(
              message: 'Chưa thể tải lịch. Vui lòng thử lại.',
              onRetry: () => ref.invalidate(calendarTasksProvider(key))),
          data: (items) => items.isEmpty
              ? EmptyView(
                  icon: AppIcons.tabWeek,
                  title: 'Chưa có hoạt động nào trong ngày này.',
                  message: 'Các hoạt động đã lên lịch sẽ xuất hiện ở đây.',
                  action: AppButton(
                      label: 'Khám phá hoạt động',
                      icon: AppIcons.tabHabits,
                      kind: AppButtonKind.secondary,
                      onPressed: () => context.go('/activities')))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      for (final task in items) ...[
                        VeloraScheduleCard(
                            task: task,
                            onTap: () async {
                              await context.push(
                                  '/calendar/task/${Uri.encodeComponent(task.id)}?date=$key');
                              if (mounted) {
                                ref.invalidate(calendarTasksProvider(key));
                              }
                            }),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(children: [
          IconButton(
              tooltip: 'Ngày trước',
              onPressed: () => vm.move(-1),
              icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
              child: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100));
                    if (picked != null) vm.select(picked);
                  },
                  child:
                      Text(calendarLabel(date), textAlign: TextAlign.center))),
          IconButton(
              tooltip: 'Ngày sau',
              onPressed: () => vm.move(1),
              icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        if (key != dateKey(vietnamToday()))
          Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                  onPressed: () => vm.select(vietnamToday()),
                  icon: const Icon(AppIcons.tabToday),
                  label: const Text('Về hôm nay'))),
        const SizedBox(height: AppSpacing.base),
        AppButton(
            label: 'Thêm hoạt động',
            icon: Icons.add_rounded,
            onPressed: () async {
              await context.push('/today/add');
              if (mounted) ref.invalidate(calendarTasksProvider(key));
            }),
      ]),
    )));
  }
}

class CalmTaskDetailScreen extends ConsumerWidget {
  const CalmTaskDetailScreen({super.key, required this.id, this.date});
  final String id;
  final DateTime? date;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = date ?? vietnamToday(), text = Theme.of(context).textTheme;
    final key = dateKey(day),
        state = ref.watch(calendarTasksProvider(dateKey(day)));
    final busy = ref.watch(calendarActionsProvider);
    return Scaffold(
        body: SafeArea(
            child: state.when(
      loading: () => const LoadingView(message: 'Đang tải hoạt động…'),
      error: (_, __) => ErrorView(
          message: 'Chưa thể tải hoạt động.',
          onRetry: () => ref.invalidate(calendarTasksProvider(key))),
      data: (items) {
        final task = items.where((t) => t.id == id).firstOrNull;
        if (task == null) {
          return EmptyView(
              icon: AppIcons.tabWeek,
              title: 'Không tìm thấy hoạt động này',
              action: AppButton(
                  label: 'Quay lại Lịch',
                  icon: AppIcons.tabWeek,
                  onPressed: () => context.go('/calendar?date=$key')));
        }
        final today = key == dateKey(vietnamToday());
        return VeloraDetailBody(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go('/calendar?date=$key'),
            children: [
              Text(task.title, style: text.headlineMedium),
              const SizedBox(height: AppSpacing.base),
              Text(calendarLabel(day), style: text.bodyMedium),
              Text(
                  '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')} · ${task.durationMinutes} phút',
                  style: text.titleMedium),
              const SizedBox(height: AppSpacing.base),
              Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TaskStatusChip(status: task.status)),
              const SizedBox(height: AppSpacing.lg),
              Text(HabitStyle.nameOf(task.habitKey), style: text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                  task.remind
                      ? 'Đã bật lời nhắc cho hoạt động này.'
                      : 'Hoạt động này không bật lời nhắc.',
                  style: text.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              if (today && !task.isDone)
                AppButton(
                    label: 'Hoàn thành',
                    icon: AppIcons.checkCircle,
                    busy: busy,
                    onPressed: () async {
                      final actions =
                          ref.read(calendarActionsProvider.notifier);
                      try {
                        await actions.setDone(task, day);
                        if (context.mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          showUndoSnackbar(context, title: 'Đã hoàn thành',
                              onUndo: () async {
                            try {
                              await actions.setDone(task, day, undo: true);
                            } catch (_) {
                              if (messenger.mounted) {
                                messenger.showSnackBar(const SnackBar(
                                    content: Text(
                                        'Chưa thể hoàn tác. Vui lòng thử lại.')));
                              }
                            }
                          });
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Chưa thể cập nhật. Vui lòng thử lại.')));
                        }
                      }
                    }),
              if (today) ...[
                const SizedBox(height: AppSpacing.base),
                AppButton(
                    label: 'Chỉnh sửa',
                    icon: AppIcons.pencil,
                    kind: AppButtonKind.secondary,
                    onPressed: () async {
                      await context.push(
                          '/today/task/${Uri.encodeComponent(task.id)}/edit');
                      if (context.mounted) {
                        ref.invalidate(calendarTasksProvider(key));
                      }
                    }),
              ] else
                Text(
                    'Bạn đang xem lịch của ngày khác. Trạng thái chỉ có thể cập nhật trong ngày diễn ra hoạt động.',
                    style: text.bodyMedium),
            ]);
      },
    )));
  }
}

class CalmReminderPreviewScreen extends StatelessWidget {
  const CalmReminderPreviewScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBackBar.adaptive(context),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: [
              const CalmPageHeader(
                  title: 'Xem thử lời nhắc', actions: false, art: true),
              const SizedBox(height: AppSpacing.lg),
              Text('Đến giờ thực hiện hoạt động',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.base),
              const Text(
                  'Đây là màn xem trước cách hiển thị lời nhắc. Lịch của bạn không thay đổi.'),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                  label: 'Về Cài đặt',
                  icon: AppIcons.settings,
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/settings')),
            ])),
      );
}
