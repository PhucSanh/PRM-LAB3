import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'package:an_nhien/services/pairing_service.dart';
import 'package:an_nhien/services/caregiver_suggestion_service.dart';

TaskItem task(
        {RepeatRule repeat = RepeatRule.weekly,
        List<int> weekdays = const [1, 3, 5],
        List<int> monthDays = const [],
        bool last = false}) =>
    TaskItem(
        id: 'walk',
        title: 'Đi bộ',
        habitKey: 'move',
        hour: 8,
        minute: 0,
        startDate: '2026-11-02',
        repeat: repeat,
        weekdays: weekdays,
        monthDays: monthDays,
        lastDayOfMonth: last);
void main() {
  test('weekly calendar bounds and excluded dates, old someDays supported', () {
    final t = task();
    expect(t.occursOn(DateTime(2026, 11, 2)), true);
    expect(t.occursOn(DateTime(2026, 11, 3)), false);
    expect(t.occursOn(DateTime(2026, 10, 30)), false);
    expect(t.copyWith(endDate: '2026-11-04').occursOn(DateTime(2026, 11, 6)),
        false);
    expect(
        t.copyWith(
            excludedDates: ['2026-11-04']).occursOn(DateTime(2026, 11, 4)),
        false);
    expect(task(repeat: RepeatRule.someDays).occursOn(DateTime(2026, 11, 4)),
        true);
  });
  test('conflicts include future recurrence, exceptions and midnight overlap',
      () {
    final a = task(repeat: RepeatRule.monthly, monthDays: [31])
        .copyWith(startDate: '2026-11-02', endDate: '2030-12-31');
    final b = task().copyWith(startDate: '2028-01-01');
    expect(schedulesConflict(a, b), true);
    expect(schedulesConflict(a, b.copyWith(hour: 10)), false);
    expect(schedulesConflict(a, b.copyWith(endDate: '2027-01-01')), false);
    final night = task(repeat: RepeatRule.once).copyWith(
        startDate: '2026-11-02', hour: 23, minute: 50, durationMinutes: 30);
    final morning = task(repeat: RepeatRule.once)
        .copyWith(startDate: '2026-11-03', hour: 0, minute: 10);
    expect(schedulesConflict(night, morning), true);
    expect(schedulesConflict(night, morning.copyWith(minute: 30)), false);
  });
  test(
      'completion inheritance follows multiple scope splits and explicit undo wins',
      () {
    final a = task(),
        b = task().copyWith(id: 'b', completionSourceId: 'walk'),
        c = task().copyWith(id: 'c', completionSourceId: 'b');
    final templates = {'walk': a, 'b': b, 'c': c};
    expect(resolveOccurrenceStatus(c, templates, {'walk': TaskStatus.done}),
        TaskStatus.done);
    expect(
        resolveOccurrenceStatus(
            c, templates, {'walk': TaskStatus.done, 'b': TaskStatus.skipped}),
        TaskStatus.skipped);
    expect(
        resolveOccurrenceStatus(
            c, templates, {'walk': TaskStatus.done, 'c': TaskStatus.pending}),
        TaskStatus.pending);
    expect(
        resolveOccurrenceStatus(
            c, {'c': c, 'b': b.copyWith(completionSourceId: 'c')}, {}),
        TaskStatus.pending);
  });
  test('monthly missing dates are skipped, leap day and last day supported',
      () {
    final t = task(repeat: RepeatRule.monthly, monthDays: [31]);
    expect(t.occursOn(DateTime(2027, 1, 31)), true);
    expect(t.occursOn(DateTime(2027, 2, 28)), false);
    final last = task(repeat: RepeatRule.monthly, last: true);
    expect(last.occursOn(DateTime(2028, 2, 29)), true);
    expect(last.occursOn(DateTime(2028, 2, 28)), false);
  });
  test(
      'roundtrip retains recurrence but never stores daily completion on series',
      () {
    final t = task().copyWith(status: TaskStatus.done);
    final decoded = TaskItem.fromMap('walk', t.toMap());
    expect(decoded.repeat, RepeatRule.weekly);
    expect(decoded.weekdays, [1, 3, 5]);
    expect(decoded.status, TaskStatus.pending);
    final assigned = task().copyWith(creatorUid: 'caregiver_1');
    expect(TaskItem.fromMap('walk', assigned.toMap()).creatorUid,
        'caregiver_1');
    expect(
        task()
            .copyWith(repeat: RepeatRule.once, startDate: '2026-11-02')
            .occursOn(DateTime(2026, 11, 4)),
        false);
    expect(
        () => task().copyWith(weekdays: []).validate(), throwsFormatException);
    expect(() => task().copyWith(startDate: '2026-02-31').validate(),
        throwsFormatException);
  });
  for (final scope in ChangeScope.values) {
    test('scope $scope preserves series and supports undo', () async {
      final original = task();
      final service = FakeCaregiverScheduleService([original]);
      addTearDown(service.dispose);
      final change = await service.change('mom', original,
          DateTime(2026, 11, 4), original.copyWith(hour: 7), scope);
      final monday = await service
          .watch('mom', DateTime(2026, 11, 2), DateTime(2026, 11, 2))
          .first;
      final wed = await service
          .watch('mom', DateTime(2026, 11, 4), DateTime(2026, 11, 4))
          .first;
      final fri = await service
          .watch('mom', DateTime(2026, 11, 6), DateTime(2026, 11, 6))
          .first;
      expect(monday.single.task.hour, scope == ChangeScope.all ? 7 : 8);
      expect(wed.single.task.hour, 7);
      if (scope != ChangeScope.all) {
        expect(wed.single.task.completionSourceId, 'walk');
      }
      expect(fri.single.task.hour, scope == ChangeScope.occurrence ? 8 : 7);
      await service.undo(change);
      expect(service.tasks.length, 1);
      expect(service.tasks['walk']!.hour, 8);
      await expectLater(service.undo(change), throwsA(isA<Exception>()));
    });
  }
  test(
      'stop from first occurrence retains history; concurrent modification blocks undo',
      () async {
    final original = task();
    final service = FakeCaregiverScheduleService([original]);
    addTearDown(service.dispose);
    final change = await service.change(
        'mom', original, DateTime(2026, 11, 2), null, ChangeScope.future);
    expect(
        (await service
            .watch('mom', DateTime(2026, 11, 2), DateTime(2026, 12, 31))
            .first),
        isEmpty);
    await service.undo(change);
    final current = service.tasks['walk']!;
    final edit = await service.change('mom', current, DateTime(2026, 11, 2),
        current.copyWith(hour: 7), ChangeScope.all);
    await service.change('mom', service.tasks['walk']!, DateTime(2026, 11, 2),
        current.copyWith(hour: 6), ChangeScope.all);
    await expectLater(service.undo(edit), throwsA(isA<Exception>()));
    await expectLater(
        service.change(
            'mom', original, DateTime(2026, 11, 2), original, ChangeScope.all),
        throwsA(isA<Exception>()));
  });
  test('pairing rejects wrong, expired and reused code', () async {
    var now = DateTime(2026, 11, 4);
    final service = FakePairingService(now: () => now);
    await service.createCode();
    await expectLater(service.redeem('000000'), throwsA(isA<Exception>()));
    now = now.add(const Duration(minutes: 10));
    await expectLater(service.redeem('123456'), throwsA(isA<Exception>()));
    await service.createCode();
    expect(await service.redeem('123456'), 'demo-mom');
    await expectLater(service.redeem('123456'), throwsA(isA<Exception>()));
  });
  test(
      'suggestion partial accept has stable ids; repeat submit cannot duplicate; dismiss undo',
      () async {
    final service = FakeSuggestionService();
    addTearDown(service.dispose);
    await service.send('mom', 'request', [task(), task().copyWith(id: 'b')]);
    await service.send('mom', 'request', [task(), task().copyWith(id: 'b')]);
    expect(service.suggestions.length, 1);
    await service.resolve('request', [1], times: {1: (hour: 10, minute: 30)});
    expect(service.acceptedTasks.single.id, 'suggestion-request-1');
    expect(service.acceptedTasks.single.hour, 10);
    await expectLater(
        service.resolve('request', [1]), throwsA(isA<Exception>()));
    expect(service.acceptedTasks.length, 1);
    await service.send('mom', 'dismiss', [task()]);
    await service.resolve('dismiss', []);
    await service.undoDismiss('dismiss');
    expect(service.suggestions['dismiss']!.status, 'pending');
  });
}
