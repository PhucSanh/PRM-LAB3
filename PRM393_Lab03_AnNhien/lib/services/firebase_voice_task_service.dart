import 'package:cloud_functions/cloud_functions.dart';
import '../models/task_item.dart';
import '../models/voice_task_draft.dart';
import '../utils/app_error.dart';
import 'voice_task_service.dart';

class FirebaseVoiceTaskService implements VoiceTaskService {
  FirebaseVoiceTaskService(FirebaseFunctions functions)
      : _call = ((data) async => (await functions
                .httpsCallable('interpretVoiceTask',
                    options: HttpsCallableOptions(
                        timeout: const Duration(seconds: 35)))
                .call<Map<String, dynamic>>(data))
            .data);
  FirebaseVoiceTaskService.withCaller(this._call);
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) _call;

  @override
  Future<VoiceTaskInterpretation> interpret(List<String> utterances,
      {DateTime? contextDate}) async {
    try {
      final data = await _call({
        'utterances': utterances,
        if (contextDate != null) 'contextDate': dateKey(contextDate)
      });
      return VoiceTaskInterpretation.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      // Never expose provider responses, keys or transcript in user-facing errors.
      throw AppException(switch (e.code) {
        'unauthenticated' => 'Bác đăng nhập lại để dùng hiểu lời nói nhé.',
        'failed-precondition' ||
        'not-found' =>
          'Hiểu lời nói chưa được bật. Bác có thể nhập lịch bằng tay.',
        'resource-exhausted' =>
          'Đã thử nhiều lần. Bác chờ một lát hoặc nhập tay nhé.',
        'unavailable' ||
        'deadline-exceeded' =>
          'Chưa kết nối được. Bác thử lại hoặc nhập tay nhé.',
        _ => 'Chưa hiểu rõ câu nói. Bác thử nói lại hoặc nhập tay nhé.',
      });
    } catch (_) {
      throw const AppException(
          'Chưa hiểu rõ câu nói. Bác thử nói lại hoặc nhập tay nhé.');
    }
  }
}
