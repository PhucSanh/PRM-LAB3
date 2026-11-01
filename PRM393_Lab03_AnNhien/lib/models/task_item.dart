/// Một việc trong ngày (Firestore: users/{uid}/tasks/{id}).
enum TaskStatus { pending, done, postponed, skipped }

enum RepeatRule { once, daily, someDays }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.habitKey,
    required this.hour,
    required this.minute,
    this.repeat = RepeatRule.daily,
    this.status = TaskStatus.pending,
    this.remind = true,
  });

  final String id;
  final String title;

  /// Một trong 9 khoá: move, purpose, downshift, eighty, plant, tea, belong, family, tribe.
  final String habitKey;
  final int hour;
  final int minute;
  final RepeatRule repeat;
  final TaskStatus status;
  final bool remind;

  bool get isDone => status == TaskStatus.done;

  TaskItem copyWith({String? title, int? hour, int? minute, RepeatRule? repeat, TaskStatus? status, bool? remind}) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      habitKey: habitKey,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeat: repeat ?? this.repeat,
      status: status ?? this.status,
      remind: remind ?? this.remind,
    );
  }

  Map<String, Object?> toMap() => {
        'title': title,
        'habitKey': habitKey,
        'hour': hour,
        'minute': minute,
        'repeat': repeat.name,
        'status': status.name,
        'remind': remind,
      };

  factory TaskItem.fromMap(String id, Map<String, Object?> m) => TaskItem(
        id: id,
        title: m['title'] as String? ?? '',
        habitKey: m['habitKey'] as String? ?? 'move',
        hour: (m['hour'] as num?)?.toInt() ?? 0,
        minute: (m['minute'] as num?)?.toInt() ?? 0,
        repeat: RepeatRule.values.asNameMap()[m['repeat']] ?? RepeatRule.daily,
        status: TaskStatus.values.asNameMap()[m['status']] ?? TaskStatus.pending,
        remind: m['remind'] as bool? ?? true,
      );
}
