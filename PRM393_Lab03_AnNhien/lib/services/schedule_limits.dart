import 'dart:isolate';
import '../models/task_item.dart';
import '../utils/app_error.dart';
import 'task_repository.dart';

String activityIdentity(String title) =>
    title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Checks effective occurrences, including moved/excluded dates, rather than
/// merely comparing templates. Gregorian weekdays/months repeat every 400 years.
void validateScheduleLimits(List<TaskItem> templates,
    List<TaskReschedule> moves, Set<String> changedIds, DateTime from) {
  final start = calendarDate(from);
  final moveBySource = {for (final move in moves) move.key: move};
  for (final candidate in templates.where((t) => changedIds.contains(t.id))) {
    final names = templates
        .where((t) =>
            activityIdentity(t.title) == activityIdentity(candidate.title))
        .length;
    final possibleTimes = {
      candidate.hour * 60 + candidate.minute,
      ...moves
          .where((m) => m.taskId == candidate.id)
          .map((m) => m.hour * 60 + m.minute)
    };
    final related = templates
        .where((t) =>
            t.id == candidate.id ||
            activityIdentity(t.title) == activityIdentity(candidate.title) ||
            possibleTimes.contains(t.hour * 60 + t.minute) ||
            moves.any((m) =>
                m.taskId == t.id &&
                possibleTimes.contains(m.hour * 60 + m.minute)))
        .toList();
    if (related.length < 2 && names < 3) continue;
    var first = start;
    if (candidate.startDate != null &&
        DateTime.parse(candidate.startDate!).isAfter(first)) {
      first = DateTime.parse(candidate.startDate!);
    }
    final ownMoves = moves.where((m) => m.taskId == candidate.id).toList();
    for (final move in ownMoves) {
      final target = DateTime.parse(move.targetDate);
      if (!target.isBefore(start) && target.isBefore(first)) first = target;
    }
    var lastBoundary = first;
    for (final t in related) {
      for (final value in [t.startDate, t.endDate, ...t.excludedDates]) {
        if (value != null && DateTime.parse(value).isAfter(lastBoundary)) {
          lastBoundary = DateTime.parse(value);
        }
      }
    }
    for (final move in moves) {
      final date = DateTime.parse(move.targetDate);
      if (date.isAfter(lastBoundary)) lastBoundary = date;
    }
    var end =
        DateTime(lastBoundary.year + 400, lastBoundary.month, lastBoundary.day);
    if (candidate.endDate != null &&
        DateTime.parse(candidate.endDate!).isBefore(end)) {
      end = DateTime.parse(candidate.endDate!);
    }
    for (final move in ownMoves) {
      final target = DateTime.parse(move.targetDate);
      if (target.isAfter(end)) end = target;
    }
    if (candidate.repeat == RepeatRule.once &&
        !moves.any((m) => m.taskId == candidate.id)) {
      end = first;
    }
    for (var day = first;
        !day.isAfter(end);
        day = DateTime(day.year, day.month, day.day + 1)) {
      final key = dateKey(day);
      final daily = <TaskItem>[];
      for (final t in related) {
        if (t.occursOn(day) && !moveBySource.containsKey('${t.id}_$key')) {
          daily.add(t);
        }
        for (final m
            in moves.where((m) => m.taskId == t.id && m.targetDate == key)) {
          daily.add(t.copyWith(hour: m.hour, minute: m.minute));
        }
      }
      final focused = daily.where((t) => t.id == candidate.id).toList();
      for (final item in focused) {
        final sameTime = daily
            .where((t) => t.hour == item.hour && t.minute == item.minute)
            .length;
        if (sameTime > 1) {
          throw AppException(
              'Ngày ${day.day}/${day.month}/${day.year} đã có việc lúc ${item.hour.toString().padLeft(2, '0')}:${item.minute.toString().padLeft(2, '0')}. Bác chọn giờ khác nhé.');
        }
        final sameName = daily
            .where((t) =>
                activityIdentity(t.title) == activityIdentity(item.title))
            .length;
        if (sameName > 2) {
          throw AppException(
              'Hoạt động “${item.title}” đã có 2 lần trong ngày ${day.day}/${day.month}/${day.year}. Mỗi hoạt động chỉ được tối đa 2 lần/ngày.');
        }
      }
    }
  }
}

Future<void> validateScheduleLimitsAsync(List<TaskItem> tasks,
        List<TaskReschedule> moves, Set<String> changedIds, DateTime from) =>
    Isolate.run(() => validateScheduleLimits(tasks, moves, changedIds, from));
