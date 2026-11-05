import 'dart:async';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/today_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mẫu test ViewModel bằng service giả (đề Lab 3 › mục 5: "services are injected").
Future<void> initialLoad(ProviderContainer c) async {
  final ready = Completer<void>();
  final sub = c.listen(todayViewModelProvider, (_, next) {
    if (next is! UiLoading<TodayData> && !ready.isCompleted) ready.complete();
  }, fireImmediately: true);
  try {
    await ready.future.timeout(const Duration(seconds: 5));
  } finally {
    sub.close();
  }
}

class _ThrowingTaskRepository implements TaskRepository {
  @override
  Future<void> delete(String taskId) async {}

  @override
  Future<void> save(TaskItem task) async {}

  @override
  Future<void> setStatus(String taskId, TaskStatus status) async {}

  @override
  Future<TaskRescheduleChange> reschedule(TaskItem task,
          {required DateTime targetDay,
          required int hour,
          required int minute}) async =>
      throw StateError('network unavailable');

  @override
  Future<void> restoreReschedule(TaskRescheduleChange change) async {}

  @override
  Future<List<TaskItem>> tasksForDay(DateTime day) =>
      Future<List<TaskItem>>.error(StateError('network unavailable'));
}

void main() {
  ProviderContainer containerWith(List<TaskItem> tasks) {
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository(tasks)),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('không có việc → UiEmpty', () async {
    final c = containerWith([]);
    await initialLoad(c);
    expect(c.read(todayViewModelProvider), isA<UiEmpty<TodayData>>());
  });

  test('đếm việc đã xong và đánh dấu xong', () async {
    final c = containerWith(const [
      TaskItem(id: 'a', title: 'Đi bộ', habitKey: 'move', hour: 9, minute: 0),
      TaskItem(
          id: 'b',
          title: 'Uống trà',
          habitKey: 'tea',
          hour: 15,
          minute: 0,
          status: TaskStatus.done),
    ]);
    final vm = c.read(todayViewModelProvider.notifier);
    await initialLoad(c);
    var data = (c.read(todayViewModelProvider) as UiData<TodayData>).data;
    expect(data.doneCount, 1);
    expect(data.next?.id, 'a');

    await vm.markDone('a');
    data = (c.read(todayViewModelProvider) as UiData<TodayData>).data;
    expect(data.doneCount, 2);
  });

  test('dời, bỏ qua và hoàn tác giữ cùng nguồn task', () async {
    final now = DateTime.now();
    final c = containerWith([
      TaskItem(
          id: 'a',
          title: 'Đi bộ',
          habitKey: 'move',
          hour: 9,
          minute: 0,
          repeat: RepeatRule.once,
          startDate: dateKey(now)),
    ]);
    final vm = c.read(todayViewModelProvider.notifier);
    await initialLoad(c);

    final expected = DateTime.now().add(const Duration(minutes: 30));
    expect(await vm.postpone('a', PostponeOption.thirtyMinutes), isTrue);
    var task =
        (await c.read(taskRepositoryProvider).tasksForDay(expected)).single;
    expect(task.status, TaskStatus.pending);
    expect(task.hour, expected.hour);
    expect(task.minute, expected.minute);

    expect(await vm.undoLastAction(), isTrue);
    task = (await c.read(taskRepositoryProvider).tasksForDay(DateTime.now()))
        .single;
    expect(task.status, TaskStatus.pending);
    expect(task.minute, 0);

    final oneHourLater = DateTime.now().add(const Duration(hours: 1));
    expect(await vm.postpone('a', PostponeOption.oneHour), isTrue);
    task =
        (await c.read(taskRepositoryProvider).tasksForDay(oneHourLater)).single;
    expect(task.hour, oneHourLater.hour);
    expect(task.minute, oneHourLater.minute);
    expect(await vm.undoLastAction(), isTrue);

    expect(await vm.skip('a'), isTrue);
    task =
        (c.read(todayViewModelProvider) as UiData<TodayData>).data.tasks.single;
    expect(task.status, TaskStatus.skipped);
  });

  test(
      'dời sang ngày mai vẫn là việc chưa hoàn thành và undo khôi phục hôm nay',
      () async {
    final now = DateTime.now();
    final c = containerWith([
      TaskItem(
          id: 'a',
          title: 'Đi bộ',
          habitKey: 'move',
          hour: 9,
          minute: 0,
          repeat: RepeatRule.once,
          startDate: dateKey(now)),
    ]);
    final vm = c.read(todayViewModelProvider.notifier);
    await initialLoad(c);

    expect(await vm.postpone('a', PostponeOption.tomorrow), isTrue);
    expect(c.read(todayViewModelProvider), isA<UiEmpty<TodayData>>());
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final moved = await c.read(taskRepositoryProvider).tasksForDay(tomorrow);
    expect(moved, hasLength(1));
    expect(moved.single.status, TaskStatus.pending);
    expect(moved.single.hour, 9);

    expect(await vm.undoLastAction(), isTrue);
    final today = c.read(todayViewModelProvider) as UiData<TodayData>;
    expect(today.data.tasks.single.hour, 9);
    expect(await c.read(taskRepositoryProvider).tasksForDay(tomorrow), isEmpty);
  });

  test('lỗi tải lịch → UiError và được ghi nhận', () async {
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(_ThrowingTaskRepository()),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    await initialLoad(c);

    expect(c.read(todayViewModelProvider), isA<UiError<TodayData>>());
  });
}
