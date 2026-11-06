import 'dart:async';
import 'package:an_nhien/services/caregiver_schedule_service.dart' as scoped;
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/task_form_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class ScopedTestRepository extends FakeTaskRepository
    implements ScopedTaskRepository {
  ScopedTestRepository(List<TaskItem> tasks)
      : schedules = scoped.FakeCaregiverScheduleService(tasks),
        super(List.of(tasks));
  final scoped.FakeCaregiverScheduleService schedules;
  @override
  Future<scoped.ScheduleUndo> changeOccurrence(TaskItem original, DateTime day,
          TaskItem? replacement, scoped.ChangeScope scope) =>
      schedules.change('owner', original, day, replacement, scope);
  @override
  Future<void> undoOccurrence(scoped.ScheduleUndo change) =>
      schedules.undo(change);
}

class _PendingRepository extends FakeTaskRepository {
  _PendingRepository() : super([]);
  final release = Completer<void>();
  int writes = 0;
  @override
  Future<void> save(TaskItem task) async {
    writes++;
    await release.future;
    await super.save(task);
  }
}

class _OfflineRepository extends FakeTaskRepository {
  _OfflineRepository() : super([]);
  @override
  Future<void> save(TaskItem task) async =>
      throw StateError('network unavailable');
}

void main() {
  late FakeTaskRepository repository;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    repository = FakeTaskRepository([]);
    analytics = FakeAnalyticsService();
    container = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(repository),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
  });
  tearDown(() => container.dispose());

  test('creation preserves future calendar date and chosen activity', () async {
    final day = DateTime.now().add(const Duration(days: 12));
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate(day: day, activity: 'downshift', title: 'Thư giãn');
    final state = container.read(taskFormViewModelProvider);
    expect(dateKey(state.date!), dateKey(day));
    expect(state.hour, 8);
    expect(state.activity, 'downshift');
    expect(await vm.save(), isTrue);
    final saved = await repository.tasksForDay(day);
    expect(saved.single.title, 'Thư giãn');
    expect(saved.single.startDate, dateKey(day));
  });

  test('past calendar context defaults to the next available time', () {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate(day: DateTime(2020));
    final state = container.read(taskFormViewModelProvider);
    expect(
        state.date!.isBefore(DateTime.now().subtract(const Duration(days: 1))),
        isFalse);
    expect(state.isTimeInPastToday, isFalse);
  });

  test('past time does not incorrectly mark a valid title as missing',
      () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    vm.setDate(DateTime.now());
    vm.setTime(hour: 0, minute: 0, isAm: true);
    expect(await vm.save(), isFalse);
    expect(container.read(taskFormViewModelProvider).titleError, isNull);
    vm.setTitle('x' * 81);
    expect(await vm.save(), isFalse);
    expect(
        container.read(taskFormViewModelProvider).titleError, contains('80'));
    expect(await repository.tasksForDay(DateTime.now()), isEmpty);
  });

  test('rapid duplicate save submits only one repository write', () async {
    final pending = _PendingRepository();
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(pending),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    final vm = c.read(taskFormViewModelProvider.notifier)..startCreate();
    final first = vm.save();
    expect(await vm.save(), isFalse);
    expect(pending.writes, 1);
    pending.release.complete();
    expect(await first, isTrue);
  });

  test('failed save preserves draft and does not claim it was saved offline',
      () async {
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(_OfflineRepository()),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    final vm = c.read(taskFormViewModelProvider.notifier)..startCreate();
    vm.setTitle('Gọi cháu vào buổi chiều');
    expect(await vm.save(), isFalse);
    expect(c.read(taskFormViewModelProvider).errorMessage,
        startsWith('Chưa lưu được'));
    vm.restoreEditing();
    expect(c.read(taskFormViewModelProvider).title, 'Gọi cháu vào buổi chiều');
  });

  test('F4: tên trống hiển thị validation và không lưu', () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    vm.setTitle('');

    expect(await vm.save(), isFalse);
    expect(container.read(taskFormViewModelProvider).showValidation, isTrue);
    expect(await repository.tasksForDay(DateTime.now()), isEmpty);
  });

  test('F4: chọn hoạt động điền sẵn tên và giờ tròn kế tiếp', () {
    final before = DateTime.now();
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    var state = container.read(taskFormViewModelProvider);
    expect(state.title, 'Đi bộ nhẹ nhàng');
    expect(state.minute, 0);
    expect(state.hour, (before.hour + 1) % 24);

    vm.selectActivity('tea', suggestedTitle: 'Uống trà với bạn');
    state = container.read(taskFormViewModelProvider);
    expect(state.activity, 'tea');
    expect(state.title, 'Uống trà với bạn');
  });

  test('F4: không lưu giờ đã qua khi ngày làm là hôm nay', () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    final past = DateTime.now().subtract(const Duration(minutes: 1));
    vm.setDate(DateTime.now());
    vm.setTime(hour: past.hour, minute: past.minute, isAm: past.hour < 12);

    expect(container.read(taskFormViewModelProvider).isTimeInPastToday, isTrue);
    expect(await vm.save(), isFalse);
    expect(container.read(taskFormViewModelProvider).showValidation, isTrue);
  });

  test('F4: tạo việc lưu repository và ghi analytics add_task', () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    vm.selectActivity('move');
    vm.setTitle('Đi bộ buổi sáng');

    expect(await vm.save(), isTrue);
    final saved = await repository
        .tasksForDay(container.read(taskFormViewModelProvider).date!);
    expect(saved.single.title, 'Đi bộ buổi sáng');
    expect(saved.single.repeat, RepeatRule.daily);
    expect(analytics.logged, contains('add_task'));
  });

  test('F4: sửa rồi xóa task lặp có analytics edit/delete', () async {
    await repository.save(const TaskItem(
        id: 'repeat', title: 'Đi bộ', habitKey: 'move', hour: 9, minute: 30));
    final vm = container.read(taskFormViewModelProvider.notifier);
    expect(await vm.startEdit('repeat'), isTrue);
    vm.setTitle('Đi bộ quanh công viên');
    vm.setDate(DateTime.now().add(const Duration(days: 1)));
    expect(await vm.save(scope: ChangeScope.thisAndFollowing), isTrue);
    expect((await repository.tasksForDay(DateTime.now())).single.title,
        'Đi bộ quanh công viên');
    expect(await vm.delete(ChangeScope.once), isTrue);
    expect(await repository.tasksForDay(DateTime.now()), isEmpty);
    expect(analytics.logged, containsAll(['edit_task', 'delete_task']));
  });
  test(
      'future occurrence edit preserves other dates and Undo restores the series',
      () async {
    const original = TaskItem(
        id: 'series',
        title: 'Đi bộ',
        habitKey: 'move',
        hour: 8,
        minute: 0,
        startDate: '2026-11-01');
    final scopedRepo = ScopedTestRepository([original]);
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(scopedRepo),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    final vm = c.read(taskFormViewModelProvider.notifier);
    final day = DateTime(2099, 11, 7);
    expect(await vm.startEdit('series', day: day), true);
    vm.setTitle('Đi bộ cùng con');
    expect(await vm.save(scope: ChangeScope.once), true);
    final tasks = scopedRepo.schedules.tasks.values.toList();
    expect(tasks.where((t) => t.occursOn(day)).single.title, 'Đi bộ cùng con');
    expect(
        tasks
            .where((t) => t.occursOn(day.add(const Duration(days: 1))))
            .single
            .title,
        'Đi bộ');
    await vm.undoLastMutation();
    expect(scopedRepo.schedules.tasks.values.single.title, 'Đi bộ');
    expect(scopedRepo.schedules.tasks.values.single.excludedDates, isEmpty);
  });

  test(
      'create saves chosen date and weekly days instead of defaulting to today',
      () async {
    final vm = container.read(taskFormViewModelProvider.notifier);
    vm.startCreate();
    vm.setDate(DateTime(2099, 11, 9));
    vm.setRepeat(RepeatRule.someDays);
    vm.setWeekdays({DateTime.monday, DateTime.friday});
    expect(await vm.save(), true);
    final task = container.read(taskFormViewModelProvider).original!;
    expect(task.startDate, '2099-11-09');
    expect(task.weekdays.toSet(), {DateTime.monday, DateTime.friday});
    expect(task.occursOn(DateTime(2099, 11, 8)), false);
  });
  test('one-off can become a daily series and Undo restores one-off', () async {
    const task = TaskItem(
        id: 'once',
        title: 'Đi bộ',
        habitKey: 'move',
        hour: 8,
        minute: 0,
        repeat: RepeatRule.once,
        startDate: '2099-11-07',
        endDate: '2099-11-07');
    final repository = ScopedTestRepository([task]);
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(repository),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    final vm = c.read(taskFormViewModelProvider.notifier);
    await vm.startEdit('once', day: DateTime(2099, 11, 7));
    vm.setRepeat(RepeatRule.daily);
    expect(await vm.save(scope: ChangeScope.thisAndFollowing), true);
    expect(repository.schedules.tasks['once']!.occursOn(DateTime(2099, 11, 8)),
        true);
    await vm.undoLastMutation();
    expect(repository.schedules.tasks['once']!.repeat, RepeatRule.once);
  });
}
