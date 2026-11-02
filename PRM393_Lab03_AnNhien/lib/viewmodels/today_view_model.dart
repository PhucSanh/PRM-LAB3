import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_item.dart';
import '../services/providers.dart';
import 'ui_state.dart';

/// F3 Hôm nay – chủ: Khang. Ví dụ MVVM mẫu cho cả nhóm làm theo:
/// mọi tính toán (đếm việc xong, việc tiếp theo) nằm ở đây, KHÔNG nằm trong build().
class TodayData {
  const TodayData({required this.tasks});
  final List<TaskItem> tasks;

  int get doneCount => tasks.where((t) => t.isDone).length;
  int get total => tasks.length;
  TaskItem? get next => tasks.where((t) => t.status == TaskStatus.pending).firstOrNull;
}

class TodayViewModel extends Notifier<UiState<TodayData>> {
  @override
  UiState<TodayData> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  Future<void> load() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    try {
      final tasks = await ref.read(taskRepositoryProvider).tasksForDay(DateTime.now());
      if (!ref.mounted) return;
      final sorted = [...tasks]..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      state = sorted.isEmpty ? const UiEmpty() : UiData(TodayData(tasks: sorted));
    } catch (e, st) {
      if (!ref.mounted) return;
      await ref.read(crashServiceProvider).recordError(e, st, reason: 'load_today');
      if (!ref.mounted) return;
      state = const UiError('Chưa tải được việc hôm nay.');
    }
  }

  Future<void> markDone(String taskId) async {
    await ref.read(taskRepositoryProvider).setStatus(taskId, TaskStatus.done);
    await ref.read(analyticsServiceProvider).logEvent('complete_task', {'task_id': taskId});
    await load();
  }

  /// Hoàn tác (snackbar) – trả việc về "Chưa làm".
  Future<void> undo(String taskId) async {
    await ref.read(taskRepositoryProvider).setStatus(taskId, TaskStatus.pending);
    await load();
  }
}

final todayViewModelProvider = NotifierProvider<TodayViewModel, UiState<TodayData>>(TodayViewModel.new);
