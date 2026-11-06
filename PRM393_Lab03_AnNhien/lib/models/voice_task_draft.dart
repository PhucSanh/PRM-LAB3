import 'task_item.dart';

/// A proposed schedule only. It has no task id and cannot persist itself.
class VoiceTaskDraft {
  const VoiceTaskDraft(
      {this.title,
      this.date,
      this.hour,
      this.minute,
      required this.repeat,
      required this.weekdays,
      required this.habitKey});
  final String? title;
  final DateTime? date;
  final int? hour, minute;
  final RepeatRule repeat;
  final List<int> weekdays;
  final String habitKey;

  bool get complete =>
      title != null &&
      date != null &&
      hour != null &&
      minute != null &&
      (!{RepeatRule.weekly, RepeatRule.someDays}.contains(repeat) ||
          weekdays.isNotEmpty);
  bool isFuture(DateTime now) =>
      complete &&
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
  String get reviewText =>
      '${title ?? 'Chưa rõ tên việc'}. Ngày $dateLabel, lúc $timeLabel. $repeatLabel. Bác kiểm tra lại trước khi lưu nhé.';

  factory VoiceTaskDraft.fromMap(Map<String, dynamic> data) {
    final title = data['title'], rawDate = data['date'];
    final hour = data['hour'], minute = data['minute'];
    final repeat =
        RepeatRule.values.where((v) => v.name == data['repeat']).firstOrNull;
    final days = data['weekdays'], habit = data['habitKey'];
    final date = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if ((title != null &&
            (title is! String || title.trim().isEmpty || title.length > 80)) ||
        (rawDate != null &&
            (rawDate is! String || date == null || dateKey(date) != rawDate)) ||
        (hour != null && (hour is! int || hour < 0 || hour > 23)) ||
        (minute != null && (minute is! int || minute < 0 || minute > 59)) ||
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
        repeat: repeat,
        weekdays:
            List<int>.unmodifiable(days.cast<int>().toSet().toList()..sort()),
        habitKey: habit as String);
  }
}

class VoiceTaskInterpretation {
  const VoiceTaskInterpretation({required this.draft, required this.question});
  final VoiceTaskDraft draft;
  final String? question;
  bool get ready => question == null && draft.complete;
  factory VoiceTaskInterpretation.fromMap(Map<String, dynamic> data) {
    if (data['draft'] is! Map ||
        data['ready'] is! bool ||
        (data['question'] != null &&
            (data['question'] is! String ||
                (data['question'] as String).trim().isEmpty ||
                (data['question'] as String).length > 240))) {
      throw const FormatException('Invalid voice interpretation');
    }
    final result = VoiceTaskInterpretation(
        draft: VoiceTaskDraft.fromMap(
            Map<String, dynamic>.from(data['draft'] as Map)),
        question: data['question'] as String?);
    if (data['ready'] != result.ready) {
      throw const FormatException('Inconsistent voice interpretation');
    }
    return result;
  }
}
