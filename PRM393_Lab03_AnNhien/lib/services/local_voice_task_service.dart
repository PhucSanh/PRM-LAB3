import 'package:clock/clock.dart';

import '../models/task_item.dart';
import '../models/voice_task_draft.dart';
import '../utils/app_error.dart';
import 'voice_task_service.dart';

/// Bộ hiểu lời nói tiếng Việt chạy ngay trên máy, theo luật (không gọi mạng).
///
/// Dùng khi callable Groq chưa bật (chưa deploy / chưa có key) và trong
/// test/demo. Luật giống backend: không tự bịa giờ khi "8 giờ" chưa rõ
/// sáng/tối, thiếu ngày thì hỏi lại, thời điểm đã qua thì hỏi lại.
/// Có dùng [VoiceUserContext]: "khi thức dậy", "sau bữa sáng", "sau khi đi bộ".
class LocalVoiceTaskService implements VoiceTaskService {
  LocalVoiceTaskService({DateTime Function()? now}) : _now = now ?? clock.now;
  final DateTime Function() _now;

  @override
  Future<VoiceTaskInterpretation> interpret(List<String> utterances,
      {DateTime? contextDate, VoiceUserContext? userContext}) async {
    if (utterances.isEmpty ||
        utterances.length > 4 ||
        utterances.any((s) => s.trim().isEmpty || s.length > 500)) {
      throw const AppException(
          'Bác nói ngắn gọn một việc cần thêm vào lịch nhé.');
    }
    return interpretVietnamese(utterances,
        now: _now(), context: userContext ?? const VoiceUserContext());
  }
}

// ---------------------------------------------------------------------------
// Bỏ dấu, giữ nguyên độ dài chuỗi để vị trí khớp regex trùng với câu gốc.

const _accented =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
final _plain = '${'a' * 17}${'e' * 11}${'i' * 5}${'o' * 17}${'u' * 11}'
    '${'y' * 5}d';
final Map<String, String> _foldMap = {
  for (var i = 0; i < _accented.length; i++) _accented[i]: _plain[i]
};

/// Chữ thường, không dấu, cùng độ dài với [text].
String foldVietnamese(String text) {
  final out = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final lower = text[i].toLowerCase();
    final c = lower.length == 1 ? lower : text[i];
    out.write(_foldMap[c] ?? c);
  }
  return out.toString();
}

// ---------------------------------------------------------------------------

class _Parsed {
  String? title;
  int? rawHour, minute, wakeOffset, relativeDays;
  String? afterHabit;
  String? period;
  DateTime? explicitDate;
  List<int> weekdays = [];
  bool weekShift = false, repeatList = false, unsupported = false;
  RepeatRule? repeat;
}

class _Text {
  _Text(this.original)
      : folded = foldVietnamese(original),
        used = List<bool>.filled(original.length, false);
  final String original, folded;
  final List<bool> used;

  /// Mọi lần khớp chưa bị đánh dấu; đánh dấu đoạn khớp (hoặc nhóm [group]).
  Iterable<RegExpMatch> take(RegExp pattern, {bool mark = true}) sync* {
    for (final m in pattern.allMatches(folded).toList()) {
      if (_overlaps(m.start, m.end)) continue;
      if (mark) markRange(m.start, m.end);
      yield m;
    }
  }

  RegExpMatch? first(RegExp pattern, {bool mark = true}) {
    for (final m in take(pattern, mark: mark)) {
      return m;
    }
    return null;
  }

  bool _overlaps(int s, int e) {
    for (var i = s; i < e; i++) {
      if (used[i]) return true;
    }
    return false;
  }

  void markRange(int s, int e) {
    for (var i = s; i < e; i++) {
      used[i] = true;
    }
  }

  String remaining() {
    final b = StringBuffer();
    for (var i = 0; i < original.length; i++) {
      b.write(used[i] ? ' ' : original[i]);
    }
    return b.toString();
  }
}

const _dayWord = r'(?:hai|ba|tu|nam|sau|bay|[2-7])';
int _weekdayOf(String token) => switch (token.trim()) {
      'hai' || '2' => 1,
      'ba' || '3' => 2,
      'tu' || '4' => 3,
      'nam' || '5' => 4,
      'sau' || '6' => 5,
      'bay' || '7' => 6,
      _ => 7,
    };

final _reUnsupported = RegExp(
    r'^\s*(?:xoa|huy|bo lich|sua|doi gio|danh dau|hoan thanh|da lam xong)\b');
final _reFiller = RegExp(
    r'\b(?:nhac|nho)\s+(?:toi|bac|ba|ong|minh|me|em|con|chau)\b|\b(?:giup|cho)\s+(?:toi|minh)\b|\btoi(?=\s+(?:muon|can|phai|se|hay)\b)');
final _reAfterMeal =
    RegExp(r'\bsau\s+(?:khi\s+)?(?:an\s+sang|bua\s+sang|an\s+diem\s+tam)\b');
final _reWake = RegExp(
    r'\b(?:(?:luc|khi|ngay\s+khi|vua|sau\s+khi)\s+(?:thuc|ngu)\s+day)\b');
final _reAfterHabit = RegExp(
    r'\bsau\s+(?:khi\s+)?(di\s+bo|tap(?:\s+the\s+duc)?|an\s+trua|an\s+toi|ngu\s+trua)\b');
final _rePeriodDate =
    RegExp(r'\b(?:buoi\s+)?(sang|trua|chieu|toi|dem)\s+(nay|mai)\b');
final _reRepeatPeriod =
    RegExp(r'\b(?:moi|hang)\s+(?:buoi\s+)?(sang|trua|chieu|toi)\b');
final _rePeriod = RegExp(r'\b(?:buoi\s+)?(sang|trua|chieu|toi|dem)\b');
final _reToday = RegExp(r'\bhom\s+nay\b');
final _reTomorrow =
    RegExp(r'\bngay\s+mai\b|^\s*mai\b|\bmai(?=\s+(?:luc|vao|\d))');
final _reDayAfter = RegExp(r'\bngay\s+(?:kia|mot)\b');
final _reNextWeek = RegExp(r'\btuan\s+(?:sau|toi)\b');
final _reExplicitDate = RegExp(
    r'\b(?:ngay\s+)?(\d{1,2})\s*(?:/|-|thang\s+)(\d{1,2})(?:\s*(?:/|-|nam\s+)(\d{4}))?\b');
final _reTime = RegExp(
    r'\b(\d{1,2})\s*(?:gio|h|:)\s*(?:(ruoi)|kem\s*(\d{1,2})(?:\s*phut)?|(\d{1,2})(?:\s*phut)?)?');
final _reDaily = RegExp(
    r'\b(?:moi|hang)\s+ngay\b|\bngay\s+nao\s+cung\b|\btat\s+ca\s+cac\s+ngay\b');
final _reWeekly = RegExp(r'\b(?:moi|hang)\s+tuan\b');
final _reMonthly = RegExp(r'\b(?:moi|hang)\s+thang\b');
final _reOnce = RegExp(r'\bmot\s+lan\b');
final _reWeekdays = RegExp(r'(?:\b(moi|cac|hang)\s+)?\b(?:thu\s*(' +
    _dayWord +
    r'(?:(?:\s*,\s*|\s+va\s+|\s+)(?:thu\s*)?' +
    _dayWord +
    r'\b)*)|chu\s+nhat)\b');

_Parsed _parseOne(String utterance) {
  final t = _Text(utterance);
  final p = _Parsed();
  if (_reUnsupported.hasMatch(t.folded)) p.unsupported = true;
  t.take(_reFiller).toList();

  if (t.first(_reAfterMeal) != null) p.wakeOffset = 60;
  if (t.first(_reWake) != null) p.wakeOffset = 0;
  final after = t.first(_reAfterHabit);
  if (after != null) {
    p.afterHabit = after.group(1)!.replaceAll(RegExp(r'\s+'), ' ');
  }

  for (final m in t.take(_reRepeatPeriod)) {
    p.repeat = RepeatRule.daily;
    p.period = m.group(1);
  }
  for (final m in t.take(_rePeriodDate)) {
    p.period = m.group(1);
    p.relativeDays = m.group(2) == 'nay' ? 0 : 1;
  }
  if (t.first(_reToday) != null) p.relativeDays = 0;
  if (t.first(_reDayAfter) != null) p.relativeDays = 2;
  if (t.first(_reTomorrow) != null) p.relativeDays = 1;
  if (t.first(_reNextWeek) != null) p.weekShift = true;

  for (final m in t.take(_reExplicitDate)) {
    final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
    final y = m.group(3) == null ? null : int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) continue;
    // Năm tạm = 0, sẽ chọn năm ở bước resolve.
    p.explicitDate = DateTime(y ?? 0, mo, d);
    if (DateTime(y ?? 2000, mo, d).month != mo) p.explicitDate = null;
  }

  for (final m in t.take(_reTime)) {
    final h = int.parse(m.group(1)!);
    if (h > 23) continue;
    var minute = 0, hour = h;
    if (m.group(2) != null) {
      minute = 30;
    } else if (m.group(3) != null) {
      final k = int.parse(m.group(3)!);
      if (k < 1 || k > 59) continue;
      hour = (h + 23) % 24;
      minute = 60 - k;
    } else if (m.group(4) != null) {
      minute = int.parse(m.group(4)!);
      if (minute > 59) continue;
    }
    p.rawHour = hour;
    p.minute = minute;
  }

  if (t.first(_reDaily) != null) p.repeat = RepeatRule.daily;
  if (t.first(_reMonthly) != null) p.repeat = RepeatRule.monthly;
  final weekly = t.first(_reWeekly) != null;
  if (t.first(_reOnce) != null) p.repeat = RepeatRule.once;

  for (final m in t.take(_reWeekdays)) {
    if (m.group(1) != null) p.repeatList = true;
    final list = m.group(2);
    if (list == null) {
      p.weekdays.add(7);
    } else {
      for (final w in RegExp(_dayWord).allMatches(list)) {
        p.weekdays.add(_weekdayOf(w.group(0)!));
      }
    }
  }
  p.weekdays = p.weekdays.toSet().toList()..sort();
  if (weekly) {
    p.repeat = p.weekdays.length > 1 ? RepeatRule.someDays : RepeatRule.weekly;
  } else if (p.repeatList || p.weekdays.length > 1) {
    p.repeat ??= RepeatRule.someDays;
  }

  // Chỉ lấy "buổi" lẻ sau khi đã gỡ các cụm có "tôi"/"sáng mai"…
  for (final m in t.take(_rePeriod)) {
    p.period = m.group(1);
  }
  p.title = _cleanTitle(t.remaining());
  return p;
}

final _leading = RegExp(
    r'^(?:nhac|nho|hay|giup|them|viec|lich|toi|bac|ba|ong|minh|em|can|phai|muon|se|la|de|vao|luc|thi|va|nhe|ngay|o)\b\s*');
final _trailing =
    RegExp(r'\s*\b(?:nhe|nha|a|voi|vao|luc|thi|va|cho|ngay|o|di nhe|nhe bac)$');
final _midLuc = RegExp(r'\b(?:vao\s+)?luc\b');

String? _cleanTitle(String raw) {
  var s = raw.replaceAll(RegExp(r'[.!?;:]'), ' ');
  s = _removeFolded(s, _midLuc);
  s = s.replaceAll(RegExp(r'\s*,\s*'), ', ').replaceAll(RegExp(r'\s+'), ' ');
  for (var changed = true; changed;) {
    final before = s;
    s = s.trim().replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '');
    final f = foldVietnamese(s);
    final lead = _leading.firstMatch(f);
    if (lead != null) s = s.substring(lead.end);
    final f2 = foldVietnamese(s);
    final trail = _trailing.firstMatch(f2);
    if (trail != null) s = s.substring(0, trail.start);
    changed = s != before;
  }
  s = s.replaceAll(RegExp(r'(,\s*){2,}'), ', ').trim();
  if (s.isEmpty || !RegExp(r'[^\d\s,]').hasMatch(s)) return null;
  if (s.length > 80) {
    final cut = s.substring(0, 80);
    final space = cut.lastIndexOf(' ');
    s = space > 20 ? cut.substring(0, space) : cut;
  }
  return s[0].toUpperCase() + s.substring(1);
}

String _removeFolded(String s, RegExp pattern) {
  final f = foldVietnamese(s);
  final b = StringBuffer();
  var last = 0;
  for (final m in pattern.allMatches(f)) {
    b
      ..write(s.substring(last, m.start))
      ..write(' ');
    last = m.end;
  }
  b.write(s.substring(last));
  return b.toString();
}

/// Nhóm Power 9 theo từ khoá trong tên việc. Không rõ thì `purpose`.
String habitKeyFor(String? title) {
  if (title == null) return 'purpose';
  final f = foldVietnamese(title);
  bool has(String pattern) => RegExp('\\b(?:$pattern)\\b').hasMatch(f);
  if (has(r'uong tra|tra|ca phe|cafe')) return 'tea';
  if (has(r'rau|dau|an chay|trai cay|hoa qua|hat|ngu coc')) return 'plant';
  if (has(
      r'di bo|tap|the duc|yoga|dap xe|boi|di dao|van dong|thai cuc|duong sinh|tuoi cay|lam vuon|nho co|quet')) {
    return 'move';
  }
  if (has(
      r'thien|nghi|ngu trua|tho|nghe nhac|thu gian|ngoi yen|xoa bop|ngam')) {
    return 'downshift';
  }
  if (has(r'chua|nha tho|le|sinh hoat|cau lac bo|clb|tinh nguyen|hoi')) {
    return 'belong';
  }
  if (has(r'ban|hang xom|choi co|danh co|tro chuyen|tan gau')) return 'tribe';
  if (has(r'goi|con|chau|gia dinh|me|bo|vo|chong|an com nha')) {
    return 'family';
  }
  if (has(r'an sang|an trua|an toi|bua|an nhe|an vua')) return 'eighty';
  return 'purpose';
}

int? _resolveHour(int h, String? period) {
  if (h == 0 || h >= 13) return h;
  return switch (period) {
    'sang' => h == 12 ? 0 : h,
    'trua' => h >= 10 ? h : h + 12,
    'chieu' => h == 12 ? 12 : h + 12,
    'toi' => h == 12 ? 0 : (h < 5 ? h : h + 12),
    'dem' => h == 12 ? 0 : (h >= 7 ? h + 12 : h),
    _ => h == 12 ? 12 : null,
  };
}

const _afterHabitKey = {
  'di bo': 'move',
  'tap': 'move',
  'tap the duc': 'move',
  'an trua': 'eighty',
  'an toi': 'eighty',
  'ngu trua': 'downshift',
};

// Match separate timed actions, preserving a time range inside one clause.
bool _hasMultipleTimedActivities(String utterance) {
  final clauses =
      foldVietnamese(utterance).split(RegExp(r'[,;]|\s+(?:va|roi|sau do)\s+'));
  final time = RegExp(
      r'(?:\d{1,2}\s*(?:gio|h)(?:\s*[0-5]?\d\s*(?:phut)?)?|\d{1,2}:[0-5]\d)');
  return clauses.where((clause) {
        final match = time.firstMatch(clause);
        if (match == null) return false;
        final action = clause
            .substring(match.end)
            .replaceFirst(
                RegExp(
                    r'^(?:\s*(?:buoi|sang|trua|chieu|toi|dem|nhac|bac|chau|luc|nua))+(?=\s|$)'),
                '')
            .trim();
        return RegExp('[a-z]').hasMatch(action);
      }).length >
      1;
}

/// Hiểu một chuỗi lời nói (câu đầu + các câu trả lời bổ sung).
VoiceTaskInterpretation interpretVietnamese(List<String> utterances,
    {required DateTime now,
    VoiceUserContext context = const VoiceUserContext()}) {
  // Discard the ambiguous multi-task draft when Bác chooses a single task.
  final conversation = _hasMultipleTimedActivities(utterances.first)
      ? utterances.skip(1).toList()
      : utterances;
  if (conversation.isEmpty || conversation.any(_hasMultipleTimedActivities)) {
    return const VoiceTaskInterpretation(
        draft: VoiceTaskDraft(
            repeat: RepeatRule.once, weekdays: [], habitKey: 'purpose'),
        question: 'Bác nói từng việc một nhé. Bác muốn thêm việc nào trước?',
        onDevice: true);
  }
  final parts = conversation.map(_parseOne).toList();
  final p = _Parsed();
  for (final part in parts) {
    p.title ??= part.title;
    p.rawHour = part.rawHour ?? p.rawHour;
    if (part.rawHour != null) p.minute = part.minute;
    p.wakeOffset = part.wakeOffset ?? p.wakeOffset;
    p.afterHabit = part.afterHabit ?? p.afterHabit;
    p.period = part.period ?? p.period;
    p.relativeDays = part.relativeDays ?? p.relativeDays;
    p.explicitDate = part.explicitDate ?? p.explicitDate;
    if (part.weekdays.isNotEmpty) p.weekdays = part.weekdays;
    p.weekShift |= part.weekShift;
    p.repeat = part.repeat ?? p.repeat;
  }
  p.unsupported = parts.first.unsupported;
  final today = DateTime(now.year, now.month, now.day);

  // --- Giờ ---
  int? hour, minute;
  if (p.rawHour != null) {
    hour = _resolveHour(p.rawHour!, p.period);
    minute = p.minute ?? 0;
  } else if (p.afterHabit != null) {
    final key = _afterHabitKey[p.afterHabit];
    final slot = context.busy.where((s) => s.habitKey == key).firstOrNull;
    if (slot != null) {
      final end = slot.hour * 60 + slot.minute + slot.durationMinutes;
      if (end < 24 * 60) {
        hour = end ~/ 60;
        minute = end % 60;
      }
    }
  } else if (p.wakeOffset != null && context.hasWakeTime) {
    final at = context.wakeHour! * 60 + context.wakeMinute! + p.wakeOffset!;
    hour = (at ~/ 60) % 24;
    minute = at % 60;
  }
  bool futureOn(DateTime day) =>
      hour == null ||
      DateTime(day.year, day.month, day.day, hour, minute ?? 0).isAfter(now);

  // --- Lặp ---
  var repeat = p.repeat ?? RepeatRule.once;
  var weekdays = p.weekdays;
  if (repeat == RepeatRule.once && weekdays.length > 1) {
    repeat = RepeatRule.someDays;
  }

  // --- Ngày ---
  DateTime? date;
  if (p.explicitDate != null) {
    final e = p.explicitDate!;
    date = DateTime(e.year == 0 ? now.year : e.year, e.month, e.day);
    if (e.year == 0 && date.isBefore(today)) {
      date = DateTime(now.year + 1, e.month, e.day);
    }
  } else if (p.relativeDays != null) {
    date = today.add(Duration(days: p.relativeDays!));
  } else if (weekdays.isNotEmpty) {
    var start = futureOn(today) ? today : today.add(const Duration(days: 1));
    if (p.weekShift) {
      start = today.add(Duration(days: 8 - today.weekday));
    }
    date = start;
    while (!weekdays.contains(date!.weekday)) {
      date = date.add(const Duration(days: 1));
    }
  } else if (repeat != RepeatRule.once) {
    date = futureOn(today) ? today : today.add(const Duration(days: 1));
  }
  if (repeat == RepeatRule.weekly && weekdays.isEmpty && date != null) {
    weekdays = [date.weekday];
  }
  if (!{RepeatRule.weekly, RepeatRule.someDays}.contains(repeat)) {
    weekdays = const [];
  }

  final draft = VoiceTaskDraft(
      title: p.title,
      date: date,
      hour: hour,
      minute: hour == null ? null : minute,
      repeat: repeat,
      weekdays: List.unmodifiable(weekdays),
      habitKey: habitKeyFor(p.title));

  String? question;
  if (p.unsupported) {
    question =
        'Bác nói một việc muốn thêm vào lịch nhé. Mục này chưa sửa hoặc xoá việc.';
  } else if (draft.title == null) {
    question = 'Bác muốn làm việc gì?';
  } else if (draft.date == null) {
    question = 'Bác muốn làm vào ngày nào?';
  } else if (draft.hour == null) {
    question = p.wakeOffset != null && !context.hasWakeTime
        ? 'Bác thường thức dậy lúc mấy giờ? Bác nói giờ cụ thể giúp cháu nhé.'
        : 'Bác muốn làm lúc mấy giờ, buổi sáng hay buổi chiều?';
  } else if (!draft.isFuture(now)) {
    question = 'Thời điểm này đã qua. Bác muốn chọn ngày và giờ nào khác?';
  } else if ({RepeatRule.weekly, RepeatRule.someDays}.contains(repeat) &&
      weekdays.isEmpty) {
    question = 'Bác muốn lặp vào những thứ nào trong tuần?';
  }
  return VoiceTaskInterpretation(
      draft: draft, question: question, onDevice: true);
}
