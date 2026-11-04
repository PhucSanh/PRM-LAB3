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

  bool get isDirty => mode == TaskFormMode.edit
      ? title != original?.title ||
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

  @override
  TaskFormState build() => const TaskFormState();

  void startCreate() => state = TaskFormState(date: DateTime.now());

  Future<bool> startEdit(String id) async {
    final tasks =
        await ref.read(taskRepositoryProvider).tasksForDay(DateTime.now());
    final task = tasks.where((item) => item.id == id).firstOrNull;
    if (task == null) return false;
    state = TaskFormState(
      mode: TaskFormMode.edit,
      activity: task.habitKey,
      title: task.title,
      date: DateTime.now(),
      hour: task.hour,
      minute: task.minute,
      isAm: task.hour < 12,
      repeat: task.repeat,
      remind: task.remind,
      editingId: task.id,
      original: task,
    );
    return true;
  }

  void selectActivity(String activity) =>
      state = state.copyWith(activity: activity);
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
    if (state.title.trim().isEmpty) {
      state = state.copyWith(showValidation: true);
      return false;
    }
    final before = state.original;
    final task = TaskItem(
      id: state.editingId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: state.title.trim(),
      habitKey: state.activity,
      hour: state.hour,
      minute: state.minute,
      repeat: state.repeat,
      remind: state.remind,
      status: before?.status ?? TaskStatus.pending,
    );
    state =
        state.copyWith(saveState: TaskSaveState.saving, showValidation: false);
    try {
      await ref.read(taskRepositoryProvider).save(task);
      await ref.read(analyticsServiceProvider).logEvent(
        state.mode == TaskFormMode.create ? 'add_task' : 'edit_task',
        {'task_id': task.id, 'repeat': task.repeat.name},
      );
      _lastMutation = before;
      _lastWasDelete = false;
      ref.invalidate(todayViewModelProvider);
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
      await ref.read(taskRepositoryProvider).delete(task.id);
      await ref
          .read(analyticsServiceProvider)
          .logEvent('delete_task', {'task_id': task.id, 'scope': scope.name});
      _lastMutation = task;
      _lastWasDelete = true;
      ref.invalidate(todayViewModelProvider);
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
    final last = _lastMutation;
    if (last == null) return;
    if (_lastWasDelete) {
      await ref.read(taskRepositoryProvider).save(last);
    } else if (state.original != null && state.mode == TaskFormMode.edit) {
      await ref.read(taskRepositoryProvider).save(last);
    }
    ref.invalidate(todayViewModelProvider);
  }
}

final taskFormViewModelProvider =
    NotifierProvider<TaskFormViewModel, TaskFormState>(TaskFormViewModel.new);
