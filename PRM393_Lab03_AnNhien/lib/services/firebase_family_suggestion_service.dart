import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/suggestion.dart';
import '../models/task_item.dart';
import '../utils/app_error.dart';
import 'firebase_pairing_service.dart';
import 'firebase_repositories.dart';
import 'suggestion_service.dart';

/// Adapter for the main family UI, using the same documents/callables as inbox.
/// Accepting is atomic on the server; the ViewModel must not save tasks twice.
class FirebaseFamilySuggestionService implements AtomicSuggestionService {
  FirebaseFamilySuggestionService(this.data, this.client);
  final FirebaseUserData data;
  final FirebaseCallableClient client;

  void _owner(String uid) {
    if (data.auth.currentUser?.uid != uid) {
      throw const AppException(
          'Tài khoản đã thay đổi. Bác mở lại màn hình nhé.');
    }
  }

  static Suggestion decode(String id, Map<String, dynamic> map) {
    final accepted = (map['acceptedIds'] as List? ?? []).cast<String>();
    final tasks = (map['tasks'] as List? ?? []).indexed.map((entry) {
      final t = TaskItem.fromMap(
          '$id-${entry.$1}', Map<String, Object?>.from(entry.$2 as Map));
      return SuggestionItem(
          title: t.title,
          habitKey: t.habitKey,
          date: parseDateKey(t.startDate) ?? DateTime.now(),
          hour: t.hour,
          minute: t.minute,
          durationMin: t.durationMinutes,
          timeOptions: [
            SuggestionTime(t.hour, t.minute),
            SuggestionTime((t.hour + 1) % 24, t.minute)
          ],
          accepted: accepted.contains('suggestion-$id-${entry.$1}'));
    }).toList();
    return Suggestion.fromMap(id, {
      'fromUid': map['senderUid'],
      'fromName': map['senderName'] ?? 'Người thân',
      'message': map['message'],
      'status': map['status'],
      'createdAt': map['createdAt'],
      'popupShown': map['popupShown'],
      'items': tasks.map((t) => t.toMap()).toList(),
    });
  }

  @override
  Future<void> send(String momUid, Suggestion s) async {
    // A stable ID on the draft makes retry after a lost response idempotent.
    if (s.id.isEmpty) throw const AppException('Bác mở lại bản gợi ý nhé.');
    await client.call('sendSuggestion', {
      'momUid': momUid,
      'id': s.id,
      'message': s.message,
      'tasks': [
        for (var i = 0; i < s.items.length; i++)
          s.items[i].toTask('draft-$i').toMap()
      ],
    });
  }

  @override
  Stream<List<Suggestion>> watchPending(String momUid) async* {
    _owner(momUid);
    try {
      await for (final snapshot in data
          .collection('suggestions')
          .where('status', whereIn: ['pending', 'partial']).snapshots()) {
        _owner(momUid);
        yield snapshot.docs.map((d) => decode(d.id, d.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      throw AppException('Chưa tải được gợi ý. Bác thử lại nhé.', cause: e);
    }
  }

  @override
  Future<Suggestion?> byId(String momUid, String id) async {
    _owner(momUid);
    final doc =
        await data.run(() => data.collection('suggestions').doc(id).get());
    _owner(momUid);
    return doc.exists ? decode(doc.id, doc.data()!) : null;
  }

  @override
  Future<void> accept(
      String momUid, String id, List<SuggestionItem> items) async {
    final s = await byId(momUid, id);
    if (s == null) throw const AppException('Không tìm thấy gợi ý.');
    final selected = <int>[];
    final times = <String, Object>{};
    for (final item in items) {
      final i = s.items.indexWhere((t) => t.sameTaskAs(item) && !t.accepted);
      if (i < 0)
        throw const AppException('Gợi ý đã thay đổi. Bác tải lại nhé.');
      selected.add(i);
      times['$i'] = {'hour': item.hour, 'minute': item.minute};
    }
    _owner(momUid);
    await client.call(
        'resolveSuggestion', {'id': id, 'selected': selected, 'times': times});
  }

  @override
  Future<void> dismiss(String momUid, String id) async {
    _owner(momUid);
    await client.call('resolveSuggestion', {'id': id, 'selected': <int>[]});
  }

  @override
  Future<void> undoDismiss(String momUid, String id) async {
    _owner(momUid);
    await client.call('undoDismiss', {'id': id});
  }

  @override
  Future<void> markPopupShown(String momUid, String id) async {
    _owner(momUid);
    await data.run(() =>
        data.collection('suggestions').doc(id).update({'popupShown': true}));
  }
}
