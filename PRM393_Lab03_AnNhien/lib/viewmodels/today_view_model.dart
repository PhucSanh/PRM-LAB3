import '../models/task_item.dart';
import '../services/providers.dart';
import '../services/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui_state.dart';

/// Các lựa chọn tại DLG-Later của Flow 3.
enum PostponeOption {
  thirtyMinutes,
  oneHour,
  customTime,
  tomorrow,
  customDate,
}

/// Dữ liệu một thao tác gần nhất, để snackbar có thể hoàn tác chính xác.
class _TodayMutation {
  const _TodayMutation(
      {required this.before, required this.action, this.reschedule});

  final TaskItem before;
  final String action;
  final TaskRescheduleChange? reschedule;
}

/// Dữ liệu trình bày của S03. Tất cả phép tính của Hôm nay nằm trong VM.
class TodayData {
  const TodayData({required this.tasks});
  final List<TaskItem> tasks;

  int get doneCount => tasks.where((t) => t.isDone).length;
  int get total => tasks.length;
  int get handledCount =>
      tasks.where((t) => t.status != TaskStatus.pending).length;
  TaskItem? get next =>
      tasks.where((t) => t.status == TaskStatus.pending).firstOrNull;
  bool get allHandled => total > 0 && handledCount == total;
  bool get allDone => total > 0 && doneCount == total;
}

/// F3 Hôm nay – MVVM: màn hình chỉ gọi các thao tác này, không sửa repository trực tiếp.
class TodayViewModel extends Notifier<UiState<TodayData>> {
  _TodayMutation? _lastMutation;

  @override
  UiState<TodayData> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  Future<void> load({bool showLoading = true}) async {
    if (!ref.mounted) return;
    if (showLoading) state = const UiLoading();
    try {
      final tasks =
          await ref.read(taskRepositoryProvider).tasksForDay(DateTime.now());
      if (!ref.mounted) return;
      final sorted = [...tasks]..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      state =
          sorted.isEmpty ? const UiEmpty() : UiData(TodayData(tasks: sorted));
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      await ref
          .read(crashServiceProvider)
          .recordError(error, stackTrace, reason: 'load_today');
      if (!ref.mounted) return;
      state = const UiError('Chưa tải được việc hôm nay.');
    }
  }

  TaskItem? taskById(String taskId) {
    final current = state;
    if (current is! UiData<TodayData>) return null;
    for (final task in current.data.tasks) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  Future<bool> markDone(String taskId,
          {String source = 'today', int taps = 2}) =>
      _changeStatus(taskId, TaskStatus.done,
          action: 'done', source: source, taps: taps);

  Future<bool> skip(String taskId, {String reason = 'none'}) async {
    final task = taskById(taskId);
    if (task == null) return false;
    return _perform(
      before: task,
      action: 'skip',
      change: () => ref
          .read(taskRepositoryProvider)
          .setStatus(taskId, TaskStatus.skipped),
      analytics: () =>
          ref.read(analyticsServiceProvider).logEvent('skip_task', {
        'habit_key': task.habitKey,
        'reason': reason,
      }),
    );
  }

  Future<bool> postpone(String taskId, PostponeOption option,
      {DateTime? targetDay, int? targetHour, int? targetMinute}) async {
    final task = taskById(taskId);
    if (task == null) return false;
    final now = DateTime.now();
    final sourceDay = DateTime(now.year, now.month, now.day);
    final target = switch (option) {
      // Dời lại nghĩa là tính từ thời điểm Bác bấm nút, không phải từ giờ cũ
      // của việc (một việc 9:00 được dời lúc 20:00 sẽ thành 20:30/21:00).
      PostponeOption.thirtyMinutes => now.add(const Duration(minutes: 30)),
      PostponeOption.oneHour => now.add(const Duration(hours: 1)),
      PostponeOption.customTime => targetHour == null || targetMinute == null
          ? null
          : DateTime(sourceDay.year, sourceDay.month, sourceDay.day, targetHour,
              targetMinute),
      PostponeOption.tomorrow => DateTime(sourceDay.year, sourceDay.month,
          sourceDay.day + 1, task.hour, task.minute),
      PostponeOption.customDate => targetDay == null
          ? null
          : DateTime(targetDay.year, targetDay.month, targetDay.day, task.hour,
              task.minute),
    };
    // Không đưa một việc sang giờ đã qua trong chính ngày hôm nay.
    if (target == null ||
        (target.year == now.year &&
            target.month == now.month &&
            target.day == now.day &&
            !target.isAfter(now))) {
      return false;
    }
    try {
      final change = await ref.read(taskRepositoryProvider).reschedule(task,
          targetDay: target, hour: target.hour, minute: target.minute);
      await ref.read(analyticsServiceProvider).logEvent('postpone_task', {
        'habit_key': task.habitKey,
        'option': switch (option) {
          PostponeOption.thirtyMinutes => '30m',
          PostponeOption.oneHour => '1h',
          PostponeOption.customTime => 'custom_time',
          PostponeOption.tomorrow => 'tomorrow',
          PostponeOption.customDate => 'custom_date',
        },
      });
      _lastMutation =
          _TodayMutation(before: task, action: 'postpone', reschedule: change);
      await load(showLoading: false);
      return true;
    } catch (error, stackTrace) {
      await ref
          .read(crashServiceProvider)
          .recordError(error, stackTrace, reason: 'today_postpone');
      return false;
    }
  }

  Future<bool> _changeStatus(String taskId, TaskStatus status,
      {required String action,
      required String source,
      required int taps}) async {
    final task = taskById(taskId);
    if (task == null) return false;
    return _perform(
      before: task,
      action: action,
      change: () => ref.read(taskRepositoryProvider).setStatus(taskId, status),
      analytics: () =>
          ref.read(analyticsServiceProvider).logEvent('complete_task', {
        'habit_key': task.habitKey,
        'on_time': _isOnTime(task),
        'taps': taps,
        'source': source,
      }),
    );
  }

  Future<bool> _perform({
    required TaskItem before,
    required String action,
    required Future<void> Function() change,
    required Future<void> Function() analytics,
  }) async {
    try {
      await change();
      await analytics();
      _lastMutation = _TodayMutation(before: before, action: action);
      await load(showLoading: false);
      return true;
    } catch (error, stackTrace) {
      await ref
          .read(crashServiceProvider)
          .recordError(error, stackTrace, reason: 'today_$action');
      return false;
    }
  }

  /// Hoàn tác thao tác gần nhất của Flow 3, bao gồm cả thay đổi giờ khi dời.
  Future<bool> undoLastAction() async {
    final mutation = _lastMutation;
    if (mutation == null) return false;
    try {
      if (mutation.reschedule != null) {
        await ref
            .read(taskRepositoryProvider)
            .restoreReschedule(mutation.reschedule!);
      } else {
        await ref.read(taskRepositoryProvider).save(mutation.before);
        await ref
            .read(taskRepositoryProvider)
            .setStatus(mutation.before.id, mutation.before.status);
      }
      await ref
          .read(analyticsServiceProvider)
          .logEvent('undo_action', {'action': mutation.action});
      _lastMutation = null;
      await load(showLoading: false);
      return true;
    } catch (error, stackTrace) {
      await ref
          .read(crashServiceProvider)
          .recordError(error, stackTrace, reason: 'undo_today_action');
      return false;
    }
  }

  Future<void> undo(String taskId) async {
    if (_lastMutation?.before.id == taskId) {
      await undoLastAction();
      return;
    }
    await ref
        .read(taskRepositoryProvider)
        .setStatus(taskId, TaskStatus.pending);
    await load();
  }

  static bool _isOnTime(TaskItem task) {
    final now = DateTime.now();
    return now.hour * 60 + now.minute <= task.hour * 60 + task.minute;
  }
}

final todayViewModelProvider =
    NotifierProvider<TodayViewModel, UiState<TodayData>>(TodayViewModel.new);
