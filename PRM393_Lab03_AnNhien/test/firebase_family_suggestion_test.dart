import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/services/firebase_family_suggestion_service.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/suggestion.dart';

void main() {
  test('Firebase schema preserves dates, sender and partial accepted task IDs',
      () {
    final s = FirebaseFamilySuggestionService.decode('request', {
      'senderUid': 'child',
      'senderName': 'Mai',
      'status': 'partial',
      'createdAt': DateTime(2026, 11, 6),
      'message': 'Mẹ chọn nhé',
      'acceptedIds': ['suggestion-request-1'],
      'tasks': [
        const TaskItem(
                id: 'a',
                title: 'Đi bộ',
                habitKey: 'move',
                hour: 8,
                minute: 15,
                startDate: '2026-11-07',
                repeat: RepeatRule.once)
            .toMap(),
        const TaskItem(
                id: 'b',
                title: 'Uống trà',
                habitKey: 'tea',
                hour: 15,
                minute: 0,
                startDate: '2026-11-07',
                repeat: RepeatRule.once)
            .toMap(),
      ],
    });
    expect(s.fromName, 'Mai');
    expect(s.fromUid, 'child');
    expect(s.status, SuggestionStatus.partial);
    expect(s.remaining.single.title, 'Đi bộ');
    expect(s.items.last.accepted, true);
    expect(s.items.first.date, DateTime(2026, 11, 7));
    expect(s.items.first.hour, 8);
  });
}
