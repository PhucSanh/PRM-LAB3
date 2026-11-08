import 'package:cloud_functions/cloud_functions.dart';
import 'package:clock/clock.dart';
import '../utils/app_error.dart';

enum AssistantAction {
  chat,
  readScreen,
  schedule,
  family,
  settings,
  createTask,
  createFamily,
  callFamily,
  editTask,
  deleteTask
}

class AssistantReply {
  const AssistantReply(this.text, this.action,
      {this.target = '', this.day, this.onDevice = false});
  final String text;
  final AssistantAction action;
  final String target;
  final bool onDevice;
  final DateTime? day;
}

abstract interface class AssistantService {
  Future<AssistantReply> reply(List<Map<String, String>> messages);
}

class FirebaseAssistantService implements AssistantService {
  FirebaseAssistantService(this.functions);
  final FirebaseFunctions functions;

  @override
  Future<AssistantReply> reply(List<Map<String, String>> messages) async {
    try {
      final result = await functions
          .httpsCallable('talkToAssistant',
              options:
                  HttpsCallableOptions(timeout: const Duration(seconds: 35)))
          .call<Map<String, dynamic>>({'messages': messages});
      final text = result.data['reply'];
      final action = result.data['action'];
      if (text is! String ||
          text.trim().isEmpty ||
          !AssistantAction.values.any((a) => a.name == action)) {
        throw const FormatException();
      }
      return AssistantReply(text.trim(),
          AssistantAction.values.firstWhere((a) => a.name == action),
          target: result.data['target'] as String? ?? '',
          day: DateTime.tryParse(result.data['date'] as String? ?? ''));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' || e.code == 'failed-precondition') {
        throw const AssistantUnavailableException();
      }
      throw AppException(switch (e.code) {
        'unauthenticated' => 'Bác đăng nhập để trò chuyện với cháu nhé.',
        'resource-exhausted' => 'Bác chờ một lát rồi nói tiếp nhé.',
        'not-found' ||
        'failed-precondition' =>
          'Trò chuyện chưa sẵn sàng. Bác vẫn có thể dùng nút đọc hoặc nói để thêm lịch.',
        _ => 'Chưa kết nối được với trợ lý. Bác thử lại nhé.',
      });
    } catch (_) {
      throw const AppException('Chưa nhận được câu trả lời. Bác thử lại nhé.');
    }
  }
}

/// Available without a deployed backend. This is a local command recognizer,
/// and is identified as such in the interface rather than presented as an LLM.
class LocalAssistantService implements AssistantService {
  String _plain(String text) {
    const groups = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    var result = text.toLowerCase();
    for (final entry in groups.entries) {
      for (final letter in entry.value.split('')) {
        result = result.replaceAll(letter, entry.key);
      }
    }
    return result;
  }

  @override
  Future<AssistantReply> reply(List<Map<String, String>> messages) async {
    final text = _plain(messages.last['content'] ?? '');
    final today = clock.now();
    var day = DateTime(
        today.year,
        today.month,
        today.day +
            (text.contains('ngay kia')
                ? 2
                : text.contains('mai')
                    ? 1
                    : 0));
    AssistantReply answer(String reply, AssistantAction action,
            {DateTime? date, String target = ''}) =>
        AssistantReply(reply, action,
            day: date, target: target, onDevice: true);
    bool has(String pattern) => RegExp(pattern).hasMatch(text);
    if (has(r'\b(them|tao|luu)\b') &&
        has(r'\b(nguoi than|lien he|danh ba)\b')) {
      return answer(
          'Cháu mở phần thêm người thân để Bác nhập tên, chọn mối quan hệ và số điện thoại nhé.',
          AssistantAction.createFamily);
    }
    if (has(r'\bgoi\b')) {
      final target = text
          .substring(RegExp(r'\bgoi\b').firstMatch(text)!.end)
          .replaceFirst(RegExp(r'^\s*(?:dien\s+)?(?:cho\s+)?'), '')
          .replaceFirst(RegExp(r'\s+(?:nhe|nha|giup bac|giup toi)[.!?]*$'), '')
          .trim();
      return answer(
          'Bác chọn người thân muốn gọi nhé.', AssistantAction.callFamily,
          target: target);
    }

    final explicit = RegExp(
            r'\bngay\s+(\d{1,2})\s+(?:thang|/)\s*(\d{1,2})(?:\s+nam\s+(\d{4}))?')
        .firstMatch(text);
    if (explicit != null) {
      final d = int.parse(explicit[1]!), m = int.parse(explicit[2]!);
      final y = int.tryParse(explicit[3] ?? '') ?? today.year;
      final parsed = DateTime(y, m, d);
      if (parsed.year != y || parsed.month != m || parsed.day != d) {
        return answer('Ngày này chưa hợp lệ. Bác nói lại ngày và tháng nhé.',
            AssistantAction.chat);
      }
      day = parsed;
    } else if (has(
            r'\b(tuan|thang|nam|thu hai|thu ba|thu tu|thu nam|thu sau|thu bay|chu nhat|hom qua|ngay \d)\b') &&
        !has(r'\b(them|nhac|dat lich|len lich)\b')) {
      return answer(
          'Bác nói một ngày cụ thể giúp cháu nhé, ví dụ “xem lịch ngày 10 tháng 11”.',
          AssistantAction.chat);
    }

    if (has(r'\b(xoa|huy|bo lich|bo viec)\b')) {
      return answer('Bác chọn việc muốn xoá rồi xác nhận nhé.',
          AssistantAction.deleteTask,
          date: day);
    }
    if (has(r'\b(sua|doi gio|doi lich|doi ten|chinh lich)\b')) {
      return answer('Bác chọn việc muốn sửa nhé.', AssistantAction.editTask,
          date: day);
    }
    if (has(r'\b(them|nhac|dat lich|len lich)\b')) {
      return answer('Cháu sẽ giúp Bác kiểm tra bản nháp lịch.',
          AssistantAction.createTask);
    }
    if (has(r'\b(doc|nghe)\b') && has(r'\b(man hinh|chu|noi dung)\b')) {
      return answer('Cháu đọc nội dung màn hình cho Bác nhé.',
          AssistantAction.readScreen);
    }
    if (has(r'\b(lich|hom nay lam gi|mai lam gi|viec gi)\b')) {
      return answer('Cháu xem lịch cho Bác nhé.', AssistantAction.schedule,
          date: day);
    }
    if (has(r'\b(gia dinh|nguoi than|danh ba)\b')) {
      return answer(
          'Bác mở gia đình bằng nút bên dưới nhé.', AssistantAction.family);
    }
    if (has(r'\b(cai dat|co chu|chu to|chu nho)\b')) {
      return answer(
          'Bác mở cài đặt để điều chỉnh nhé.', AssistantAction.settings);
    }
    if (has(r'\b(chao|cam on)\b')) {
      return answer(
          'Cháu ở đây để giúp Bác. Bác muốn xem lịch, thêm việc hay gọi người thân?',
          AssistantAction.chat);
    }
    return answer(
        'Cháu đang hỗ trợ trên điện thoại. Bác có thể nói “đọc màn hình”, “xem lịch hôm nay”, “thêm lịch”, “sửa lịch”, “xoá lịch” hoặc “gọi người thân”.',
        AssistantAction.chat);
  }
}

class AvailableAssistantService implements AssistantService {
  AvailableAssistantService(this.remote, this.local);
  final AssistantService remote, local;
  bool _localOnly = false;
  @override
  Future<AssistantReply> reply(List<Map<String, String>> messages) async {
    if (_localOnly) return local.reply(messages);
    try {
      return await remote.reply(messages);
    } on AssistantUnavailableException {
      _localOnly = true;
      return local.reply(messages);
    }
  }
}

class AssistantUnavailableException implements Exception {
  const AssistantUnavailableException();
}
