import '../models/voice_task_draft.dart';
import '../utils/app_error.dart';

abstract interface class VoiceTaskService {
  Future<VoiceTaskInterpretation> interpret(List<String> utterances,
      {DateTime? contextDate});
}

/// Test/preview fixture only; production always uses the authenticated callable.
class FakeVoiceTaskService implements VoiceTaskService {
  FakeVoiceTaskService({this.result});
  final VoiceTaskInterpretation? result;
  @override
  Future<VoiceTaskInterpretation> interpret(List<String> utterances,
      {DateTime? contextDate}) async {
    if (result != null) return result!;
    throw const AppException(
        'Hiểu lời nói chưa được bật trong bản xem thử. Bác có thể nhập tay.');
  }
}
