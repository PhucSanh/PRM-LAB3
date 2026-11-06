import '../services/task_repository.dart';
import '../services/caregiver_schedule_service.dart' as schedule;
import 'calm_feature_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_item.dart';
import '../services/providers.dart';
import 'today_view_model.dart';

enum TaskFormMode { create, edit }

enum TaskSaveState { editing, saving, offline, saved, error }

enum ChangeScope { once, thisAndFollowing }

/// Dữ liệu tạm của F4. Date và [weekdays] chưa thuộc contract TaskRepository,
/// nên chỉ tồn tại trong form cho tới khi nhóm chốt schema occurrence.
class TaskFormState {
  const TaskFormState({
    this.mode = TaskFormMode.create,
    this.saveState = TaskSaveState.editing,
    this.activity = 'move',
    this.title = '',
    this.date,
    this.hour = 8,
    this.minute = 0,
    this.isAm = true,
    this.repeat = RepeatRule.daily,
    this.weekdays = const {DateTime.monday},
    this.remind = true,
    this.showValidation = false,
    this.errorMessage,
    this.editingId,
    this.original,
  });

  final TaskFormMode mode;
  final TaskSaveState saveState;
  final String activity;
  final String title;
  final DateTime? date;
  final int hour;
  final int minute;
  final bool isAm;
  final RepeatRule repeat;
  final Set<int> weekdays;
  final bool remind;
  final bool showValidation;
  final String? errorMessage;
  final String? editingId;
  final TaskItem? original;

  /// Chỉ chặn giờ đã qua khi Bác đang đặt việc cho đúng ngày hôm nay.
  bool get isTimeInPastToday {
    final selectedDate = date;
    if (selectedDate == null) return false;
    if (mode == TaskFormMode.edit &&
        hour == original?.hour &&
        minute == original?.minute) {
      return false;
    }
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    if (!isToday) return false;
    return DateTime(now.year, now.month, now.day, hour, minute).isBefore(now);
  }

  bool get isDirty => mode == TaskFormMode.edit
      ? activity != original?.habitKey ||
          weekdays.length != (original?.weekdays.length ?? 0) ||
          !weekdays.every((day) => original?.weekdays.contains(day) ?? false) ||
          title != original?.title ||
          hour != original?.hour ||
          minute != original?.minute ||
          repeat != original?.repeat ||
          remind != original?.remind
      : title.isNotEmpty ||
          activity != 'move' ||
          hour != 8 ||
          minute != 0 ||
          repeat != RepeatRule.daily ||
          !remind;

  TaskFormState copyWith({
    TaskFormMode? mode,
    TaskSaveState? saveState,
    String? activity,
    String? title,
    DateTime? date,
    bool clearDate = false,
    int? hour,
    int? minute,
    bool? isAm,
    RepeatRule? repeat,
    Set<int>? weekdays,
    bool? remind,
    bool? showValidation,
    String? errorMessage,
    bool clearError = false,
    String? editingId,
    TaskItem? original,
  }) =>
      TaskFormState(
        mode: mode ?? this.mode,
        saveState: saveState ?? this.saveState,
        activity: activity ?? this.activity,
        title: title ?? this.title,
        date: clearDate ? null : date ?? this.date,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        isAm: isAm ?? this.isAm,
        repeat: repeat ?? this.repeat,
        weekdays: weekdays ?? this.weekdays,
        remind: remind ?? this.remind,
        showValidation: showValidation ?? this.showValidation,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        editingId: editingId ?? this.editingId,
        original: original ?? this.original,
      );
}

class TaskFormViewModel extends Notifier<TaskFormState> {
  TaskItem? _lastMutation;
  bool _lastWasDelete = false;
  schedule.ScheduleUndo? _scopedUndo;
  DateTime? _editDay;

  @override
  TaskFormState build() => const TaskFormState();

  /// Khởi tạo F4 bằng việc mặc định và giờ tròn kế tiếp để Bác chỉ cần sửa khi
  /// muốn. Ví dụ 15:33 → 16:00; 23:33 → ngày kế tiếp lúc 0:00.
  void startCreate() {
    _scopedUndo = null;
    _lastMutation = null;
    _editDay = null;
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    state = TaskFormState(
      activity: 'move',
      title: 'Đi bộ nhẹ nhàng',
      date: DateTime(nextHour.year, nextHour.month, nextHour.day),
      hour: nextHour.hour,
      minute: 0,
      isAm: nextHour.hour < 12,
    );
  }

  Future<bool> startEdit(String id, {DateTime? day}) async {
    _editDay = day ?? DateTime.now();
    _scopedUndo = null;
    _lastMutation = null;
    final tasks = await ref.read(taskRepositoryProvider).tasksForDay(_editDay!);
    final task = tasks.where((item) => item.id == id).firstOrNull;
    if (task == null) return false;
    state = TaskFormState(
      mode: TaskFormMode.edit,
      activity: task.habitKey,
      title: task.title,
      date: _editDay,
      hour: task.hour,
      minute: task.minute,
      isAm: task.hour < 12,
      repeat: task.repeat,
      weekdays: task.weekdays.toSet(),
      remind: task.remind,
      editingId: task.id,
      original: task,
    );
    return true;
  }

  void selectActivity(String activity, {String? suggestedTitle}) =>
      state = state.copyWith(
          activity: activity,
          title: state.mode == TaskFormMode.create && suggestedTitle != null
              ? suggestedTitle
              : state.title,
          showValidation: false,
          clearError: true);
  void setTitle(String value) => state =
      state.copyWith(title: value, showValidation: false, clearError: true);
  void setDate(DateTime value) => state = state.copyWith(date: value);
  void setTime({required int hour, required int minute, required bool isAm}) =>
      state = state.copyWith(hour: hour, minute: minute, isAm: isAm);
  void setRepeat(RepeatRule value) => state = state.copyWith(repeat: value);
  void setWeekdays(Set<int> value) => state = state.copyWith(weekdays: value);
  void setRemind(bool value) => state = state.copyWith(remind: value);
  void restoreEditing() => state =
      state.copyWith(saveState: TaskSaveState.editing, clearError: true);

  Future<bool> save({ChangeScope? scope}) async {
    if (state.title.trim().isEmpty || state.isTimeInPastToday) {
      state = state.copyWith(showValidation: true);
      return false;
    }
    final before = state.original;
    final task = (before ??
            const TaskItem(
                id: "", title: "", habitKey: "move", hour: 8, minute: 0))
        .copyWith(
      id: state.editingId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: state.title.trim(),
      habitKey: state.activity,
      hour: state.hour,
      minute: state.minute,
      repeat: state.repeat,
      clearEndDate:
          before?.repeat == RepeatRule.once && state.repeat != RepeatRule.once,
      remind: state.remind,
      status: before?.status ?? TaskStatus.pending,
      startDate: before?.startDate ??
          dateKey(before != null ? _editDay! : state.date ?? DateTime.now()),
      weekdays: state.repeat == RepeatRule.someDays ||
              state.repeat == RepeatRule.weekly
          ? state.weekdays.toList()
          : const [],
    );
    state =
        state.copyWith(saveState: TaskSaveState.saving, showValidation: false);
    try {
      final repository = ref.read(taskRepositoryProvider);
      if (before != null && repository is ScopedTaskRepository) {
        _scopedUndo =
            await (repository as ScopedTaskRepository).changeOccurrence(
                before,
                _editDay!,
                task,
                before.repeat == RepeatRule.once
                    ? schedule.ChangeScope.all
                    : scope == ChangeScope.once
                        ? schedule.ChangeScope.occurrence
                        : schedule.ChangeScope.future);
      } else {
        await repository.save(task);
      }
      await ref.read(analyticsServiceProvider).logEvent(
        state.mode == TaskFormMode.create ? 'add_task' : 'edit_task',
        {'task_id': task.id, 'repeat': task.repeat.name},
      );
      _lastMutation = before;
      _lastWasDelete = false;
      ref.invalidate(todayViewModelProvider);
      ref.invalidate(calendarTasksProvider);
      state = state.copyWith(
          saveState: TaskSaveState.saved, original: task, editingId: task.id);
      return true;
    } catch (error, stack) {
      await ref
          .read(crashServiceProvider)
          .recordError(error, stack, reason: 'save_task');
      final offline = error
          .toString()
          .toLowerCase()
          .contains(RegExp('network|offline|unavailable'));
      state = state.copyWith(
        saveState: offline ? TaskSaveState.offline : TaskSaveState.error,
        errorMessage: offline
            ? 'Lưu trên điện thoại, không cần mạng'
            : 'Chưa thể lưu trên điện thoại.',
      );
      return false;
    }
  }

  Future<bool> delete(ChangeScope scope) async {
    final task = state.original;
    if (task == null) return false;
    state = state.copyWith(saveState: TaskSaveState.saving);
    try {
      final repository = ref.read(taskRepositoryProvider);
      if (repository is ScopedTaskRepository) {
        _scopedUndo = await (repository as ScopedTaskRepository)
            .changeOccurrence(
                task,
                _editDay ?? DateTime.now(),
                null,
                scope == ChangeScope.once
                    ? schedule.ChangeScope.occurrence
                    : schedule.ChangeScope.future);
      } else {
        await repository.delete(task.id);
      }
      await ref
          .read(analyticsServiceProvider)
          .logEvent('delete_task', {'task_id': task.id, 'scope': scope.name});
      _lastMutation = task;
      _lastWasDelete = true;
      ref.invalidate(todayViewModelProvider);
      ref.invalidate(calendarTasksProvider);
      return true;
    } catch (error, stack) {
      await ref
          .read(crashServiceProvider)
          .recordError(error, stack, reason: 'delete_task');
      state = state.copyWith(
          saveState: TaskSaveState.error,
          errorMessage: 'Chưa thể xóa trên điện thoại.');
      return false;
    }
  }

  Future<void> undoLastMutation() async {
    if (_scopedUndo != null) {
      await (ref.read(taskRepositoryProvider) as ScopedTaskRepository)
          .undoOccurrence(_scopedUndo!);
      _scopedUndo = null;
      ref.invalidate(todayViewModelProvider);
      ref.invalidate(calendarTasksProvider);
      return;
    }
    final last = _lastMutation;
    if (last == null) return;
    if (_lastWasDelete) {
      await ref.read(taskRepositoryProvider).save(last);
    } else if (state.original != null && state.mode == TaskFormMode.edit) {
      await ref.read(taskRepositoryProvider).save(last);
    }
    ref.invalidate(todayViewModelProvider);
    ref.invalidate(calendarTasksProvider);
  }
}

final taskFormViewModelProvider =
    NotifierProvider<TaskFormViewModel, TaskFormState>(TaskFormViewModel.new);
