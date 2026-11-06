import 'caregiver_schedule_service.dart' as schedule;
import '../models/task_item.dart';

/// Việc của Bác. Bản thật (Firestore users/{uid}/tasks): B – Hiếu, F1/F4.
abstract interface class TaskRepository {
  Future<List<TaskItem>> tasksForDay(DateTime day);
  Future<void> save(TaskItem task);
  Future<void> setStatus(String taskId, TaskStatus status);
  Future<void> delete(String taskId);

  /// Dời một occurrence mà không sửa giờ/ngày của cả chuỗi lặp.
  Future<TaskRescheduleChange> reschedule(TaskItem task,
      {required DateTime targetDay, required int hour, required int minute});

  /// Hoàn tác chính xác một lần dời, kể cả khi occurrence đã từng được dời.
  Future<void> restoreReschedule(TaskRescheduleChange change);
}

/// Optional contract for atomic edits/deletes of recurring occurrences.
abstract interface class ScopedTaskRepository {
  Future<schedule.ScheduleUndo> changeOccurrence(TaskItem original,
      DateTime day, TaskItem? replacement, schedule.ChangeScope scope);
  Future<void> undoOccurrence(schedule.ScheduleUndo change);
}

/// Bản ghi dời của một occurrence. [history] chỉ lưu mốc thời gian, không có
/// tiêu đề việc hoặc dữ liệu nhận diện người dùng.
class TaskReschedule {
  const TaskReschedule({
    required this.taskId,
    required this.sourceDate,
    required this.targetDate,
    required this.hour,
    required this.minute,
    this.history = const [],
  });

  final String taskId;
  final String sourceDate;
  final String targetDate;
  final int hour;
  final int minute;
  final List<Map<String, Object?>> history;

  String get key => '${taskId}_$sourceDate';

  Map<String, Object?> toMap() => {
        'taskId': taskId,
        'sourceDate': sourceDate,
        'targetDate': targetDate,
        'hour': hour,
        'minute': minute,
        'history': history,
      };

  factory TaskReschedule.fromMap(Map<String, Object?> map) => TaskReschedule(
        taskId: map['taskId'] as String,
        sourceDate: map['sourceDate'] as String,
        targetDate: map['targetDate'] as String,
        hour: (map['hour'] as num).toInt(),
        minute: (map['minute'] as num).toInt(),
        history: ((map['history'] as List?) ?? const [])
            .whereType<Map>()
            .map((entry) => Map<String, Object?>.from(entry))
            .toList(growable: false),
      );
}

/// Snapshot trước khi ghi dời, dùng để Undo mà không đoán lại thời gian cũ.
class TaskRescheduleChange {
  const TaskRescheduleChange({required this.key, required this.before});
  final String key;
  final TaskReschedule? before;
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<TaskItem>? seed]) : _tasks = [...(seed ?? _sample)];

  final List<TaskItem> _tasks;
  final Map<String, TaskReschedule> _reschedules = {};

  static const _sample = [
    TaskItem(
        id: 't1',
        title: 'Tưới rau ngoài vườn',
        habitKey: 'plant',
        hour: 6,
        minute: 30,
        status: TaskStatus.done),
    TaskItem(
        id: 't2',
        title: 'Ăn sáng chậm rãi',
        habitKey: 'eighty',
        hour: 7,
        minute: 30,
        status: TaskStatus.done),
    TaskItem(
        id: 't3',
        title: 'Đi bộ quanh công viên',
        habitKey: 'move',
        hour: 9,
        minute: 30),
    TaskItem(
        id: 't4',
        title: 'Gọi điện cho Mai',
        habitKey: 'family',
        hour: 18,
        minute: 0),
  ];

  @override
  Future<List<TaskItem>> tasksForDay(DateTime day) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final key = dateKey(day);
    final result = <TaskItem>[];
    for (final task in _tasks) {
      final sourceKey = '${task.id}_$key';
      if (!_reschedules.containsKey(sourceKey) &&
          (task.startDate == null || task.occursOn(day))) {
        // Fake giữ hành vi cũ: task seed không có ngày vẫn xuất hiện ở ngày
        // đang kiểm thử. Firebase dùng occursOn thật ở adapter của nó.
        result
            .add(task.copyWith(occurrenceDate: key, rescheduleSourceDate: key));
      }
    }
    for (final reschedule
        in _reschedules.values.where((r) => r.targetDate == key)) {
      final task = _tasks.where((t) => t.id == reschedule.taskId).firstOrNull;
      if (task != null) {
        result.add(task.copyWith(
          hour: reschedule.hour,
          minute: reschedule.minute,
          status: TaskStatus.pending,
          occurrenceDate: key,
          rescheduleSourceDate: reschedule.sourceDate,
        ));
      }
    }
    result.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return List.unmodifiable(result);
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
  Future<void> delete(String taskId) async =>
      _tasks.removeWhere((t) => t.id == taskId);

  @override
  Future<TaskRescheduleChange> reschedule(TaskItem task,
      {required DateTime targetDay,
      required int hour,
      required int minute}) async {
    final sourceDate = task.rescheduleSourceDate ??
        task.occurrenceDate ??
        dateKey(DateTime.now());
    final key = '${task.id}_$sourceDate';
    final before = _reschedules[key];
    final history = [
      ...?before?.history,
      {
        'fromDate': before?.targetDate ?? sourceDate,
        'fromHour': before?.hour ?? task.hour,
        'fromMinute': before?.minute ?? task.minute,
      },
    ];
    _reschedules[key] = TaskReschedule(
      taskId: task.id,
      sourceDate: sourceDate,
      targetDate: dateKey(targetDay),
      hour: hour,
      minute: minute,
      history: history,
    );
    return TaskRescheduleChange(key: key, before: before);
  }

  @override
  Future<void> restoreReschedule(TaskRescheduleChange change) async {
    if (change.before == null) {
      _reschedules.remove(change.key);
    } else {
      _reschedules[change.key] = change.before!;
    }
  }
}
