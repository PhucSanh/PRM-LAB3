import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/viewmodels/suggestion_review_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/services/firebase_family_suggestion_service.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/suggestion.dart';

class AtomicMemoryService extends FakeSuggestionService
    implements AtomicSuggestionService {
  AtomicMemoryService(this.tasks) : super(delay: Duration.zero);
  final TaskRepository tasks;
  int accepts = 0;
  @override
  Future<void> accept(String uid, String id, List<SuggestionItem> items,
      {List<int>? indexes}) async {
    accepts++;
    for (var i = 0; i < items.length; i++) {
      await tasks.save(items[i].toTask('suggestion-$id-${indexes?[i] ?? i}'));
    }
    await super.accept(uid, id, items, indexes: indexes);
  }
}

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
  test('atomic acceptance keeps both indexes for same-name tasks', () async {
    final repository = FakeTaskRepository([]);
    final service = AtomicMemoryService(repository);
    final day = DateTime(2099, 11, 7);
    await service.send(
        'elder',
        Suggestion(
            id: 'one',
            fromUid: 'child',
            fromName: 'Mai',
            createdAt: DateTime(2026, 11, 6),
            items: [
              SuggestionItem(
                  title: 'Đi bộ',
                  habitKey: 'move',
                  date: day,
                  hour: 8,
                  minute: 0),
              SuggestionItem(
                  title: 'Đi bộ',
                  habitKey: 'move',
                  date: day,
                  hour: 16,
                  minute: 0),
            ]));
    final c = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'elder'))),
      suggestionServiceProvider.overrideWithValue(service),
      taskRepositoryProvider.overrideWithValue(repository),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    addTearDown(service.dispose);
    final provider = suggestionReviewViewModelProvider(
        (id: 'one', entry: SuggestionEntry.push));
    final keep = c.listen(provider, (_, __) {});
    addTearDown(keep.close);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(provider), isA<UiData>());
    expect(await c.read(provider.notifier).acceptAll(), true);
    final tasks = await repository.tasksForDay(day);
    expect(service.accepts, 1);
    expect(tasks.map((task) => (task.id, task.hour)),
        [('suggestion-one-0', 8), ('suggestion-one-1', 16)]);
  });
}
