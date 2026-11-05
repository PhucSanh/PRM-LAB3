import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_item.dart';
import '../services/providers.dart';
import 'today_view_model.dart';
import 'ui_state.dart';

/// ViewModel cho S04. Tải một task từ cùng nguồn dữ liệu F3/F4; các thao tác
/// thay đổi trạng thái được ủy quyền cho [TodayViewModel] để không nhân bản logic.
class TaskDetailViewModel extends Notifier<UiState<TaskItem>> {
  @override
  UiState<TaskItem> build() => const UiLoading();

  Future<void> load(String taskId,
      {DateTime? day, bool showLoading = true}) async {
    if (!ref.mounted) return;
    if (showLoading) state = const UiLoading();
    try {
      final tasks = await ref
          .read(taskRepositoryProvider)
          .tasksForDay(day ?? DateTime.now());
      final task = tasks.where((item) => item.id == taskId).firstOrNull;
      if (!ref.mounted) return;
      state = task == null
          ? const UiError('Không tìm thấy việc này.')
          : UiData(task);
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      await ref
          .read(crashServiceProvider)
          .recordError(error, stackTrace, reason: 'load_task_detail');
      if (!ref.mounted) return;
      state = const UiError('Chưa tải được chi tiết việc.');
    }
  }

  Future<TodayViewModel> _today() async {
    final today = ref.read(todayViewModelProvider.notifier);
    await Future<void>.value();
    // Route S04 cũng có thể được mở trực tiếp từ deep-link, khi S03 chưa load.
    if (today.taskById(_taskId) == null) await today.load();
    return today;
  }

  String get _taskId => switch (state) {
        UiData(:final data) => data.id,
        _ => '',
      };

  Future<bool> complete(String taskId) async =>
      (await _today()).markDone(taskId, source: 'detail');

  Future<bool> skip(String taskId) async => (await _today()).skip(taskId);

  Future<bool> postpone(String taskId, PostponeOption option,
          {DateTime? targetDay, int? targetHour, int? targetMinute}) async =>
      (await _today()).postpone(taskId, option,
          targetDay: targetDay,
          targetHour: targetHour,
          targetMinute: targetMinute);

  Future<bool> undoLastAction() =>
      ref.read(todayViewModelProvider.notifier).undoLastAction();
}

final taskDetailViewModelProvider =
    NotifierProvider<TaskDetailViewModel, UiState<TaskItem>>(
        TaskDetailViewModel.new);
