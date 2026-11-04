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

class DelayedAnalytics extends FakeAnalyticsService {
  final pending = Completer<void>();
  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) =>
      pending.future;
}

class RefreshRepository extends FakeTaskRepository {
  RefreshRepository(super.seed);
  bool fail = false;
  Completer<List<TaskItem>>? pending;
  @override
  Future<List<TaskItem>> tasksForDay(DateTime day) async {
    if (fail) throw StateError('offline');
    if (pending != null) return pending!.future;
    return super.tasksForDay(day);
  }
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
  test('postponed remains actionable, skipped does not become next', () {
    const data = TodayData(tasks: [
      TaskItem(
          id: 'skip',
          title: 'Bỏ qua',
          habitKey: 'move',
          hour: 7,
          minute: 0,
          status: TaskStatus.skipped),
      TaskItem(
          id: 'later',
          title: 'Đã dời',
          habitKey: 'move',
          hour: 8,
          minute: 0,
          status: TaskStatus.postponed),
      TaskItem(
          id: 'pending',
          title: 'Tiếp theo',
          habitKey: 'tea',
          hour: 9,
          minute: 0),
    ]);
    expect(data.next?.id, 'later');
    expect(data.remaining.map((task) => task.id), ['later', 'pending']);
    expect(data.skippedCount, 1);
  });

  test('completion returns without waiting for analytics', () async {
    final analytics = DelayedAnalytics();
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository(const [
        TaskItem(id: 'a', title: 'Đi bộ', habitKey: 'move', hour: 8, minute: 0)
      ])),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(() {
      analytics.pending.complete();
      c.dispose();
    });
    await initialLoad(c);
    await c
        .read(todayViewModelProvider.notifier)
        .markDone('a')
        .timeout(const Duration(seconds: 1));
    expect((c.read(todayViewModelProvider) as UiData<TodayData>).data.doneCount,
        1);
  });

  test(
      'refresh keeps cached tasks on error and cannot overwrite a newer completion',
      () async {
    const task =
        TaskItem(id: 'a', title: 'Đi bộ', habitKey: 'move', hour: 8, minute: 0);
    final repository = RefreshRepository([task]);
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(repository),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    await initialLoad(c);
    final vm = c.read(todayViewModelProvider.notifier);
    repository.fail = true;
    await vm.load();
    var data = (c.read(todayViewModelProvider) as UiData<TodayData>).data;
    expect(data.tasks.single.id, 'a');
    expect(data.refreshError, isNotNull);
    repository.fail = false;
    repository.pending = Completer<List<TaskItem>>();
    final refresh = vm.load();
    expect(c.read(todayViewModelProvider), isA<UiData<TodayData>>());
    await vm.markDone('a');
    repository.pending!.complete([task]);
    await refresh;
    data = (c.read(todayViewModelProvider) as UiData<TodayData>).data;
    expect(data.doneCount, 1);
    expect(data.refreshError, isNull);
  });
}
