import '../../widgets/upcoming_activity_card.dart';
import '../../widgets/quick_task_actions.dart';
import '../../viewmodels/daily_actions_view_model.dart';
import '../../widgets/read_aloud_control.dart';
import '../../widgets/assistant_bubble.dart';
import '../today/task_detail_screen.dart' show runTaskAction;
import '../../viewmodels/today_view_model.dart';
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
import '../../widgets/task_detail_parts.dart';
import '../../widgets/caregiver_parts.dart' show repeatLabel;
import '../../models/habit_guide.dart';
import '../../models/voice_task_draft.dart' show durationText;

String _hhmm(int totalMinutes) {
  final m = totalMinutes % (24 * 60);
  return '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';
}

/// "08:00 – 08:30".
String taskTimeRange(TaskItem t) {
  final start = t.hour * 60 + t.minute;
  return '${_hhmm(start)} – ${_hhmm(start + t.durationMinutes)}';
}

/// Toàn bộ nội dung màn Chi tiết việc để nút Đọc to đọc lần lượt.
String taskDetailSpokenText(
        TaskItem t, DateTime day, HabitGuide guide, String benefit) =>
    [
      '${t.title}.',
      'Trạng thái: ${t.status.label}.',
      '${calendarLabel(day)}, từ ${t.hour} giờ ${t.minute} phút, '
          'làm trong ${durationText(t.durationMinutes)}.',
      'Lặp lại: ${repeatLabel(t)}.',
      t.remind ? 'Đang bật lời nhắc.' : 'Chưa bật lời nhắc.',
      'Vì sao tốt cho Bác: $benefit',
      'Bác chuẩn bị: ${guide.prepare.map((p) => p.$2).join(', ')}.',
      'Cách làm:',
      for (final (i, step) in guide.steps.indexed) 'Bước ${i + 1}: $step',
      'Lưu ý: ${guide.note}',
    ].join(' ');

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

/// Nút "Thêm hoạt động" ghim ở đáy Trang chủ và trang Lịch trong ngày.
class _AddActivityBar extends ConsumerWidget {
  const _AddActivityBar({required this.dayKey});
  final String dayKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
              AppSpacing.screen, AppSpacing.sm),
          child: AppButton(
            label: 'Thêm hoạt động',
            kind: AppButtonKind.tonal,
            icon: Icons.add_rounded,
            onPressed: () async {
              await context.push('/today/add?date=$dayKey');
              ref.invalidate(calendarTasksProvider(dayKey));
            },
          ),
        ),
      );
}

String calendarDayRoute(DateTime day) => '/calendar/day?date=${dateKey(day)}';

/// Trang chủ: chỉ việc sắp tới hôm nay (việc kế tiếp + tối đa 2 việc sau đó,
/// theo giờ). Toàn bộ lịch trong ngày nằm ở [CalendarDayScreen].
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  /// Số hoạt động hiện thêm sau việc kế tiếp.
  static const moreUpcoming = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = vietnamToday(), key = dateKey(today);
    final text = Theme.of(context).textTheme;
    final tasks = ref.watch(calendarTasksProvider(key));
    void open(TaskItem task) => context
        .push('/calendar/task/${Uri.encodeComponent(task.id)}?date=$key');
    return Scaffold(
        floatingActionButton: const AssistantBubble(),
        bottomNavigationBar: _AddActivityBar(dayKey: key),
        body: SafeArea(
            child: RefreshIndicator(
          onRefresh: () async => ref.refresh(calendarTasksProvider(key).future),
          child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.screen,
                  AppSpacing.screen,
                  AssistantBubble.clearance),
              children: [
                const VeloraGreeting(),
                const SizedBox(height: AppSpacing.lg),
                tasks.when(
                  loading: () =>
                      const LoadingView(message: 'Đang tải hoạt động…'),
                  error: (_, __) => ErrorView(
                      message: 'Chưa thể tải lịch. Vui lòng thử lại.',
                      onRetry: () =>
                          ref.invalidate(calendarTasksProvider(key))),
                  data: (items) {
                    // Chỉ việc hôm nay chưa làm và chưa kết thúc theo giờ
                    // hiện tại: đang diễn ra hoặc chưa tới giờ. Việc đã qua
                    // giờ không hiện ở đây (xem trong lịch ngày). Không còn
                    // việc nào thì không hiện thẻ.
                    final upcoming = upcomingTasks(items, vietnamNow());
                    if (upcoming.isEmpty) return const SizedBox.shrink();
                    final next = upcoming.first;
                    final later = upcoming.skip(1).take(moreUpcoming).toList();
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          UpcomingActivityCard(
                              task: next,
                              day: today,
                              canComplete: true,
                              onOpen: () => open(next)),
                          if (later.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Semantics(
                                header: true,
                                child:
                                    Text('Tiếp theo', style: text.titleLarge)),
                            const SizedBox(height: AppSpacing.md),
                            for (final task in later) ...[
                              VeloraScheduleCard(
                                  task: task, onTap: () => open(task)),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        ]);
                  },
                ),
                const SizedBox(height: AppSpacing.base),
                AppButton(
                    key: const Key('calendar-day-detail'),
                    label: 'Xem chi tiết lịch hôm nay',
                    icon: Icons.view_agenda_outlined,
                    kind: AppButtonKind.secondary,
                    onPressed: () => context.go(calendarDayRoute(today))),
                const SizedBox(height: AppSpacing.xl),
                const VeloraHomeDiscovery(),
              ]),
        )));
  }
}

/// Toàn bộ lịch của một ngày, có chuyển ngày trước / sau và chọn ngày.
class CalendarDayScreen extends ConsumerStatefulWidget {
  const CalendarDayScreen({super.key, this.date});
  final DateTime? date;
  @override
  ConsumerState<CalendarDayScreen> createState() => _CalendarDayScreenState();
}

class _CalendarDayScreenState extends ConsumerState<CalendarDayScreen> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    Future.microtask(() {
      if (mounted) {
        ref
            .read(calendarDateProvider.notifier)
            .select(widget.date ?? vietnamToday());
      }
    });
  }

  @override
  void didUpdateWidget(covariant CalendarDayScreen old) {
    super.didUpdateWidget(old);
    if (old.date != widget.date) _sync();
  }

  Future<void> _pick(DateTime date) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (picked != null) ref.read(calendarDateProvider.notifier).select(picked);
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(calendarDateProvider);
    final vm = ref.read(calendarDateProvider.notifier);
    final key = dateKey(date), text = Theme.of(context).textTheme;
    final tasks = ref.watch(calendarTasksProvider(key));
    return Scaffold(
        // Là tab "Lịch": chỉ có nút Quay lại khi được mở chồng lên màn khác.
        appBar: context.canPop()
            ? AppBackBar.adaptive(context, onBack: () => context.pop())
            : null,
        floatingActionButton: const AssistantBubble(),
        bottomNavigationBar: _AddActivityBar(dayKey: key),
        body: SafeArea(
            child: RefreshIndicator(
          onRefresh: () async => ref.refresh(calendarTasksProvider(key).future),
          child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.sm, AppSpacing.screen, AssistantBubble.clearance),
              children: [
                Semantics(
                    header: true,
                    child: Text('Lịch của Bác', style: text.headlineSmall)),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  IconButton(
                      tooltip: 'Ngày trước',
                      onPressed: () => vm.move(-1),
                      icon: const Icon(Icons.chevron_left_rounded)),
                  Expanded(
                      child: TextButton(
                          onPressed: () => _pick(date),
                          child: Text(calendarLabel(date),
                              textAlign: TextAlign.center))),
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
                const SizedBox(height: AppSpacing.sm),
                tasks.when(
                  loading: () =>
                      const LoadingView(message: 'Đang tải hoạt động…'),
                  error: (_, __) => ErrorView(
                      message: 'Chưa thể tải lịch. Vui lòng thử lại.',
                      onRetry: () =>
                          ref.invalidate(calendarTasksProvider(key))),
                  data: (items) => items.isEmpty
                      ? EmptyView(
                          icon: AppIcons.tabWeek,
                          title: 'Chưa có hoạt động nào trong ngày này.',
                          message:
                              'Bác chạm Thêm hoạt động bên dưới để lên lịch.',
                          action: AppButton(
                              label: 'Khám phá hoạt động',
                              icon: AppIcons.tabHabits,
                              kind: AppButtonKind.secondary,
                              onPressed: () => context.go('/activities')))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              Text('${items.length} hoạt động',
                                  style: text.titleMedium),
                              const SizedBox(height: AppSpacing.md),
                              for (final task in items) ...[
                                VeloraScheduleCard(
                                    task: task,
                                    onTap: () async {
                                      await context.push(
                                          '/calendar/task/${Uri.encodeComponent(task.id)}?date=$key');
                                      if (mounted) {
                                        ref.invalidate(
                                            calendarTasksProvider(key));
                                      }
                                    }),
                                const SizedBox(height: AppSpacing.md),
                              ],
                            ]),
                ),
              ]),
        )));
  }
}

class CalmTaskDetailScreen extends ConsumerWidget {
  const CalmTaskDetailScreen(
      {super.key, required this.id, this.date, this.autoRead = false});
  final bool autoRead;
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
        if (autoRead) {
          return ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/calendar'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Quay lại'))),
                Text('Đến giờ của Bác', style: text.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Text(task.title, style: text.headlineMedium),
                Text(
                    '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')} · ${calendarLabel(day)}',
                    style: text.titleMedium),
                const SizedBox(height: AppSpacing.lg),
                ReminderReadAloudControl(
                    identity: '${task.id}-$key',
                    showButton: false,
                    text:
                        '${task.title}. ${task.hour} giờ ${task.minute} phút.'),
                if (today && !task.isDone && task.status != TaskStatus.skipped)
                  QuickTaskActions(task: task, day: day)
                else
                  Text(
                      task.isDone
                          ? 'Bác đã làm xong việc này.'
                          : 'Lời nhắc này thuộc ngày khác hoặc việc đã được bỏ qua. Bác xem lại lịch nhé.',
                      style: text.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                    label: 'Xem lịch',
                    icon: AppIcons.tabWeek,
                    kind: AppButtonKind.secondary,
                    onPressed: () => context.go('/calendar?date=$key')),
              ]);
        }

        final guide = habitGuideOf(task.habitKey);
        final benefit = [
          HabitStyle.descriptionOf(task.habitKey),
          guide.benefit,
        ].where((s) => s.isNotEmpty).join(' ');
        return VeloraDetailBody(
            hero: TaskHeroArt(
                habitKey: task.habitKey,
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go(calendarDayRoute(day))),
            children: [
              Text(HabitStyle.nameOf(task.habitKey).toUpperCase(),
                  style: text.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1)),
              const SizedBox(height: AppSpacing.xs),
              Text(task.title, style: text.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TaskStatusChip(status: task.status)),
              const SizedBox(height: AppSpacing.lg),
              // Nút Đọc to duy nhất của app cho một việc: đọc cả màn chi tiết.
              ReadAloudControl(
                  text: taskDetailSpokenText(task, day, guide, benefit)),
              const SizedBox(height: AppSpacing.lg),
              TaskInfoGrid(tiles: [
                TaskInfoTile(
                    icon: Icons.event_rounded,
                    label: 'Ngày',
                    value: calendarLabel(day)),
                TaskInfoTile(
                    icon: Icons.schedule_rounded,
                    label: 'Giờ làm',
                    value: taskTimeRange(task)),
                TaskInfoTile(
                    icon: Icons.hourglass_bottom_rounded,
                    label: 'Làm trong',
                    value: durationText(task.durationMinutes)),
                TaskInfoTile(
                    icon: Icons.repeat_rounded,
                    label: 'Lặp lại',
                    value: repeatLabel(task)),
                TaskInfoTile(
                    icon: task.remind
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    label: 'Nhắc nhở',
                    value: task.remind ? 'Đang bật' : 'Đang tắt'),
                TaskInfoTile(
                    icon: HabitStyle.iconOf(task.habitKey),
                    label: 'Nhóm thói quen',
                    value: HabitStyle.nameOf(task.habitKey)),
              ]),
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
              if (today && !task.isDone) ...[
                const SizedBox(height: AppSpacing.base),
                AppButton(
                    label: 'Dời lại',
                    icon: AppIcons.later,
                    kind: AppButtonKind.secondary,
                    onPressed: busy
                        ? null
                        : () async {
                            final vm =
                                ref.read(todayViewModelProvider.notifier);
                            await vm.load();
                            if (!context.mounted) return;
                            await runTaskAction(context, task,
                                postpone: vm.postpone, undo: () async {
                              final ok = await vm.undoLastAction();
                              ref.invalidate(calendarTasksProvider);
                              return ok;
                            });
                            ref.invalidate(calendarTasksProvider);
                          }),
                const SizedBox(height: AppSpacing.base),
                AppButton(
                    label: 'Bỏ qua hôm nay',
                    icon: AppIcons.skipToday,
                    kind: AppButtonKind.secondary,
                    onPressed: busy
                        ? null
                        : () async {
                            final vm =
                                ref.read(todayViewModelProvider.notifier);
                            await vm.load();
                            if (!context.mounted) return;
                            await runTaskAction(context, task,
                                skip: () => vm.skip(task.id),
                                undo: () async {
                                  final ok = await vm.undoLastAction();
                                  ref.invalidate(calendarTasksProvider);
                                  return ok;
                                });
                            ref.invalidate(calendarTasksProvider);
                          }),
              ],
              if (!day.isBefore(vietnamToday())) ...[
                const SizedBox(height: AppSpacing.base),
                AppButton(
                    label: 'Chỉnh sửa',
                    icon: AppIcons.pencil,
                    kind: AppButtonKind.secondary,
                    onPressed: () async {
                      await context.push(
                          '/today/task/${Uri.encodeComponent(task.id)}/edit?date=$key');
                      if (context.mounted) {
                        ref.invalidate(calendarTasksProvider(key));
                      }
                    }),
              ] else
                Text(
                    'Bạn đang xem lịch của ngày khác. Trạng thái chỉ có thể cập nhật trong ngày diễn ra hoạt động.',
                    style: text.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                  header: true,
                  child: Text('Vì sao tốt cho Bác', style: text.titleLarge)),
              const SizedBox(height: AppSpacing.sm),
              Text(benefit, style: text.bodyLarge),
              if (habitPhotosOf(task.habitKey).skip(1).toList() case final more
                  when more.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Semantics(
                    header: true,
                    child: Text('Hình ảnh', style: text.titleLarge)),
                const SizedBox(height: AppSpacing.md),
                HabitPhotoStrip(
                    photos: more,
                    label: 'Ảnh minh hoạ ${HabitStyle.nameOf(task.habitKey)}'),
              ],
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                  header: true,
                  child: Text('Bác chuẩn bị', style: text.titleLarge)),
              const SizedBox(height: AppSpacing.md),
              PrepareGallery(items: guide.prepare),
              const SizedBox(height: AppSpacing.xl),
              Semantics(
                  header: true,
                  child: Text('Cách làm', style: text.titleLarge)),
              const SizedBox(height: AppSpacing.md),
              TaskStepList(steps: guide.steps),
              const SizedBox(height: AppSpacing.md),
              TaskNoteCard(text: guide.note),
              const SizedBox(height: AppSpacing.xl),
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
