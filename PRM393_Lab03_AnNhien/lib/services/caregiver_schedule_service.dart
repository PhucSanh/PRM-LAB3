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
  ScheduleUndo(this.momUid, this.before, this.after);
  final String momUid;
  final Map<String, TaskItem?> before, after;
  bool used = false;
}

abstract interface class CaregiverScheduleService {
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
        ChangeScope scope, String newId) {
  if (!current.occursOn(day))
    throw const AppException(
        'Lần nhắc này đã thay đổi. Tải lại lịch rồi thử lại.');
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
  bool fail = false;
  void _check() {
    if (fail) throw AppException.network;
  }

  List<ScheduleOccurrence> _range(DateTime from, DateTime through) {
    final list = <ScheduleOccurrence>[];
    for (var d = calendarDate(from);
        !d.isAfter(through);
        d = d.add(const Duration(days: 1))) {
      for (final t in tasks.values.where((t) => t.occursOn(d))) {
        list.add(ScheduleOccurrence(t, d));
      }
    }
    list.sort((a, b) =>
        ('${dateKey(a.date)}${a.task.hour.toString().padLeft(2, '0')}${a.task.minute.toString().padLeft(2, '0')}')
            .compareTo(
                '${dateKey(b.date)}${b.task.hour.toString().padLeft(2, '0')}${b.task.minute.toString().padLeft(2, '0')}'));
    return list;
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
    tasks[task.id] = task;
    _changes.add(null);
  }

  @override
  Future<ScheduleUndo> change(String momUid, TaskItem original, DateTime day,
      TaskItem? replacement, ChangeScope scope) async {
    _check();
    final current = tasks[original.id];
    if (current == null || current.revision != original.revision)
      throw const AppException('Lịch đã thay đổi. Tải lại rồi thử lại.');
    final plan = planScheduleChange(current, day, replacement, scope,
        '${current.id}-${DateTime.now().microsecondsSinceEpoch}');
    for (final e in plan.after.entries) {
      if (e.value == null) {
        tasks.remove(e.key);
      } else {
        tasks[e.key] = e.value!;
      }
    }
    _changes.add(null);
    return ScheduleUndo(momUid, plan.before, plan.after);
  }

  @override
  Future<void> undo(ScheduleUndo change) async {
    _check();
    if (change.used) throw const AppException('Thay đổi này đã được hoàn tác.');
    for (final e in change.after.entries) {
      if (tasks[e.key]?.revision != e.value?.revision)
        throw const AppException('Lịch đã được sửa tiếp. Không thể hoàn tác.');
    }
    for (final e in change.before.entries) {
      if (e.value == null) {
        tasks.remove(e.key);
      } else {
        tasks[e.key] = e.value!.copyWith(revision: tasks[e.key]!.revision + 1);
      }
    }
    change.used = true;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
