import '../models/task_item.dart';
import '../models/voice_task_draft.dart';
import '../services/local_voice_task_service.dart' show foldVietnamese;

/// Lệnh Bác nói về lịch hôm nay (không phải thêm việc mới). Nhận diện trên
/// máy bằng luật; câu nói không bao giờ được gửi cho AI để tự ghi lịch.
/// [agenda]: Bác hỏi lịch một ngày ("công việc ngày mai", "hôm nay phải làm
/// gì") – chỉ đọc lịch, không thêm việc.
enum VoiceCommandKind { complete, next, agenda }

final _reComplete = RegExp(
    r'\b(?:lam\s+xong|da\s+xong|xong\s+(?:roi|ru[io]i|viec|het)|hoan\s+thanh|da\s+lam\s+(?:roi|ru[io]i|viec)|lam\s+(?:roi|ru[io]i)|danh\s+dau\s+(?:xong|da\s+lam))\b');
final _reNext = RegExp(
    r'\b(?:viec\s+(?:tiep\s+theo|ke\s+tiep|sau|tiep)|tiep\s+theo\s+(?:la\s+)?(?:gi|viec\s+gi)|con\s+viec\s+gi|lam\s+gi\s+(?:tiep|nua|tiep\s+theo))\b');
// Câu thêm việc mới ("nhắc tôi hoàn thành báo cáo lúc 8 giờ") không phải lệnh.
final _reAddIntent =
    RegExp(r'\b(?:nhac|them|len\s+lich|dat\s+lich|hen)\b.*\d|\d.*\b(?:nhac)\b');

// Hỏi về lịch: "công việc", "những việc", "lịch", "việc gì", "phải làm gì"…
final _reAgenda = RegExp(
    r'\b(?:cong\s+viec|nhung\s+viec|cac\s+viec|lich|viec\s+(?:gi|nao)|co\s+viec|lam\s+gi|phai\s+lam|sap\s+toi|ke\s+hoach)\b');
// Có động từ thêm việc ("nhắc", "thêm", "lên lịch"…) thì là thêm việc mới.
final _reAddVerb = RegExp(
    r'\b(?:nhac|them|tao|hen|len\s+lich|dat\s+lich|xep\s+lich|ghi\s+lich)\b');
final _reWeekdayNumber = RegExp(r'\bthu\s*[2-7]\b');
const _weekdays = {
  'thu hai': DateTime.monday,
  'thu ba': DateTime.tuesday,
  'thu tu': DateTime.wednesday,
  'thu nam': DateTime.thursday,
  'thu sau': DateTime.friday,
  'thu bay': DateTime.saturday,
  'chu nhat': DateTime.sunday,
};

VoiceCommandKind? parseVoiceCommand(String text) {
  final f = foldVietnamese(text);
  if (_reAddIntent.hasMatch(f)) return null;
  if (_reComplete.hasMatch(f)) return VoiceCommandKind.complete;
  // "Ngày mai còn việc gì" hỏi ngày khác, không phải việc kế tiếp hôm nay.
  final otherDay = agendaDayOffset(text, DateTime(2000, 1, 3)) != 0;
  if (_reNext.hasMatch(f) && !otherDay) return VoiceCommandKind.next;
  if (_isAgenda(f)) return VoiceCommandKind.agenda;
  if (_reNext.hasMatch(f)) return VoiceCommandKind.next;
  return null;
}

/// Câu hỏi lịch: có từ hỏi lịch, không có động từ thêm việc, không nêu giờ.
bool _isAgenda(String folded) {
  if (!_reAgenda.hasMatch(folded) || _reAddVerb.hasMatch(folded)) {
    return false;
  }
  // "thứ 5" là ngày, không phải giờ; số khác (8 giờ, 15 phút) là thêm việc.
  return !RegExp(r'\d').hasMatch(folded.replaceAll(_reWeekdayNumber, ''));
}

/// Bác hỏi lịch ngày nào, tính từ [today]: 0 = hôm nay (mặc định),
/// 1 = mai, 2 = ngày kia / ngày mốt, hoặc thứ trong tuần gần nhất.
int agendaDayOffset(String text, DateTime today) {
  final f = foldVietnamese(text);
  if (RegExp(r'\b(?:ngay\s+kia|ngay\s+mot)\b').hasMatch(f)) return 2;
  if (RegExp(r'\b(?:ngay\s+mai|sang\s+mai|chieu\s+mai|toi\s+mai|mai)\b')
      .hasMatch(f)) {
    return 1;
  }
  int? weekday;
  for (final e in _weekdays.entries) {
    if (f.contains(e.key)) weekday = e.value;
  }
  final n = RegExp(r'\bthu\s*([2-7])\b').firstMatch(f);
  if (n != null) weekday = int.parse(n.group(1)!) - 1;
  if (weekday == null) return 0;
  return (weekday - today.weekday + 7) % 7;
}

int _start(TaskItem t) => t.hour * 60 + t.minute;
bool _open(TaskItem t) =>
    t.status == TaskStatus.pending || t.status == TaskStatus.postponed;

const _stopWords = {
  'viec',
  'nay',
  'roi',
  'xong',
  'lam',
  'da',
  'toi',
  'tui',
  'bac',
  'cua',
  'va',
  'cho',
  'voi',
  'nhe',
  'rui',
  'gio',
  'ban',
  'noi',
  'danh',
  'dau',
  'hoan',
  'thanh',
  'tiep',
  'theo',
  'ke',
};

/// Việc Bác nói tên (khớp nhiều từ nhất trong tên việc), hoặc `null`.
TaskItem? _named(String text, List<TaskItem> open) {
  final said = foldVietnamese(text).split(RegExp(r'[^a-z0-9]+')).toSet();
  TaskItem? best;
  var bestScore = 0;
  for (final t in open) {
    final words = foldVietnamese(t.title)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 1 && !_stopWords.contains(w))
        .toSet();
    if (words.isEmpty) continue;
    final hits = words.where(said.contains).length;
    final enough = hits >= 2 || (hits == 1 && words.length == 1);
    if (enough && hits > bestScore) {
      best = t;
      bestScore = hits;
    }
  }
  return best;
}

/// Việc Bác vừa làm: việc Bác nêu tên; nếu không, việc chưa xong đã tới giờ
/// gần nhất; nếu chưa tới giờ việc nào thì việc sớm nhất còn lại.
TaskItem? taskToComplete(String text, List<TaskItem> today, DateTime now) {
  final open = today.where(_open).toList()
    ..sort((a, b) => _start(a).compareTo(_start(b)));
  if (open.isEmpty) return null;
  final named = _named(text, open);
  if (named != null) return named;
  final minute = now.hour * 60 + now.minute;
  final started = open.where((t) => _start(t) <= minute).toList();
  return started.isNotEmpty ? started.last : open.first;
}

/// Việc chưa làm kế tiếp sau [now] (hoặc việc còn sót sớm nhất), bỏ [except].
TaskItem? nextOpenTask(List<TaskItem> today, DateTime now, {String? except}) {
  final open = today.where((t) => _open(t) && t.id != except).toList()
    ..sort((a, b) => _start(a).compareTo(_start(b)));
  if (open.isEmpty) return null;
  final minute = now.hour * 60 + now.minute;
  return open.where((t) => _start(t) >= minute).firstOrNull ?? open.first;
}

String _time(TaskItem t) => '${t.hour.toString().padLeft(2, '0')}:'
    '${t.minute.toString().padLeft(2, '0')}';

String nextTaskSentence(TaskItem? next) => next == null
    ? 'Hôm nay Bác không còn việc nào nữa. Bác nghỉ ngơi nhé.'
    : 'Việc tiếp theo của Bác: “${next.title}” lúc ${_time(next)}, '
        'làm trong ${durationText(next.durationMinutes)}.';

String completedSentence(TaskItem done, TaskItem? next) =>
    'Cháu đã đánh dấu xong “${done.title}”. ${nextTaskSentence(next)}';

const _weekdayNames = [
  'thứ Hai',
  'thứ Ba',
  'thứ Tư',
  'thứ Năm',
  'thứ Sáu',
  'thứ Bảy',
  'Chủ nhật'
];

/// Số việc đọc to tối đa; còn lại Bác xem trong Lịch.
const agendaReadLimit = 6;

/// Câu trả lời khi Bác hỏi lịch ngày [day] ([offset] ngày tính từ hôm nay).
/// Hôm nay chỉ kể việc chưa làm; ngày khác kể mọi việc trừ việc đã bỏ qua.
String agendaSentence(DateTime day, int offset, List<TaskItem> tasks) {
  final weekday = _weekdayNames[day.weekday - 1];
  final date = '$weekday, ngày ${day.day}/${day.month}';
  final when = switch (offset) {
    0 => 'Hôm nay, $date,',
    1 => 'Ngày mai, $date,',
    2 => 'Ngày kia, $date,',
    _ => '${weekday[0].toUpperCase()}${weekday.substring(1)} '
        'ngày ${day.day}/${day.month},',
  };
  final list = tasks
      .where((t) => offset == 0 ? _open(t) : t.status != TaskStatus.skipped)
      .toList()
    ..sort((a, b) => _start(a).compareTo(_start(b)));
  if (list.isEmpty) {
    return offset == 0
        ? '$when Bác không còn việc nào nữa. Bác nghỉ ngơi nhé.'
        : '$when Bác chưa có việc nào. Muốn thêm việc, Bác nói tên việc và giờ nhé.';
  }
  final read = list.take(agendaReadLimit).map((t) =>
      '“${t.title}” lúc ${_time(t)}, ${durationText(t.durationMinutes)}');
  final more = list.length - agendaReadLimit;
  return '$when Bác ${offset == 0 ? 'còn' : 'có'} ${list.length} việc: '
      '${read.join('; ')}.'
      '${more > 0 ? ' Còn $more việc nữa, Bác xem trong Lịch nhé.' : ''}';
}
