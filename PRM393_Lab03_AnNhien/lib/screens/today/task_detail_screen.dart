import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/task_item.dart';
import '../tasks/task_form_screens.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../viewmodels/task_detail_view_model.dart';
import '../../viewmodels/task_form_view_model.dart';
import '../../viewmodels/today_view_model.dart';
import '../../viewmodels/ui_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/habit_widgets.dart';
import '../../widgets/state_views.dart';
import '../../widgets/section_card.dart';
import '../../widgets/task_widgets.dart';
import '../../widgets/time_field.dart';
import '../../widgets/undo_snackbar.dart';

/// S04 – Chi tiết một việc của hôm nay. Dùng được cho link từ S03 và lịch tuần.
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId, this.day});

  final String taskId;
  final DateTime? day;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(taskDetailViewModelProvider.notifier)
          .load(widget.taskId, day: widget.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskDetailViewModelProvider);
    final vm = ref.read(taskDetailViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBackBar(
        onBack: () => context.pop(),
        trailing: AppBarEditButton(
          onPressed: () => context.push('/today/task/${widget.taskId}/edit'),
        ),
      ),
      body: SafeArea(
        child: switch (state) {
          UiLoading() => const LoadingView(message: 'Đang tải chi tiết việc…'),
          UiError(:final message) => ErrorView(
              message: message,
              onRetry: () => vm.load(widget.taskId, day: widget.day),
            ),
          UiEmpty() => const SizedBox.shrink(),
          UiData(:final data) => _TaskDetail(task: data, vm: vm),
        },
      ),
    );
  }
}

class _TaskDetail extends StatelessWidget {
  const _TaskDetail({required this.task, required this.vm});

  final TaskItem task;
  final TaskDetailViewModel vm;

  @override
  Widget build(BuildContext context) => ListView(
        // Màn này nằm trong AppShell có thanh điều hướng đáy. Chừa đủ phần
        // cuộn cuối để các nút hành động (đặc biệt “Đã xong”) không bị thanh
        // đó che ở màn hình thấp.
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.screen,
            AppSpacing.screen + AppSizes.navBar),
        children: [
          Semantics(
            header: true,
            child: Text('Việc của Bác',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          const SizedBox(height: AppSpacing.lg),
          HabitAccentCard(
            habitKey: task.habitKey,
            child: Row(children: [
              HabitBadge(habitKey: task.habitKey),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Text(task.title,
                      style: Theme.of(context).textTheme.titleLarge)),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: AppSizes.minTarget,
                leading: const Icon(AppIcons.clock),
                title: const Text('Giờ làm'),
                subtitle: Text(formatTimeOfDay(
                    TimeOfDay(hour: task.hour, minute: task.minute),
                    wholeHourInWords: true)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: AppSizes.minTarget,
                leading: const Icon(AppIcons.repeat),
                title: const Text('Lặp lại'),
                subtitle: Text(_repeatLabel(task.repeat)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: AppSizes.minTarget,
                leading: const Icon(AppIcons.bell),
                title: const Text('Lời nhắc'),
                subtitle: Text(task.remind ? 'Đang bật' : 'Chưa đặt lời nhắc'),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (task.status == TaskStatus.pending) ...[
            AppButton(
              label: 'Đã xong',
              icon: AppIcons.checkCircle,
              onPressed: () => _runThenReturnToday(
                context,
                () => runTaskAction(context, task,
                    complete: () => _afterAction(vm.complete(task.id)),
                    undo: vm.undoLastAction),
              ),
            ),
            const SizedBox(height: AppSpacing.betweenTargets),
            AppButton(
              label: 'Dời lại',
              icon: AppIcons.later,
              kind: AppButtonKind.secondary,
              onPressed: () => _runThenReturnToday(
                context,
                () => runTaskAction(context, task,
                    postpone: (id, option,
                            {targetDay, targetHour, targetMinute}) =>
                        _afterAction(vm.postpone(id, option,
                            targetDay: targetDay,
                            targetHour: targetHour,
                            targetMinute: targetMinute)),
                    undo: vm.undoLastAction),
              ),
            ),
            const SizedBox(height: AppSpacing.betweenTargets),
            AppButton(
              label: 'Hôm nay bỏ qua',
              icon: AppIcons.skipToday,
              kind: AppButtonKind.text,
              onPressed: () => _runThenReturnToday(
                context,
                () => runTaskAction(context, task,
                    skip: () => _afterAction(vm.skip(task.id)),
                    undo: vm.undoLastAction),
              ),
            ),
          ] else
            TaskStatusChip(status: task.status),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Sửa việc',
            icon: AppIcons.pencil,
            kind: AppButtonKind.secondary,
            onPressed: () => context.push('/today/task/${task.id}/edit'),
          ),
        ],
      );

  Future<bool> _afterAction(Future<bool> action) async {
    final saved = await action;
    if (saved) await vm.load(task.id, showLoading: false);
    return saved;
  }

  Future<void> _runThenReturnToday(
      BuildContext context, Future<bool> Function() action) async {
    final saved = await action();
    if (saved && context.mounted) context.go('/today?view=main');
  }
}

String _repeatLabel(RepeatRule repeat) => switch (repeat) {
      RepeatRule.once => 'Một lần',
      RepeatRule.daily => 'Mỗi ngày',
      RepeatRule.someDays || RepeatRule.weekly => 'Vài ngày trong tuần',
      RepeatRule.monthly => 'Mỗi tháng',
    };

/// Dùng chung cho S03 và S04: xác nhận trước khi đổi trạng thái, sau đó hiển thị
/// snackbar có Hoàn tác. Các callback gọi ViewModel, không gọi repository từ UI.
Future<bool> runTaskAction(
  BuildContext context,
  TaskItem task, {
  Future<bool> Function()? complete,
  Future<bool> Function()? skip,
  Future<bool> Function(String taskId, PostponeOption option,
          {DateTime? targetDay, int? targetHour, int? targetMinute})?
      postpone,
  required Future<bool> Function() undo,
}) async {
  bool? saved;
  String? message;
  if (complete != null) {
    final confirmed = await showConfirmDialog<bool>(
      context,
      icon: AppIcons.checkCircle,
      title: 'Bác đã làm xong?',
      message: 'Việc “${task.title}” sẽ được đánh dấu đã xong.',
      options: const [
        ConfirmOption(
            label: 'Đúng, đã xong', icon: AppIcons.checkCircle, value: true),
        ConfirmOption(
            label: 'Chưa, để sau',
            icon: AppIcons.x,
            value: false,
            kind: AppButtonKind.text),
      ],
    );
    if (confirmed == true) {
      saved = await complete();
      message = 'Đã xong việc ${task.title}.';
    }
  } else if (postpone != null) {
    final option = await showConfirmDialog<PostponeOption?>(
      context,
      icon: AppIcons.later,
      title: 'Dời việc này?',
      message: 'Bác muốn nhắc lại việc “${task.title}” khi nào?',
      options: const <ConfirmOption<PostponeOption?>>[
        ConfirmOption(
            label: 'Sau 30 phút',
            icon: AppIcons.later,
            value: PostponeOption.thirtyMinutes),
        ConfirmOption(
            label: 'Sau 1 giờ',
            icon: AppIcons.clock,
            value: PostponeOption.oneHour,
            kind: AppButtonKind.secondary),
        ConfirmOption(
            label: 'Chọn giờ, phút',
            icon: AppIcons.clock,
            value: PostponeOption.customTime,
            kind: AppButtonKind.secondary),
        ConfirmOption(
            label: 'Ngày mai',
            icon: AppIcons.arrowRight,
            value: PostponeOption.tomorrow,
            kind: AppButtonKind.secondary),
        ConfirmOption(
            label: 'Chọn ngày khác',
            icon: AppIcons.tabWeek,
            value: PostponeOption.customDate,
            kind: AppButtonKind.secondary),
        ConfirmOption(
            label: 'Không dời nữa',
            icon: AppIcons.x,
            value: null,
            kind: AppButtonKind.text),
      ],
    );
    if (option != null) {
      DateTime? targetDay;
      int? targetHour;
      int? targetMinute;
      if (option == PostponeOption.customTime) {
        if (!context.mounted) return false;
        final now = DateTime.now();
        final firstSuggestedTime =
            DateTime(now.year, now.month, now.day, now.hour + 1);
        // Dùng đúng hộp chọn giờ của F4 để Bác luôn thao tác theo cùng một
        // cách: giờ 1–12, phút 00/15/30/45 và Sáng/Chiều.
        final picked = await showTaskTimeDialog(
          context,
          TaskFormState(
            date: DateTime(now.year, now.month, now.day),
            hour: firstSuggestedTime.hour,
            minute: 0,
            isAm: firstSuggestedTime.hour < 12,
          ),
        );
        if (picked == null) return false;
        if (!context.mounted) return false;
        targetHour = picked.$1;
        targetMinute = picked.$2;
      }
      if (option == PostponeOption.customDate) {
        if (!context.mounted) return false;
        final now = DateTime.now();
        targetDay = await showDatePicker(
          context: context,
          initialDate: now.add(const Duration(days: 1)),
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: DateTime(now.year + 2),
          helpText: 'Chọn ngày dời việc',
          cancelText: 'Hủy',
          confirmText: 'Xong',
        );
        if (targetDay == null) return false;
      }
      saved = await postpone(task.id, option,
          targetDay: targetDay,
          targetHour: targetHour,
          targetMinute: targetMinute);
      message = switch (option) {
        PostponeOption.thirtyMinutes => 'Đã dời ${task.title} thêm 30 phút.',
        PostponeOption.oneHour => 'Đã dời ${task.title} thêm 1 giờ.',
        PostponeOption.customTime => 'Đã dời ${task.title} đến giờ đã chọn.',
        PostponeOption.tomorrow => 'Đã dời ${task.title} sang ngày mai.',
        PostponeOption.customDate => 'Đã dời ${task.title} sang ngày đã chọn.',
      };
    }
  } else if (skip != null) {
    final confirmed = await showConfirmDialog<bool>(
      context,
      icon: AppIcons.skipToday,
      title: 'Bỏ qua hôm nay?',
      message: 'Việc “${task.title}” sẽ không nhắc lại trong hôm nay.',
      options: const [
        ConfirmOption(
            label: 'Bỏ qua hôm nay', icon: AppIcons.skipToday, value: true),
        ConfirmOption(
            label: 'Không, giữ lại',
            icon: AppIcons.x,
            value: false,
            kind: AppButtonKind.secondary),
      ],
    );
    if (confirmed == true) {
      saved = await skip();
      message = 'Đã bỏ qua ${task.title} hôm nay.';
    }
  }
  if (saved == null || !context.mounted) return false;
  if (saved) {
    showUndoSnackbar(
      context,
      title: message!,
      subtitle: 'Bác có thể bấm Hoàn tác nếu vừa chọn nhầm.',
      onUndo: () {
        undo();
      },
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
      ProviderScope.containerOf(context).read(todayViewModelProvider.notifier).actionError ?? 'Chưa cập nhật được việc. Bác thử lại nhé.')));
  }
  return saved;
}
