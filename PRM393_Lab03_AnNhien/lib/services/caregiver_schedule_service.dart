import 'schedule_limits.dart';
import 'task_repository.dart' show TaskReschedule;
import 'dart:async';
import '../models/task_item.dart';
import '../utils/app_error.dart';

enum ChangeScope { occurrence, future, all }

class ScheduleOccurrence {
  const ScheduleOccurrence(this.task, this.date);
  final TaskItem task;
  final DateTime date;
}

class ScheduleUndo {
  ScheduleUndo(this.momUid, this.before, this.after,
      {this.reschedulesBefore = const {}, this.reschedulesAfter = const {}});
  final Map<String, TaskReschedule?> reschedulesBefore, reschedulesAfter;
  final String momUid;
  final Map<String, TaskItem?> before, after;
  bool used = false;
}

abstract interface class CaregiverScheduleService {
  Future<List<TaskItem>> templates(String momUid);
  Stream<List<ScheduleOccurrence>> watch(
      String momUid, DateTime from, DateTime through);
  Future<void> create(String momUid, TaskItem task);
  Future<ScheduleUndo> change(String momUid, TaskItem original, DateTime day,
      TaskItem? replacement, ChangeScope scope);
  Future<void> undo(ScheduleUndo change);
}

/// Cùng một thuật toán scope cho Fake và Firebase; không xoá completion lịch sử.
({Map<String, TaskItem?> before, Map<String, TaskItem?> after})
    planScheduleChange(TaskItem current, DateTime day, TaskItem? replacement,
        ChangeScope scope, String newId,
        {TaskReschedule? moved}) {
  if (moved != null) {
    if (moved.taskId != current.id ||
        moved.targetDate != dateKey(day) ||
        !current.occursOn(DateTime.parse(moved.sourceDate))) {
      throw const AppException(
          'Lần việc đã dời đã thay đổi. Bác tải lại lịch nhé.');
    }
    // Editing a moved occurrence detaches that occurrence; the series stays intact.
    final recurring = current.repeat == RepeatRule.once &&
        replacement?.repeat != RepeatRule.once;
    return (
      before: {current.id: current, if (replacement != null) newId: null},
      after: {
        current.id: current.copyWith(
            excludedDates:
                {...current.excludedDates, moved.sourceDate}.toList(),
            revision: current.revision + 1),
        if (replacement != null)
          newId: replacement.copyWith(
              id: newId,
              completionSourceId: current.id,
              startDate: dateKey(day),
              endDate: recurring ? null : dateKey(day),
              clearEndDate: recurring,
              repeat: recurring ? replacement.repeat : RepeatRule.once,
              excludedDates: [],
              revision: 0),
      }
    );
  }
  if (!current.occursOn(day)) {
    throw const AppException(
        'Lần nhắc này đã thay đổi. Tải lại lịch rồi thử lại.');
  }
  final key = dateKey(day);
  final before = <String, TaskItem?>{current.id: current};
  final after = <String, TaskItem?>{};
  switch (scope) {
    case ChangeScope.all:
      // Ngưng giữ toàn bộ lịch sử trước ngày chọn; không xoá series.
      after[current.id] = replacement?.copyWith(
              id: current.id, revision: current.revision + 1) ??
          current.copyWith(
              endDate:
                  dateKey(calendarDate(day).subtract(const Duration(days: 1))),
              revision: current.revision + 1);
    case ChangeScope.occurrence:
      after[current.id] = current.copyWith(
          excludedDates: [...current.excludedDates, key],
          revision: current.revision + 1);
      if (replacement != null) {
        before[newId] = null;
        after[newId] = replacement.copyWith(
            id: newId,
            completionSourceId: current.id,
            repeat: RepeatRule.once,
            startDate: key,
            endDate: key,
            excludedDates: [],
            revision: 0);
      }
    case ChangeScope.future:
      after[current.id] = current.copyWith(
          endDate: dateKey(calendarDate(day).subtract(const Duration(days: 1))),
          revision: current.revision + 1);
      if (replacement != null) {
        before[newId] = null;
        after[newId] = replacement.copyWith(
            id: newId,
            completionSourceId: current.id,
            startDate: key,
            revision: 0,
            excludedDates: current.excludedDates
                .where((d) => d.compareTo(key) >= 0)
                .toList());
      }
  }
  return (before: before, after: after);
}

class FakeCaregiverScheduleService implements CaregiverScheduleService {
  FakeCaregiverScheduleService([Iterable<TaskItem> seed = const []])
      : tasks = {for (final t in seed) t.id: t};
  final Map<String, TaskItem> tasks;
  final _changes = StreamController<void>.broadcast(sync: true);
  final reschedules = <String, TaskReschedule>{};
  bool fail = false;
  void _check() {
    if (fail) throw AppException.network;
  }

  List<ScheduleOccurrence> _range(DateTime from, DateTime through) {
    final list = <ScheduleOccurrence>[];
    for (var d = calendarDate(from);
        !d.isAfter(through);
        d = d.add(const Duration(days: 1))) {
      for (final t in tasks.values.where((t) =>
          t.occursOn(d) && !reschedules.containsKey('${t.id}_${dateKey(d)}'))) {
        list.add(ScheduleOccurrence(t, d));
      }
    }
    for (final r in reschedules.values) {
      final day = DateTime.parse(r.targetDate), task = tasks[r.taskId];
      if (task != null &&
          !day.isBefore(calendarDate(from)) &&
          !day.isAfter(calendarDate(through))) {
        list.add(ScheduleOccurrence(
            task.copyWith(
                hour: r.hour,
                minute: r.minute,
                occurrenceDate: r.targetDate,
                rescheduleSourceDate: r.sourceDate,
                isRescheduled: true),
            day));
      }
    }
    list.sort((a, b) =>
        ('${dateKey(a.date)}${a.task.hour.toString().padLeft(2, '0')}${a.task.minute.toString().padLeft(2, '0')}')
            .compareTo(
                '${dateKey(b.date)}${b.task.hour.toString().padLeft(2, '0')}${b.task.minute.toString().padLeft(2, '0')}'));
    return list;
  }

  Future<void> acceptTasks(List<TaskItem> incoming) async {
    _check();
    for (final task in incoming) {
      task.validate();
    }
    for (final task in incoming) {
      tasks.putIfAbsent(task.id, () => task);
    }
    _changes.add(null);
  }

  @override
  Future<List<TaskItem>> templates(String momUid) async {
    _check();
    return List.unmodifiable(tasks.values);
  }

  @override
  Stream<List<ScheduleOccurrence>> watch(
          String momUid, DateTime from, DateTime through) =>
      Stream.multi((sink) {
        void emit() {
          try {
            _check();
            sink.add(_range(from, through));
          } catch (e, st) {
            sink.addError(e, st);
          }
        }

        final sub = _changes.stream.listen((_) => emit());
        emit();
        sink.onCancel = sub.cancel;
      });
  @override
  Future<void> create(String momUid, TaskItem task) async {
    _check();
    task.validate();
    if (tasks.containsKey(task.id)) return;
    validateScheduleLimits([...tasks.values, task], reschedules.values.toList(),
        {task.id}, DateTime.parse(task.startDate ?? dateKey(DateTime.now())));
    tasks[task.id] = task;
    _changes.add(null);
  }

  @override
  Future<ScheduleUndo> change(String momUid, TaskItem original, DateTime day,
      TaskItem? replacement, ChangeScope scope) async {
    _check();
    final current = tasks[original.id];
    if (current == null || current.revision != original.revision) {
      throw const AppException('Lịch đã thay đổi. Tải lại rồi thử lại.');
    }
    final movedKey =
        '${original.id}_${original.rescheduleSourceDate ?? dateKey(day)}';
    final candidate = reschedules[movedKey];
    final moved = candidate?.targetDate == dateKey(day) ? candidate : null;
    final plan = planScheduleChange(current, day, replacement, scope,
        '${current.id}-${DateTime.now().microsecondsSinceEpoch}',
        moved: moved);
    if (replacement != null) {
      final prospective = Map<String, TaskItem>.of(tasks);
      for (final e in plan.after.entries) {
        if (e.value == null) {
          prospective.remove(e.key);
        } else {
          prospective[e.key] = e.value!;
        }
      }
      validateScheduleLimits(
          prospective.values.toList(),
          reschedules.entries
              .where((e) => moved == null || e.key != movedKey)
              .map((e) => e.value)
              .toList(),
          plan.after.keys.toSet(),
          day);
    }
    for (final e in plan.after.entries) {
      if (e.value == null) {
        tasks.remove(e.key);
      } else {
        tasks[e.key] = e.value!;
      }
    }
    _changes.add(null);
    if (moved != null) reschedules.remove(movedKey);
    return ScheduleUndo(momUid, plan.before, plan.after,
        reschedulesBefore: {if (moved != null) movedKey: moved},
        reschedulesAfter: {if (moved != null) movedKey: null});
  }

  @override
  Future<void> undo(ScheduleUndo change) async {
    _check();
    if (change.used) throw const AppException('Thay đổi này đã được hoàn tác.');
    for (final e in change.after.entries) {
      if (tasks[e.key]?.revision != e.value?.revision) {
        throw const AppException('Lịch đã được sửa tiếp. Không thể hoàn tác.');
      }
    }
    final prospective = Map<String, TaskItem>.of(tasks);
    for (final e in change.before.entries) {
      if (e.value == null) {
        prospective.remove(e.key);
      } else {
        prospective[e.key] = e.value!;
      }
    }
    final restoredMoves = Map<String, TaskReschedule>.of(reschedules);
    for (final e in change.reschedulesBefore.entries) {
      if (e.value == null) {
        restoredMoves.remove(e.key);
      } else {
        restoredMoves[e.key] = e.value!;
      }
    }
    validateScheduleLimits(
        prospective.values.toList(),
        restoredMoves.values.toList(),
        change.before.keys.toSet(),
        DateTime.now());
    for (final e in change.before.entries) {
      if (e.value == null) {
        tasks.remove(e.key);
      } else {
        tasks[e.key] = e.value!.copyWith(revision: tasks[e.key]!.revision + 1);
      }
    }
    for (final e in change.reschedulesBefore.entries) {
      if (e.value == null) {
        reschedules.remove(e.key);
      } else {
        reschedules[e.key] = e.value!;
      }
    }
    change.used = true;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
