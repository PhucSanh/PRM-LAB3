import '../models/task_item.dart';
import '../models/voice_task_draft.dart';
import '../services/local_voice_task_service.dart' show foldVietnamese;

/// Lệnh Bác nói về lịch hôm nay (không phải thêm việc mới). Nhận diện trên
/// máy bằng luật; câu nói không bao giờ được gửi cho AI để tự ghi lịch.
enum VoiceCommandKind { complete, next }

final _reComplete = RegExp(
    r'\b(?:lam\s+xong|da\s+xong|xong\s+(?:roi|ru[io]i|viec|het)|hoan\s+thanh|da\s+lam\s+(?:roi|ru[io]i|viec)|lam\s+(?:roi|ru[io]i)|danh\s+dau\s+(?:xong|da\s+lam))\b');
final _reNext = RegExp(
    r'\b(?:viec\s+(?:tiep\s+theo|ke\s+tiep|sau|tiep)|tiep\s+theo\s+(?:la\s+)?(?:gi|viec\s+gi)|con\s+viec\s+gi|lam\s+gi\s+(?:tiep|nua|tiep\s+theo))\b');
// Câu thêm việc mới ("nhắc tôi hoàn thành báo cáo lúc 8 giờ") không phải lệnh.
final _reAddIntent =
    RegExp(r'\b(?:nhac|them|len\s+lich|dat\s+lich|hen)\b.*\d|\d.*\b(?:nhac)\b');

VoiceCommandKind? parseVoiceCommand(String text) {
  final f = foldVietnamese(text);
  if (_reAddIntent.hasMatch(f)) return null;
  if (_reComplete.hasMatch(f)) return VoiceCommandKind.complete;
  if (_reNext.hasMatch(f)) return VoiceCommandKind.next;
  return null;
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
