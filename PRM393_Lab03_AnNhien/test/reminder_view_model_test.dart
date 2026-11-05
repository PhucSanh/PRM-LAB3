import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/remote_config_service.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/reminder_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const task = TaskItem(
      id: 'reminder-task',
      title: 'Đi bộ quanh công viên',
      habitKey: 'move',
      hour: 9,
      minute: 30);

  ProviderContainer container({int snoozeMinutes = 10}) {
    return ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository([task])),
      reminderServiceProvider.overrideWithValue(FakeReminderService()),
      remoteConfigServiceProvider.overrideWithValue(
          FakeRemoteConfigService({RemoteConfigKeys.snoozeMinutes: snoozeMinutes})),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
    ]);
  }

  test('S14 đọc snooze_minutes từ Remote Config', () async {
    final c = container(snoozeMinutes: 15);
    addTearDown(c.dispose);
    final vm = c.read(reminderViewModelProvider.notifier);
    await vm.load(task.id);
    final state = c.read(reminderViewModelProvider);
    expect(state, isA<UiData<ReminderData>>());
    expect((state as UiData<ReminderData>).data.snoozeMinutes, 15);
  });

  test('S14 nhắc lại ghi ReminderService và event', () async {
    final reminder = FakeReminderService(alreadyGranted: true);
    final analytics = FakeAnalyticsService();
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository([task])),
      reminderServiceProvider.overrideWithValue(reminder),
      remoteConfigServiceProvider.overrideWithValue(FakeRemoteConfigService()),
      analyticsServiceProvider.overrideWithValue(analytics),
    ]);
    addTearDown(c.dispose);
    final vm = c.read(reminderViewModelProvider.notifier);
    await vm.load(task.id);
    expect(await vm.snooze(), isTrue);
    expect(reminder.snoozed[task.id], 10);
    expect(analytics.logged, contains('reminder_action'));
  });

  test('S14 preview không ghi dữ liệu hay analytics', () async {
    final reminder = FakeReminderService();
    final analytics = FakeAnalyticsService();
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository([task])),
      reminderServiceProvider.overrideWithValue(reminder),
      remoteConfigServiceProvider.overrideWithValue(FakeRemoteConfigService()),
      analyticsServiceProvider.overrideWithValue(analytics),
    ]);
    addTearDown(c.dispose);
    final vm = c.read(reminderViewModelProvider.notifier);
    await vm.load('preview', preview: true);
    expect(await vm.snooze(), isTrue);
    expect(await vm.skip(), isTrue);
    expect(reminder.snoozed, isEmpty);
    expect(analytics.logged, isEmpty);
  });
}
