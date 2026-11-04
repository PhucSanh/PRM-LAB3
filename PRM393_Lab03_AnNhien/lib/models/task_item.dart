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
    this.startDate,
    this.durationMin,
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

  /// Ngày bắt đầu (chỉ phần ngày, giờ máy). Việc `once` diễn ra đúng ngày này.
  /// `null` = dữ liệu cũ chưa có ngày. F12 thêm (DT trong PR) – TODO(Hiếu): chốt
  /// schema `users/{uid}/tasks.startDate` (architecture.md mục 10), đang lưu chuỗi `yyyy-MM-dd`.
  final DateTime? startDate;

  /// Thời lượng (phút), vd. 20 cho "Đi bộ nhẹ nhàng · 20 phút". `null` = không ghi.
  final int? durationMin;

  bool get isDone => status == TaskStatus.done;

  TaskItem copyWith({
    String? title,
    int? hour,
    int? minute,
    RepeatRule? repeat,
    TaskStatus? status,
    bool? remind,
    DateTime? startDate,
    int? durationMin,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      habitKey: habitKey,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeat: repeat ?? this.repeat,
      status: status ?? this.status,
      remind: remind ?? this.remind,
      startDate: startDate ?? this.startDate,
      durationMin: durationMin ?? this.durationMin,
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
        // Chỉ ghi khi có, để không đổi dữ liệu cũ.
        if (startDate != null) 'startDate': dateKey(startDate!),
        if (durationMin != null) 'durationMin': durationMin,
      };

  factory TaskItem.fromMap(String id, Map<String, Object?> m) => TaskItem(
        id: id,
        title: m['title'] as String? ?? '',
        habitKey: m['habitKey'] as String? ?? 'move',
        hour: (m['hour'] as num?)?.toInt() ?? 0,
        minute: (m['minute'] as num?)?.toInt() ?? 0,
        repeat: RepeatRule.values.asNameMap()[m['repeat']] ?? RepeatRule.daily,
        status:
            TaskStatus.values.asNameMap()[m['status']] ?? TaskStatus.pending,
        remind: m['remind'] as bool? ?? true,
        startDate: parseDateKey(m['startDate']),
        durationMin: (m['durationMin'] as num?)?.toInt(),
      );
}

/// Ngày → chuỗi `yyyy-MM-dd` (giờ máy) để lưu Firestore, không lệch múi giờ.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Đọc ngày đã lưu: chuỗi `yyyy-MM-dd`, `DateTime`, hoặc Timestamp Firestore (có `toDate()`).
/// Sai định dạng → `null` (không phá dữ liệu cũ).
DateTime? parseDateKey(Object? v) {
  DateTime? d;
  if (v is DateTime) {
    d = v;
  } else if (v is String) {
    d = DateTime.tryParse(v);
  } else if (v != null) {
    try {
      d = (v as dynamic).toDate() as DateTime;
    } catch (_) {
      d = null;
    }
  }
  return d == null ? null : DateTime(d.year, d.month, d.day);
}
