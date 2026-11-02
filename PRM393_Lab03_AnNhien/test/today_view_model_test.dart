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
}
