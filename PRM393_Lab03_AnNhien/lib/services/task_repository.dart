import '../models/task_item.dart';

/// Việc của Bác. Bản thật (Firestore users/{uid}/tasks): B – Hiếu, F1/F4.
abstract interface class TaskRepository {
  Future<List<TaskItem>> tasksForDay(DateTime day);
  Future<void> save(TaskItem task);
  Future<void> setStatus(String taskId, TaskStatus status);
  Future<void> delete(String taskId);
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<TaskItem>? seed]) : _tasks = [...(seed ?? _sample)];

  final List<TaskItem> _tasks;

  static const _sample = [
    TaskItem(id: 't1', title: 'Tưới rau ngoài vườn', habitKey: 'plant', hour: 6, minute: 30, status: TaskStatus.done),
    TaskItem(id: 't2', title: 'Ăn sáng chậm rãi', habitKey: 'eighty', hour: 7, minute: 30, status: TaskStatus.done),
    TaskItem(id: 't3', title: 'Đi bộ quanh công viên', habitKey: 'move', hour: 9, minute: 30),
    TaskItem(id: 't4', title: 'Gọi điện cho Mai', habitKey: 'family', hour: 18, minute: 0),
  ];

  @override
  Future<List<TaskItem>> tasksForDay(DateTime day) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> save(TaskItem task) async {
    _tasks
      ..removeWhere((t) => t.id == task.id)
      ..add(task);
  }

  @override
  Future<void> setStatus(String taskId, TaskStatus status) async {
    final i = _tasks.indexWhere((t) => t.id == taskId);
    if (i >= 0) _tasks[i] = _tasks[i].copyWith(status: status);
  }

  @override
  Future<void> delete(String taskId) async => _tasks.removeWhere((t) => t.id == taskId);
}
