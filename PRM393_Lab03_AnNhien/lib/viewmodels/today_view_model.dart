import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_item.dart';
import '../services/providers.dart';
import 'ui_state.dart';

/// F3 Hôm nay – chủ: Khang. Ví dụ MVVM mẫu cho cả nhóm làm theo:
/// mọi tính toán (đếm việc xong, việc tiếp theo) nằm ở đây, KHÔNG nằm trong build().
class TodayData {
  const TodayData({required this.tasks, this.refreshError});
  final List<TaskItem> tasks;
  final String? refreshError;
  Iterable<TaskItem> get remaining => tasks.where((task) =>
      task.status == TaskStatus.pending || task.status == TaskStatus.postponed);
  int get skippedCount =>
      tasks.where((task) => task.status == TaskStatus.skipped).length;

  int get doneCount => tasks.where((t) => t.isDone).length;
  int get total => tasks.length;
  TaskItem? get next => remaining.firstOrNull;
}

class TodayViewModel extends Notifier<UiState<TodayData>> {
  int _loadGeneration = 0;
  @override
  UiState<TodayData> build() {
    ++_loadGeneration;
    Future.microtask(load);
    return const UiLoading();
  }

  Future<void> load() async {
    if (!ref.mounted) return;
    final generation = ++_loadGeneration;
    final previous =
        state is UiData<TodayData> ? (state as UiData<TodayData>).data : null;
    if (previous == null) state = const UiLoading();
    try {
      final tasks =
          await ref.read(taskRepositoryProvider).tasksForDay(DateTime.now());
      if (!ref.mounted || generation != _loadGeneration) return;
      final sorted = [...tasks]..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      state =
          sorted.isEmpty ? const UiEmpty() : UiData(TodayData(tasks: sorted));
    } catch (e, st) {
      if (!ref.mounted || generation != _loadGeneration) return;
      state = previous == null
          ? const UiError('Chưa tải được việc hôm nay.')
          : UiData(TodayData(
              tasks: previous.tasks,
              refreshError:
                  'Chưa cập nhật được. Lịch đang hiển thị vẫn được giữ lại.'));
      try {
        unawaited(ref
            .read(crashServiceProvider)
            .recordError(e, st, reason: 'load_today')
            .catchError((Object _) {}));
      } catch (_) {}
    }
  }

  Future<void> markDone(String taskId) async {
    await _setStatus(taskId, TaskStatus.done);
    // Saved state must not wait for analytics or connectivity.
    try {
      unawaited(ref.read(analyticsServiceProvider).logEvent(
          'complete_task', {'task_id': taskId}).catchError((Object _) {}));
    } catch (_) {}
  }

  Future<void> undo(String taskId,
          {TaskStatus previousStatus = TaskStatus.pending}) =>
      _setStatus(taskId, previousStatus);

  Future<void> _setStatus(String taskId, TaskStatus status) async {
    await ref.read(taskRepositoryProvider).setStatus(taskId, status);
    if (!ref.mounted) return;
    ++_loadGeneration; // Ignore refresh results fetched before this saved change.
    final current = state;
    if (current is UiData<TodayData>) {
      state = UiData(TodayData(tasks: [
        for (final task in current.data.tasks)
          task.id == taskId ? task.copyWith(status: status) : task,
      ]));
    }
  }
}

final todayViewModelProvider =
    NotifierProvider<TodayViewModel, UiState<TodayData>>(TodayViewModel.new);
