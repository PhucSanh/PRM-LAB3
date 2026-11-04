import '../models/task_item.dart';
import '../utils/app_error.dart';
import 'firebase_pairing_service.dart';
import 'firebase_repositories.dart';
import 'caregiver_suggestion_service.dart';

class FirebaseSuggestionService implements SuggestionService {
  FirebaseSuggestionService(this.data, this.client);
  final FirebaseUserData data;
  final FirebaseCallableClient client;
  @override
  Stream<List<ScheduleSuggestion>> watchPending() async* {
    try {
      await for (final s in data
          .collection('suggestions')
          .where('status', isEqualTo: 'pending')
          .snapshots()) {
        yield s.docs.map((d) {
          final m = d.data();
          return ScheduleSuggestion(
              id: d.id,
              senderUid: m['senderUid'] as String,
              status: m['status'] as String,
              message: m['message'] as String? ?? '',
              tasks: (m['tasks'] as List)
                  .indexed
                  .map((e) => TaskItem.fromMap('${d.id}-${e.$1}',
                      Map<String, Object?>.from(e.$2 as Map)))
                  .toList());
        }).toList();
      }
    } catch (e) {
      throw AppException('Chưa tải được gợi ý. Bác thử lại nhé.', cause: e);
    }
  }

  @override
  Future<String> send(String momUid, String requestId, List<TaskItem> tasks,
      {String message = ''}) async {
    await client.call('sendSuggestion', {
      'momUid': momUid,
      'id': requestId,
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'message': message
    });
    return requestId;
  }

  @override
  Future<void> resolve(String id, List<int> selected,
      {Map<int, ({int hour, int minute})> times = const {}}) async {
    await client.call('resolveSuggestion', {
      'id': id,
      'selected': selected,
      'times': {
        for (final e in times.entries)
          '${e.key}': {'hour': e.value.hour, 'minute': e.value.minute}
      }
    });
  }

  @override
  Future<void> undoDismiss(String id) async {
    await client.call('undoDismiss', {'id': id});
  }
}
