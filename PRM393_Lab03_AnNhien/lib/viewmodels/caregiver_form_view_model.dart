import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import '../services/caregiver_schedule_service.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'caregiver_schedule_view_model.dart';
import 'session_view_model.dart';

final caregiverHabitsProvider = FutureProvider<List<Habit>>(
    (ref) => ref.watch(habitRepositoryProvider).all());
String _id() =>
    List.generate(16, (_) => Random.secure().nextInt(16).toRadixString(16))
        .join();

class CaregiverFormState {
  const CaregiverFormState(
      {required this.task,
      this.original,
      this.occurrence,
      this.message = '',
      this.needsConsent = true,
      this.busy = false,
      this.error,
      this.conflicts = const [],
      this.saved = false,
      this.scope = ChangeScope.future});
  final TaskItem task;
  final TaskItem? original;
  final DateTime? occurrence;
  final String message;
  final bool needsConsent, busy, saved;
  final String? error;
  final List<TaskItem> conflicts;
  final ChangeScope scope;
  CaregiverFormState copyWith(
          {TaskItem? task,
          String? message,
          bool? needsConsent,
          bool? busy,
          String? error,
          List<TaskItem>? conflicts,
          bool? saved,
          ChangeScope? scope}) =>
      CaregiverFormState(
          task: task ?? this.task,
          original: original,
          occurrence: occurrence,
          message: message ?? this.message,
          needsConsent: needsConsent ?? this.needsConsent,
          busy: busy ?? this.busy,
          error: error,
          conflicts: conflicts ?? const [],
          saved: saved ?? this.saved,
          scope: scope ?? this.scope);
}

class CaregiverFormViewModel extends Notifier<CaregiverFormState> {
  DateTime _started = DateTime.now();
  int _generation = 0;
  @override
  CaregiverFormState build() {
    ref.watch(sessionProvider.select((s) => s.value?.uid));
    _generation++;
    return _fresh();
  }

  CaregiverFormState _fresh() => CaregiverFormState(
      task: TaskItem(
          id: _id(),
          title: '',
          habitKey: 'move',
          hour: 8,
          minute: 0,
          startDate: dateKey(vietnamToday()),
          repeat: RepeatRule.weekly,
          weekdays: [vietnamToday().weekday]));
  void start({TaskItem? existing, DateTime? occurrence}) {
    _generation++;
    _started = DateTime.now();
    state = existing == null
        ? _fresh()
        : CaregiverFormState(
            task: existing,
            original: existing,
            occurrence: occurrence ?? vietnamToday(),
            needsConsent: false);
  }

  void updateTask(TaskItem task) {
    if (!state.busy) state = state.copyWith(task: task);
  }

  void message(String value) {
    if (!state.busy) state = state.copyWith(message: value);
  }

  void consent(bool value) {
    if (!state.busy) state = state.copyWith(needsConsent: value);
  }

  void scope(ChangeScope value) {
    if (!state.busy) state = state.copyWith(scope: value);
  }

  bool validate() {
    try {
      if (state.task.title.trim().isEmpty) {
        throw const FormatException(
            'Hãy nhập tên việc để mẹ biết cần làm gì. Ví dụ: Đi bộ buổi sáng.');
      }
      state.task.validate();
      if (state.task.startDate == null) {
        throw const FormatException('Chọn ngày bắt đầu.');
      }
      return true;
    } catch (e) {
      state = state.copyWith(
          error: e is FormatException
              ? e.message.toString()
              : 'Kiểm tra lại tên và giờ. Ví dụ: Đi bộ, 8:00 sáng.');
      return false;
    }
  }

  Future<bool> submit({bool allowConflict = false}) async {
    if (state.busy || state.saved || !validate()) return false;
    final mom = ref.read(pairedMomUidProvider);
    if (mom == null) {
      state = state.copyWith(error: 'Cần ghép nối với máy của mẹ trước.');
      return false;
    }
    final input = state;
    final generation = _generation;
    final schedules = ref.read(caregiverScheduleServiceProvider);
    final suggestions = ref.read(caregiverSuggestionServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final crash = ref.read(crashServiceProvider);
    state = input.copyWith(busy: true);
    try {
      final templates = await schedules.templates(mom);
      if (!ref.mounted || generation != _generation) return false;
      final candidate = input.original == null || input.scope == ChangeScope.all
          ? input.task
          : input.task.copyWith(
              startDate: dateKey(input.occurrence!),
              endDate: input.scope == ChangeScope.occurrence
                  ? dateKey(input.occurrence!)
                  : input.task.endDate,
              repeat: input.scope == ChangeScope.occurrence
                  ? RepeatRule.once
                  : input.task.repeat);
      final conflicts = templates
          .where((task) =>
              task.id != input.original?.id &&
              schedulesConflict(candidate, task))
          .toList();
      if (!allowConflict && conflicts.isNotEmpty) {
        if (ref.mounted) {
          state = input.copyWith(
              conflicts: conflicts,
              error:
                  'Có việc trùng giờ trong lịch. Đổi giờ hoặc chọn vẫn gửi.');
        }
        return false;
      }
      if (input.original != null) {
        await schedules.change(
            mom, input.original!, input.occurrence!, input.task, input.scope);
      } else if (input.needsConsent) {
        await suggestions.send(mom, input.task.id, [input.task],
            message: input.message);
      } else {
        await schedules.create(mom, input.task);
      }
      try {
        await analytics.logEvent('create_recurring_task', {
          'repeat': input.task.repeat.name,
          'requires_consent': input.needsConsent ? 1 : 0,
          'duration_sec': DateTime.now().difference(_started).inSeconds,
          'is_edit': input.original == null ? 0 : 1
        });
      } catch (_) {}
      if (!ref.mounted || generation != _generation) return false;
      state = input.copyWith(saved: true);
      return true;
    } catch (e, st) {
      try {
        await crash.recordError(e, st, reason: 'save_caregiver_task');
      } catch (_) {}
      if (ref.mounted && generation == _generation) {
        state = input.copyWith(
            error: e is AppException
                ? e.userMessage
                : 'Chưa lưu được lịch. Dữ liệu nhập vẫn còn, thử lại nhé.');
      }
      return false;
    }
  }
}

final caregiverFormViewModelProvider =
    NotifierProvider<CaregiverFormViewModel, CaregiverFormState>(
        CaregiverFormViewModel.new);
