import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_item.dart';
import '../services/providers.dart';
import '../services/remote_config_service.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

/// Dữ liệu hiển thị của S14. Không giữ tên việc trong Analytics.
class ReminderData {
  const ReminderData({
    required this.task,
    required this.snoozeMinutes,
    required this.preview,
  });

  final TaskItem task;
  final int snoozeMinutes;
  final bool preview;
}

/// F6 S14 – tải occurrence hôm nay, đọc Remote Config và thực hiện thao tác
/// thông qua interface service. UI chỉ vẽ [UiState] và điều hướng sau kết quả.
class ReminderViewModel extends Notifier<UiState<ReminderData>> {
  @override
  UiState<ReminderData> build() => const UiLoading();

  Future<void> load(String id, {bool preview = false}) async {
    state = const UiLoading();
    try {
      final task = preview ? _previewTask : await _findTask(id);
      if (task == null) {
        state = const UiError('Không tìm thấy việc này trong lịch hôm nay.');
        return;
      }
      final configured = ref
          .read(remoteConfigServiceProvider)
          .getInt(RemoteConfigKeys.snoozeMinutes);
      state = UiData(ReminderData(
        task: task,
        snoozeMinutes: configured > 0 ? configured : 10,
        preview: preview,
      ));
    } catch (error, stack) {
      await _record(error, stack, 'load_reminder');
      state = UiError(error is AppException
          ? error.userMessage
          : 'Chưa tải được lời nhắc. Bác thử lại nhé.');
    }
  }

  Future<TaskItem?> _findTask(String id) async {
    final tasks =
        await ref.read(taskRepositoryProvider).tasksForDay(DateTime.now());
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Bắt đầu làm chỉ đóng lời nhắc; hoàn thành là thao tác riêng ở F3/S04.
  Future<bool> start() => _action('start');

  Future<bool> snooze() async {
    final data = _data;
    if (data == null || data.preview) return data?.preview == true;
    try {
      await ref
          .read(reminderServiceProvider)
          .snooze(data.task.id, data.snoozeMinutes);
      await _log('snooze', data.snoozeMinutes);
      return true;
    } catch (error, stack) {
      await _record(error, stack, 'snooze_reminder');
      return false;
    }
  }

  Future<bool> skip() async {
    final data = _data;
    if (data == null || data.preview) return data?.preview == true;
    try {
      await ref
          .read(taskRepositoryProvider)
          .setStatus(data.task.id, TaskStatus.skipped);
      await _log('skip');
      return true;
    } catch (error, stack) {
      await _record(error, stack, 'skip_reminder');
      return false;
    }
  }

  ReminderData? get _data => switch (state) {
        UiData(:final data) => data,
        _ => null,
      };

  Future<bool> _action(String action) async {
    final data = _data;
    if (data == null) return false;
    if (data.preview) return true;
    try {
      await _log(action);
      return true;
    } catch (error, stack) {
      await _record(error, stack, 'reminder_$action');
      return false;
    }
  }

  Future<void> _log(String action, [int? snoozeMinutes]) async {
    try {
      await ref.read(analyticsServiceProvider).logEvent('reminder_action', {
        'action': action,
        if (snoozeMinutes != null) 'snooze_minutes': snoozeMinutes,
      });
    } catch (_) {}
  }

  Future<void> _record(Object error, StackTrace stack, String reason) async {
    try {
      await ref
          .read(crashServiceProvider)
          .recordError(error, stack, reason: reason);
    } catch (_) {}
  }
}

final reminderViewModelProvider =
    NotifierProvider<ReminderViewModel, UiState<ReminderData>>(
        ReminderViewModel.new);

final _previewTask = TaskItem(
  id: 'preview',
  title: 'Đi bộ quanh công viên',
  habitKey: 'move',
  hour: 9,
  minute: 30,
  startDate: dateKey(DateTime.now()),
);
