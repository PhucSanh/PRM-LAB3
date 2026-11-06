import '../models/voice_task_draft.dart';
import '../utils/app_error.dart';

abstract interface class VoiceTaskService {
  /// [userContext]: cách xưng hô, giờ thức dậy, khung giờ đã bận (không có tên
  /// việc). Giúp hiểu "khi thức dậy", "sau bữa sáng", "sau khi đi bộ".
  Future<VoiceTaskInterpretation> interpret(List<String> utterances,
      {DateTime? contextDate, VoiceUserContext? userContext});
}

/// Hiểu lời nói chưa được bật ở server (chưa deploy callable / chưa có key).
/// Khác lỗi mạng: lỗi này cho phép chuyển sang bộ hiểu trên máy.
class VoiceUnavailableException extends AppException {
  const VoiceUnavailableException()
      : super('Hiểu lời nói chưa được bật. Bác có thể nhập lịch bằng tay.');
}

/// Test/preview fixture only; production always uses the authenticated callable.
class FakeVoiceTaskService implements VoiceTaskService {
  FakeVoiceTaskService({this.result});
  final VoiceTaskInterpretation? result;
  @override
  Future<VoiceTaskInterpretation> interpret(List<String> utterances,
      {DateTime? contextDate, VoiceUserContext? userContext}) async {
    if (result != null) return result!;
    throw const AppException(
        'Hiểu lời nói chưa được bật trong bản xem thử. Bác có thể nhập tay.');
  }
}

/// Gọi [primary] (Groq); chỉ khi server báo chưa bật thì dùng [fallback]
/// (bộ hiểu trên máy). Lỗi mạng, quota… vẫn trả về cho Bác như cũ.
class FallbackVoiceTaskService implements VoiceTaskService {
  FallbackVoiceTaskService(this.primary, this.fallback);
  final VoiceTaskService primary, fallback;

  @override
  Future<VoiceTaskInterpretation> interpret(List<String> utterances,
      {DateTime? contextDate, VoiceUserContext? userContext}) async {
    try {
      return await primary.interpret(utterances,
          contextDate: contextDate, userContext: userContext);
    } on VoiceUnavailableException {
      return fallback.interpret(utterances,
          contextDate: contextDate, userContext: userContext);
    }
  }
}
