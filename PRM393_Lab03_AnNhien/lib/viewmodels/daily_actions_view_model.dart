import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../services/providers.dart';
import '../services/task_repository.dart';
import '../utils/app_error.dart';
import 'calm_feature_providers.dart';
import 'session_view_model.dart';
import 'today_view_model.dart';

DateTime vietnamNow() => clock.now().toUtc().add(const Duration(hours: 7));
TaskItem? nextPendingTask(List<TaskItem> tasks, DateTime day, DateTime now) {
  final pending = tasks
      .where((t) =>
          t.status == TaskStatus.pending || t.status == TaskStatus.postponed)
      .toList()
    ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  if (pending.isEmpty) return null;
  if (dateKey(day) != dateKey(now)) return pending.first;
  return pending
          .where((t) => t.hour * 60 + t.minute >= now.hour * 60 + now.minute)
          .firstOrNull ??
      pending.last;
}

class QuickTaskUndo {
  const QuickTaskUndo(this.uid, this.task, this.day, {this.move});
  final String uid;
  final TaskItem task;
  final DateTime day;
  final TaskRescheduleChange? move;
}

class DailyActionsViewModel extends Notifier<bool> {
  @override
  bool build() => false;
  String _uid() =>
      ref.read(sessionProvider).value?.uid ??
      (throw const AppException('Bác đăng nhập lại nhé.'));
  void _refresh() {
    ref.invalidate(calendarTasksProvider);
    ref.invalidate(todayViewModelProvider);
  }

  Future<QuickTaskUndo?> complete(TaskItem task, DateTime day) async {
    if (state) return null;
    final uid = _uid();
    state = true;
    try {
      await ref.read(calendarActionsProvider.notifier).setDone(task, day);
      return QuickTaskUndo(uid, task, day);
    } finally {
      if (ref.mounted) state = false;
    }
  }

  Future<QuickTaskUndo?> move(
      TaskItem task, DateTime day, DateTime target) async {
    if (state) return null;
    final uid = _uid(), now = vietnamNow();
    if (dateKey(day) != dateKey(now) ||
        !target.isAfter(
            DateTime(now.year, now.month, now.day, now.hour, now.minute))) {
      throw const AppException(
          'Bác chọn ngày, giờ sau thời điểm hiện tại nhé.');
    }
    state = true;
    try {
      final change = await ref.read(taskRepositoryProvider).reschedule(task,
          targetDay: target, hour: target.hour, minute: target.minute);
      _refresh();
      return QuickTaskUndo(uid, task, day, move: change);
    } finally {
      if (ref.mounted) state = false;
    }
  }

  Future<void> undo(QuickTaskUndo change) async {
    if (_uid() != change.uid)
      throw const AppException('Tài khoản đã thay đổi. Bác mở lại lịch nhé.');
    if (change.move != null) {
      await ref.read(taskRepositoryProvider).restoreReschedule(change.move!);
    } else {
      if (dateKey(change.day) != dateKey(vietnamNow()))
        throw const AppException('Đã sang ngày mới. Bác mở lại lịch nhé.');
      await ref
          .read(todayViewModelProvider.notifier)
          .undo(change.task.id, previousStatus: change.task.status);
    }
    _refresh();
  }
}

final dailyActionsProvider =
    NotifierProvider<DailyActionsViewModel, bool>(DailyActionsViewModel.new);
