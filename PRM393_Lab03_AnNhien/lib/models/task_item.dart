/// Trạng thái của một lần làm việc, không phải của cả chuỗi lặp.
enum TaskStatus { pending, done, postponed, skipped }

enum RepeatRule { once, daily, someDays, weekly, monthly }

String dateKey(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
DateTime calendarDate(DateTime day) => DateTime(day.year, day.month, day.day);

/// Schema v2: ngày lịch địa phương, giờ theo Asia/Ho_Chi_Minh (UTC+7).
/// v1 vẫn đọc được; lần save tiếp theo thêm startDate và schemaVersion.
class TaskItem {
  const TaskItem(
      {required this.id,
      required this.title,
      required this.habitKey,
      required this.hour,
      required this.minute,
      this.repeat = RepeatRule.daily,
      this.status = TaskStatus.pending,
      this.remind = true,
      this.startDate,
      this.endDate,
      this.weekdays = const [],
      this.monthDays = const [],
      this.lastDayOfMonth = false,
      this.excludedDates = const [],
      this.durationMinutes = 15,
      this.revision = 0,
      this.occurrenceDate,
      this.rescheduleSourceDate,
      this.isRescheduled = false,
      this.completionSourceId});
  final String id, title, habitKey;
  final int hour, minute, durationMinutes, revision;
  final RepeatRule repeat;
  final TaskStatus status;
  final bool remind, lastDayOfMonth;
  final String? startDate, endDate;
  final List<int> weekdays, monthDays;
  final List<String> excludedDates;

  /// Chỉ ở bộ nhớ; được dùng khi hiển thị kết quả tasksForDay.
  final String? occurrenceDate;

  /// Ngày gốc của occurrence đã được dời. Chỉ dùng ở bộ nhớ khi đọc lịch;
  /// schema task gốc không bị thay đổi bởi thao tác dời một lần.
  final String? rescheduleSourceDate;
  final bool isRescheduled;

  /// Parent series for pre-existing completion records after a scope split.
  /// A completion recorded on this task's own ID always takes precedence.
  final String? completionSourceId;
  bool get isDone => status == TaskStatus.done;

  bool occursOn(DateTime day) {
    final key = dateKey(day);
    if (startDate != null && key.compareTo(startDate!) < 0 ||
        endDate != null && key.compareTo(endDate!) > 0 ||
        excludedDates.contains(key)) {
      return false;
    }
    return switch (repeat) {
      RepeatRule.once => key == startDate,
      RepeatRule.daily => true,
      RepeatRule.weekly ||
      RepeatRule.someDays =>
        weekdays.contains(day.weekday),
      RepeatRule.monthly => monthDays.contains(day.day) ||
          lastDayOfMonth && day.day == DateTime(day.year, day.month + 1, 0).day,
    };
  }

  void validate() {
    bool validDate(String? s) =>
        s == null ||
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) &&
            DateTime.tryParse(s) != null &&
            dateKey(DateTime.parse(s)) == s;
    if (title.trim().isEmpty ||
        title.length > 80 ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        durationMinutes < 1 ||
        durationMinutes > 1440 ||
        ![
          'move',
          'purpose',
          'downshift',
          'eighty',
          'plant',
          'tea',
          'belong',
          'family',
          'tribe'
        ].contains(habitKey) ||
        !validDate(startDate) ||
        !validDate(endDate) ||
        startDate != null &&
            endDate != null &&
            endDate!.compareTo(startDate!) < 0 ||
        weekdays.any((n) => n < 1 || n > 7) ||
        monthDays.any((n) => n < 1 || n > 31) ||
        [RepeatRule.weekly, RepeatRule.someDays].contains(repeat) &&
            weekdays.isEmpty ||
        repeat == RepeatRule.monthly && monthDays.isEmpty && !lastDayOfMonth ||
        excludedDates.length > 366 ||
        excludedDates.any((s) => !validDate(s))) {
      throw const FormatException(
          'Thông tin lịch chưa hợp lệ. Kiểm tra tên, ngày và giờ.');
    }
  }

  TaskItem copyWith(
          {String? id,
          String? title,
          String? habitKey,
          int? hour,
          int? minute,
          RepeatRule? repeat,
          TaskStatus? status,
          bool? remind,
          String? startDate,
          String? endDate,
          bool clearEndDate = false,
          List<int>? weekdays,
          List<int>? monthDays,
          bool? lastDayOfMonth,
          List<String>? excludedDates,
          int? durationMinutes,
          int? revision,
          String? occurrenceDate,
          String? rescheduleSourceDate,
          bool? isRescheduled,
          String? completionSourceId}) =>
      TaskItem(
          id: id ?? this.id,
          title: title ?? this.title,
          habitKey: habitKey ?? this.habitKey,
          hour: hour ?? this.hour,
          minute: minute ?? this.minute,
          repeat: repeat ?? this.repeat,
          status: status ?? this.status,
          remind: remind ?? this.remind,
          startDate: startDate ?? this.startDate,
          endDate: clearEndDate ? null : endDate ?? this.endDate,
          weekdays: weekdays ?? this.weekdays,
          monthDays: monthDays ?? this.monthDays,
          lastDayOfMonth: lastDayOfMonth ?? this.lastDayOfMonth,
          excludedDates: excludedDates ?? this.excludedDates,
          durationMinutes: durationMinutes ?? this.durationMinutes,
          revision: revision ?? this.revision,
          occurrenceDate: occurrenceDate ?? this.occurrenceDate,
          rescheduleSourceDate:
              rescheduleSourceDate ?? this.rescheduleSourceDate,
          isRescheduled: isRescheduled ?? this.isRescheduled,
          completionSourceId: completionSourceId ?? this.completionSourceId);

  Map<String, Object?> toMap() => {
        'schemaVersion': 2,
        'completionSourceId': completionSourceId,
        'revision': revision,
        'title': title.trim(),
        'habitKey': habitKey,
        'hour': hour,
        'minute': minute,
        'repeat': repeat.name,
        'status': TaskStatus.pending.name,
        'remind': remind,
        'startDate': startDate,
        'endDate': endDate,
        'weekdays': weekdays,
        'monthDays': monthDays,
        'lastDayOfMonth': lastDayOfMonth,
        'excludedDates': excludedDates,
        'durationMinutes': durationMinutes,
        'timezone': 'Asia/Ho_Chi_Minh'
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
      startDate: parseDateKey(m['startDate']) == null
          ? null
          : dateKey(parseDateKey(m['startDate'])!),
      endDate: m['endDate'] as String?,
      weekdays: (m['weekdays'] as List?)?.cast<int>() ?? const [],
      monthDays: (m['monthDays'] as List?)?.cast<int>() ?? const [],
      lastDayOfMonth: m['lastDayOfMonth'] as bool? ?? false,
      excludedDates: (m['excludedDates'] as List?)?.cast<String>() ?? const [],
      durationMinutes:
          ((m['durationMinutes'] ?? m['durationMin']) as num?)?.toInt() ?? 15,
      revision: (m['revision'] as num?)?.toInt() ?? 0,
      completionSourceId: m['completionSourceId'] as String?);
}

/// Gregorian calendar/weekday patterns repeat every 400 years. Include all
/// finite exceptions before bounding the search by a full calendar cycle.
bool schedulesConflict(TaskItem a, TaskItem b) {
  final aStart = a.hour * 60 + a.minute, bStart = b.hour * 60 + b.minute;
  final same = aStart < bStart + b.durationMinutes &&
      bStart < aStart + a.durationMinutes;
  final previous = bStart + b.durationMinutes > 1440 + aStart;
  final next = aStart + a.durationMinutes > 1440 + bStart;
  if (!same && !previous && !next) return false;
  final aFirst = DateTime.parse(a.startDate ?? '1900-01-01');
  final bFirst = DateTime.parse(b.startDate ?? '1900-01-01')
      .subtract(const Duration(days: 1));
  final from = aFirst.isAfter(bFirst) ? aFirst : bFirst;
  final exceptions = [dateKey(from), ...a.excludedDates, ...b.excludedDates]
    ..sort();
  final lastException = DateTime.parse(exceptions.last);
  final cap = DateTime(
      lastException.year + 400, lastException.month, lastException.day + 1);
  final aEnd = a.endDate == null ? cap : DateTime.parse(a.endDate!);
  final bEnd = b.endDate == null
      ? cap
      : DateTime.parse(b.endDate!).add(const Duration(days: 1));
  final through = [aEnd, bEnd, cap].reduce((x, y) => x.isBefore(y) ? x : y);
  for (var d = from; !d.isAfter(through); d = d.add(const Duration(days: 1))) {
    if (!a.occursOn(d)) continue;
    if (same && b.occursOn(d) ||
        previous && b.occursOn(d.subtract(const Duration(days: 1))) ||
        next && b.occursOn(d.add(const Duration(days: 1)))) {
      return true;
    }
  }
  return false;
}

/// A scope split points at its parent. Walk the chain to preserve progress even
/// after several edits; an explicit status on the new occurrence wins.
TaskStatus resolveOccurrenceStatus(TaskItem task,
    Map<String, TaskItem> templates, Map<String, TaskStatus> statuses) {
  String? id = task.id;
  final seen = <String>{};
  while (id != null && seen.add(id)) {
    final status = statuses[id];
    if (status != null) return status;
    id = (id == task.id ? task : templates[id])?.completionSourceId;
  }
  return TaskStatus.pending;
}

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
