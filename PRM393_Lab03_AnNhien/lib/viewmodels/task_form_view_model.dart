import '../services/task_repository.dart';
import '../services/caregiver_schedule_service.dart' as schedule;
import 'calm_feature_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_item.dart';
import '../services/providers.dart';
import 'today_view_model.dart';
import 'schedule_conflict.dart';

enum TaskFormMode { create, edit }

enum TaskSaveState { editing, saving, offline, saved, error }

/// [all]: xoá cả chuỗi lặp khỏi lịch (mọi lần).
enum ChangeScope { once, thisAndFollowing, all }

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
    this.durationMinutes = 15,
    this.isAm = true,
    this.repeat = RepeatRule.daily,
    this.weekdays = const {DateTime.monday},
    this.remind = true,
    this.showValidation = false,
    this.errorMessage,
    this.conflictMessage,
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
  final int durationMinutes;
  final bool isAm;
  final RepeatRule repeat;
  final Set<int> weekdays;
  final bool remind;
  final bool showValidation;
  final String? errorMessage;

  /// Trùng giờ với việc đã có: một khung giờ chỉ một việc.
  final String? conflictMessage;
  final String? editingId;
  final TaskItem? original;

  String? get titleError {
    if (!showValidation) return null;
    if (title.trim().isEmpty) return 'Bác chưa nhập tên việc.';
    if (title.trim().length > 80) return 'Tên việc tối đa 80 ký tự.';
    return null;
  }

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
          durationMinutes != original?.durationMinutes ||
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
    int? durationMinutes,
    bool? isAm,
    RepeatRule? repeat,
    Set<int>? weekdays,
    bool? remind,
    bool? showValidation,
    String? errorMessage,
    bool clearError = false,
    String? conflictMessage,
    bool clearConflict = false,
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
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isAm: isAm ?? this.isAm,
        repeat: repeat ?? this.repeat,
        weekdays: weekdays ?? this.weekdays,
        remind: remind ?? this.remind,
        showValidation: showValidation ?? this.showValidation,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        conflictMessage:
            clearConflict ? null : conflictMessage ?? this.conflictMessage,
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
  void startCreate(
      {DateTime? day,
      String activity = 'move',
      String title = 'Đi bộ nhẹ nhàng',
      int durationMinutes = 15,
      RepeatRule repeat = RepeatRule.daily}) {
    _scopedUndo = null;
    _lastMutation = null;
    _editDay = null;
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    final today = DateTime(now.year, now.month, now.day);
    final requested =
        day == null ? today : DateTime(day.year, day.month, day.day);
    final future = requested.isAfter(today);
    final hour = future ? 8 : nextHour.hour;
    state = TaskFormState(
      activity: activity,
      title: title,
      durationMinutes: durationMinutes,
      repeat: repeat,
      date: future
          ? requested
          : DateTime(nextHour.year, nextHour.month, nextHour.day),
      hour: hour,
      minute: 0,
      isAm: hour < 12,
    );
  }

  void startFromRecent(TaskItem task, {DateTime? day}) {
    startCreate(
        day: day,
        activity: task.habitKey,
        title: task.title,
        durationMinutes: task.durationMinutes,
        repeat: task.repeat);
    final now = DateTime.now(), selected = state.date!;
    final originalTime = DateTime(
        selected.year, selected.month, selected.day, task.hour, task.minute);
    if (originalTime.isAfter(now)) {
      setTime(hour: task.hour, minute: task.minute, isAm: task.hour < 12);
    }
    setRemind(task.remind);
    setWeekdays(
        task.weekdays.isEmpty ? {selected.weekday} : task.weekdays.toSet());
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
      durationMinutes: task.durationMinutes,
      isAm: task.hour < 12,
      repeat: task.isRescheduled ? RepeatRule.once : task.repeat,
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
  void setDate(DateTime value) =>
      state = state.copyWith(date: value, clearConflict: true);
  void setTime({required int hour, required int minute, required bool isAm}) =>
      state = state.copyWith(
          hour: hour, minute: minute, isAm: isAm, clearConflict: true);
  void setRepeat(RepeatRule value) =>
      state = state.copyWith(repeat: value, clearConflict: true);
  void setWeekdays(Set<int> value) =>
      state = state.copyWith(weekdays: value, clearConflict: true);
  void setDuration(int value) {
    if (value >= 1 && value <= 240) {
      state = state.copyWith(durationMinutes: value, clearConflict: true);
    }
  }

  void setRemind(bool value) => state = state.copyWith(remind: value);
  void restoreEditing() => state =
      state.copyWith(saveState: TaskSaveState.editing, clearError: true);

  /// Chặn bấm Lưu lần hai khi đang kiểm tra trùng giờ (trước khi `saving`).
  bool _checking = false;

  Future<bool> save({ChangeScope? scope}) async {
    if (_checking || state.saveState == TaskSaveState.saving) return false;
    _checking = true;
    try {
      return await _save(scope);
    } finally {
      _checking = false;
    }
  }

  Future<bool> _save(ChangeScope? scope) async {
    if (state.title.trim().isEmpty ||
        state.title.trim().length > 80 ||
        state.isTimeInPastToday) {
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
      durationMinutes: state.durationMinutes,
      status: before?.status ?? TaskStatus.pending,
      startDate: before?.startDate ??
          dateKey(before != null ? _editDay! : state.date ?? DateTime.now()),
      weekdays: state.repeat == RepeatRule.someDays ||
              state.repeat == RepeatRule.weekly
          ? state.weekdays.toList()
          : const [],
    );
    final occurrenceOnly = before != null &&
        (before.isRescheduled ||
            (before.repeat != RepeatRule.once && scope == ChangeScope.once));
    TaskItem? overlap;
    try {
      overlap = await findScheduleConflict(
          ref.read(taskRepositoryProvider), task,
          ignoreId: before?.id, onlyDay: occurrenceOnly ? _editDay : null);
    } catch (_) {/* chưa tải được lịch: không chặn, lưu như cũ */}
    if (!ref.mounted) return false;
    if (overlap != null) {
      state = state.copyWith(conflictMessage: overlapMessage(overlap));
      return false;
    }
    state = state.copyWith(
        saveState: TaskSaveState.saving,
        showValidation: false,
        clearConflict: true);
    try {
      final repository = ref.read(taskRepositoryProvider);
      if (before != null && repository is ScopedTaskRepository) {
        _scopedUndo =
            await (repository as ScopedTaskRepository).changeOccurrence(
                before,
                _editDay!,
                task,
                before.isRescheduled
                    ? schedule.ChangeScope.occurrence
                    : before.repeat == RepeatRule.once
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
      ref.invalidate(recentActivitiesProvider);
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
            ? 'Chưa lưu được. Bác kiểm tra kết nối rồi thử lại nhé.'
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
        _scopedUndo =
            await (repository as ScopedTaskRepository).changeOccurrence(
                task,
                _editDay ?? DateTime.now(),
                null,
                switch (scope) {
                  ChangeScope.once => task.repeat == RepeatRule.once
                      ? schedule.ChangeScope.all
                      : schedule.ChangeScope.occurrence,
                  ChangeScope.thisAndFollowing => schedule.ChangeScope.future,
                  ChangeScope.all => schedule.ChangeScope.all,
                });
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
