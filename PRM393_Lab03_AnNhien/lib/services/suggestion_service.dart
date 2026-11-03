import 'dart:async';
import '../models/task_item.dart';
import '../utils/app_error.dart';

class ScheduleSuggestion {
  const ScheduleSuggestion(
      {required this.id,
      required this.senderUid,
      required this.tasks,
      this.status = 'pending',
      this.message = ''});
  final String id, senderUid, status, message;
  final List<TaskItem> tasks;
  ScheduleSuggestion withStatus(String status) => ScheduleSuggestion(
      id: id,
      senderUid: senderUid,
      tasks: tasks,
      status: status,
      message: message);
}

/// F12 (Sanh) có thể dùng contract này. Không gửi phản hồi bỏ qua cho Con cháu.
abstract interface class SuggestionService {
  Stream<List<ScheduleSuggestion>> watchPending();
  Future<String> send(String momUid, String requestId, List<TaskItem> tasks,
      {String message = ''});
  Future<void> resolve(String id, List<int> selected,
      {Map<int, ({int hour, int minute})> times = const {}});
  Future<void> undoDismiss(String id);
}

class FakeSuggestionService implements SuggestionService {
  final suggestions = <String, ScheduleSuggestion>{};
  final acceptedTasks = <TaskItem>[];
  final _changes = StreamController<void>.broadcast(sync: true);
  @override
  Stream<List<ScheduleSuggestion>> watchPending() => Stream.multi((sink) {
        void emit() => sink.add(
            suggestions.values.where((s) => s.status == 'pending').toList());
        final sub = _changes.stream.listen((_) => emit());
        emit();
        sink.onCancel = sub.cancel;
      });
  @override
  Future<String> send(String momUid, String requestId, List<TaskItem> tasks,
      {String message = ''}) async {
    for (final t in tasks) {
      t.validate();
    }
    suggestions.putIfAbsent(
        requestId,
        () => ScheduleSuggestion(
            id: requestId,
            senderUid: 'demo-child',
            tasks: tasks,
            message: message));
    _changes.add(null);
    return requestId;
  }

  @override
  Future<void> resolve(String id, List<int> selected,
      {Map<int, ({int hour, int minute})> times = const {}}) async {
    final s = suggestions[id];
    if (s == null || s.status != 'pending')
      throw const AppException('Gợi ý đã được xử lý.');
    if (selected.toSet().length != selected.length ||
        selected.any((i) => i < 0 || i >= s.tasks.length) ||
        times.keys.any((i) => !selected.contains(i)))
      throw const AppException('Lựa chọn chưa hợp lệ.');
    final tasks = selected
        .map((i) => s.tasks[i].copyWith(
            id: 'suggestion-$id-$i',
            hour: times[i]?.hour,
            minute: times[i]?.minute))
        .toList();
    for (final t in tasks) {
      t.validate();
    }
    acceptedTasks.addAll(tasks);
    suggestions[id] = s.withStatus(selected.isEmpty
        ? 'dismissed'
        : selected.length == s.tasks.length
            ? 'accepted'
            : 'partial');
    _changes.add(null);
  }

  @override
  Future<void> undoDismiss(String id) async {
    final s = suggestions[id];
    if (s == null || s.status != 'dismissed')
      throw const AppException('Không thể hoàn tác.');
    suggestions[id] = s.withStatus('pending');
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
