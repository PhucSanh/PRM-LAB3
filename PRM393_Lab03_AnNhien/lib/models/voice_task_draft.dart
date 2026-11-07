import 'task_item.dart';

/// A proposed schedule only. It has no task id and cannot persist itself.
class VoiceTaskDraft {
  const VoiceTaskDraft(
      {this.title,
      this.date,
      this.hour,
      this.minute,
      this.durationMinutes,
      required this.repeat,
      required this.weekdays,
      required this.habitKey});
  final String? title;
  final DateTime? date;
  final int? hour, minute;

  /// Bác làm việc này trong bao lâu (phút). Bắt buộc trước khi lưu.
  final int? durationMinutes;
  final RepeatRule repeat;
  final List<int> weekdays;
  final String habitKey;

  static const maxDurationMinutes = 240;

  /// Đủ tên, ngày, giờ, lặp (chưa xét thời lượng).
  bool get scheduleComplete =>
      title != null &&
      date != null &&
      hour != null &&
      minute != null &&
      (!{RepeatRule.weekly, RepeatRule.someDays}.contains(repeat) ||
          weekdays.isNotEmpty);

  /// Đủ thông tin để lưu: cả lịch lẫn thời lượng.
  bool get complete => scheduleComplete && durationMinutes != null;

  VoiceTaskDraft withDuration(int minutes) => VoiceTaskDraft(
      title: title,
      date: date,
      hour: hour,
      minute: minute,
      durationMinutes: minutes,
      repeat: repeat,
      weekdays: weekdays,
      habitKey: habitKey);

  bool isFuture(DateTime now) =>
      scheduleComplete &&
      DateTime.utc(date!.year, date!.month, date!.day, hour! - 7, minute!)
          .isAfter(now.toUtc());
  String get repeatLabel => switch (repeat) {
        RepeatRule.once => 'Một lần',
        RepeatRule.daily => 'Mỗi ngày',
        RepeatRule.weekly ||
        RepeatRule.someDays =>
          'Hằng tuần: ${weekdays.map((n) => n == 7 ? 'Chủ Nhật' : 'thứ ${n + 1}').join(', ')}',
        RepeatRule.monthly => 'Mỗi tháng',
      };
  String get dateLabel => date == null
      ? 'Chưa rõ ngày'
      : '${date!.day}/${date!.month}/${date!.year}';
  String get timeLabel => hour == null || minute == null
      ? 'Chưa rõ giờ'
      : '${hour!.toString().padLeft(2, '0')}:${minute!.toString().padLeft(2, '0')}';
  String get durationLabel => durationMinutes == null
      ? 'Chưa rõ bao lâu'
      : durationText(durationMinutes!);
  String get reviewText =>
      '${title ?? 'Chưa rõ tên việc'}. Ngày $dateLabel, lúc $timeLabel, làm trong $durationLabel. $repeatLabel. Bác kiểm tra lại trước khi lưu nhé.';

  /// Việc mới từ bản nháp đã đủ thông tin. Chỉ gọi khi [complete].
  TaskItem toTask(String id) {
    assert(complete, 'Draft must be complete before saving');
    final day = date!;
    return TaskItem(
      id: id,
      title: title!,
      habitKey: habitKey,
      hour: hour!,
      minute: minute!,
      repeat: repeat,
      durationMinutes: durationMinutes!,
      startDate: dateKey(day),
      weekdays: {RepeatRule.weekly, RepeatRule.someDays}.contains(repeat)
          ? (weekdays.isEmpty ? [day.weekday] : weekdays)
          : const [],
      monthDays: repeat == RepeatRule.monthly ? [day.day] : const [],
    );
  }

  factory VoiceTaskDraft.fromMap(Map<String, dynamic> data) {
    final title = data['title'], rawDate = data['date'];
    final hour = data['hour'], minute = data['minute'];
    final repeat =
        RepeatRule.values.where((v) => v.name == data['repeat']).firstOrNull;
    final days = data['weekdays'], habit = data['habitKey'];
    // Server cũ chưa trả thời lượng: để null, app tự hiểu hoặc hỏi lại.
    final duration = data['durationMinutes'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if ((title != null &&
            (title is! String || title.trim().isEmpty || title.length > 80)) ||
        (rawDate != null &&
            (rawDate is! String || date == null || dateKey(date) != rawDate)) ||
        (hour != null && (hour is! int || hour < 0 || hour > 23)) ||
        (minute != null && (minute is! int || minute < 0 || minute > 59)) ||
        (duration != null &&
            (duration is! int ||
                duration < 1 ||
                duration > maxDurationMinutes)) ||
        repeat == null ||
        days is! List ||
        days.length > 7 ||
        days.any((v) => v is! int || v < 1 || v > 7) ||
        !const [
          'move',
          'purpose',
          'downshift',
          'eighty',
          'plant',
          'tea',
          'belong',
          'family',
          'tribe'
        ].contains(habit)) {
      throw const FormatException('Invalid voice draft');
    }
    return VoiceTaskDraft(
        title: (title as String?)?.trim(),
        date: date,
        hour: hour as int?,
        minute: minute as int?,
        durationMinutes: duration as int?,
        repeat: repeat,
        weekdays:
            List<int>.unmodifiable(days.cast<int>().toSet().toList()..sort()),
        habitKey: habit as String);
  }
}

/// Một khung giờ đã bận trong ngày. Không chứa tên việc: chỉ giờ, thời lượng
/// và nhóm thói quen, để AI hiểu "sau khi đi bộ" mà không đọc lịch riêng tư.
class VoiceBusySlot {
  const VoiceBusySlot(
      {required this.hour,
      required this.minute,
      required this.durationMinutes,
      required this.habitKey,
      this.date});
  final int hour, minute, durationMinutes;
  final String habitKey;

  /// Chỉ có ở `week` (khung giờ bận 7 ngày tới).
  final DateTime? date;
  Map<String, Object> toMap() => {
        if (date != null) 'date': dateKey(date!),
        'time':
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        'durationMinutes': durationMinutes,
        'habitKey': habitKey,
      };
}

/// Ngữ cảnh của Bác gửi kèm câu nói: cách xưng hô, giờ thức dậy và các khung
/// giờ đã bận của ngày đang xem. Mọi trường đều có thể thiếu.
class VoiceUserContext {
  const VoiceUserContext(
      {this.honorific,
      this.wakeHour,
      this.wakeMinute,
      this.busy = const [],
      this.week = const []});

  /// Khoá `ong` / `ba` như `users/{uid}.honorific`.
  final String? honorific;
  final int? wakeHour, wakeMinute;
  final List<VoiceBusySlot> busy;

  /// Khung giờ bận 7 ngày tới (có ngày, không có tên việc) để AI trả lời
  /// "mai tui rảnh lúc nào".
  final List<VoiceBusySlot> week;

  static const maxBusy = 20, maxWeek = 60;
  bool get hasWakeTime => wakeHour != null && wakeMinute != null;
  bool get isEmpty =>
      honorific == null && !hasWakeTime && busy.isEmpty && week.isEmpty;

  Map<String, Object?> toMap() => {
        'honorific': honorific,
        'wakeTime': hasWakeTime
            ? '${wakeHour!.toString().padLeft(2, '0')}:${wakeMinute!.toString().padLeft(2, '0')}'
            : null,
        'busy': busy.take(maxBusy).map((s) => s.toMap()).toList(),
        if (week.isNotEmpty)
          'week': week.take(maxWeek).map((s) => s.toMap()).toList(),
      };
}

/// Ý định AI hiểu từ câu nói. [add] là thêm việc (mặc định, cả bản server cũ).
enum VoiceIntent { add, agenda, complete, next, answer }

class VoiceTaskInterpretation {
  const VoiceTaskInterpretation(
      {required this.draft,
      required this.question,
      this.onDevice = false,
      this.intent = VoiceIntent.add,
      this.queryDate,
      this.queryDays = 1,
      this.reply});
  final VoiceTaskDraft draft;
  final String? question;
  final VoiceIntent intent;

  /// [VoiceIntent.agenda]: ngày đầu và số ngày (1–7) Bác hỏi lịch.
  final DateTime? queryDate;
  final int queryDays;

  /// [VoiceIntent.answer]: câu trả lời ngắn của AI, chỉ hiển thị và đọc to.
  final String? reply;
  static const maxReply = 300;

  /// `true` khi kết quả do bộ hiểu lời nói trên máy tạo (chưa bật Groq).
  final bool onDevice;
  bool get ready => question == null && draft.complete;

  VoiceTaskInterpretation copyWith(
          {VoiceTaskDraft? draft,
          String? question,
          bool clearQuestion = false}) =>
      VoiceTaskInterpretation(
          draft: draft ?? this.draft,
          question: clearQuestion ? null : (question ?? this.question),
          onDevice: onDevice,
          intent: intent,
          queryDate: queryDate,
          queryDays: queryDays,
          reply: reply);
  factory VoiceTaskInterpretation.fromMap(Map<String, dynamic> data) {
    if (data['draft'] is! Map ||
        data['ready'] is! bool ||
        (data['question'] != null &&
            (data['question'] is! String ||
                (data['question'] as String).trim().isEmpty ||
                (data['question'] as String).length > 240))) {
      throw const FormatException('Invalid voice interpretation');
    }
    final rawIntent = data['intent'] ?? 'add';
    final intent =
        VoiceIntent.values.where((i) => i.name == rawIntent).firstOrNull;
    final rawDays = data['queryDays'] ?? 1;
    final rawReply = data['reply'];
    final queryDate =
        data['queryDate'] == null ? null : parseDateKey(data['queryDate']);
    if (intent == null ||
        rawDays is! int ||
        rawDays < 1 ||
        rawDays > 7 ||
        (data['queryDate'] != null && queryDate == null) ||
        (rawReply != null &&
            (rawReply is! String || rawReply.length > maxReply)) ||
        (intent == VoiceIntent.answer &&
            (rawReply is! String || rawReply.trim().isEmpty))) {
      throw const FormatException('Invalid voice intent');
    }
    final result = VoiceTaskInterpretation(
        draft: VoiceTaskDraft.fromMap(
            Map<String, dynamic>.from(data['draft'] as Map)),
        question: data['question'] as String?,
        intent: intent,
        queryDate: queryDate,
        queryDays: rawDays,
        reply: (rawReply as String?)?.trim());
    // `ready` của server không xét thời lượng (app tự bổ sung / hỏi lại).
    if (data['ready'] !=
        (result.question == null && result.draft.scheduleComplete)) {
      throw const FormatException('Inconsistent voice interpretation');
    }
    return result;
  }
}

/// "30 phút", "1 tiếng", "1 tiếng 30 phút" cho người 65+ dễ nghe.
String durationText(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m phút';
  if (m == 0) return '$h tiếng';
  if (m == 30) return '$h tiếng rưỡi';
  return '$h tiếng $m phút';
}
