import 'package:clock/clock.dart';

import '../models/task_item.dart';
import '../services/task_repository.dart';
import '../utils/app_error.dart';

/// Một khung giờ chỉ có một việc: hai việc không được chồng thời gian
/// (giờ bắt đầu + thời lượng). Việc đã bỏ qua không giữ chỗ.
bool timesOverlap(int startA, int durationA, int startB, int durationB) =>
    startA < startB + durationB && startB < startA + durationA;

/// Việc đã có trong [sameDay] chồng giờ với khung [hour]:[minute] dài
/// [durationMinutes], bỏ qua việc có id [ignoreId] (khi sửa chính nó).
TaskItem? overlappingTask(List<TaskItem> sameDay,
    {required int hour,
    required int minute,
    required int durationMinutes,
    String? ignoreId}) {
  final start = hour * 60 + minute;
  for (final t in sameDay) {
    if (t.id == ignoreId || t.status == TaskStatus.skipped) continue;
    if (timesOverlap(
        start, durationMinutes, t.hour * 60 + t.minute, t.durationMinutes)) {
      return t;
    }
  }
  return null;
}

String _clock(int totalMinutes) {
  final m = totalMinutes % (24 * 60);
  return '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';
}

/// Câu báo trùng giờ cho Bác, có giờ bắt đầu – kết thúc của việc đã có.
String overlapMessage(TaskItem task) {
  final start = task.hour * 60 + task.minute;
  return 'Từ ${_clock(start)} đến ${_clock(start + task.durationMinutes)} '
      'Bác đã có việc “${task.title}”. Bác chọn giờ khác hoặc rút ngắn thời gian nhé.';
}

/// Lỗi trùng giờ: ViewModel đọc [userMessage] để hiện cho Bác.
class ScheduleConflictException extends AppException {
  ScheduleConflictException(this.task) : super(overlapMessage(task));
  final TaskItem task;
}

/// Tìm việc trùng giờ với [candidate] trong 7 ngày kể từ ngày bắt đầu (đủ để
/// gặp mọi thứ trong tuần của việc lặp). Trả về `null` nếu không trùng.
Future<TaskItem?> findScheduleConflict(
    TaskRepository repository, TaskItem candidate,
    {String? ignoreId, DateTime? onlyDay}) async {
  final now = clock.now(), today = DateTime(now.year, now.month, now.day);
  final start = candidate.startDate == null
      ? today
      : DateTime.parse(candidate.startDate!);
  // Việc lặp đã bắt đầu từ trước: chỉ xét từ hôm nay, không xét ngày đã qua.
  final first = onlyDay ?? (start.isBefore(today) ? today : start);
  final days = onlyDay != null || candidate.repeat == RepeatRule.once
      ? [first]
      : [for (var i = 0; i < 7; i++) first.add(Duration(days: i))];
  for (final day in days) {
    if (onlyDay == null &&
        candidate.startDate != null &&
        !candidate.occursOn(day)) {
      continue;
    }
    final hit = overlappingTask(await repository.tasksForDay(day),
        hour: candidate.hour,
        minute: candidate.minute,
        durationMinutes: candidate.durationMinutes,
        ignoreId: ignoreId ?? candidate.id);
    if (hit != null) return hit;
  }
  return null;
}
