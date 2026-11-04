import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'package:an_nhien/services/local_reminder_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'Android notification plugin: show, schedule, snooze, cancel and sign-out cleanup',
      (tester) async {
    var uid = 'local-notification-test';
    final service = LocalReminderService(() => uid);
    await service.init();
    // For unattended test only: adb shell pm grant <package> android.permission.POST_NOTIFICATIONS
    for (var i = 0; i < 60 && !await service.hasPermission(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    expect(await service.hasPermission(), true,
        reason:
            'Grant notification permission to this test app before running.');
    await service.showTest();
    expect(
        (await service.sdk.getActiveNotifications())
            .any((n) => n.id == 0x70000000),
        true);
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final time = now.add(const Duration(hours: 2));
    final task = TaskItem(
        id: 'native-reminder',
        title: 'Lời nhắc local',
        habitKey: 'move',
        hour: time.hour,
        minute: time.minute,
        startDate: dateKey(now));
    final day = calendarDate(time);
    await service.sync([
      ScheduleOccurrence(task, day),
      ScheduleOccurrence(task, day.add(const Duration(days: 1)))
    ]);
    expect((await service.sdk.pendingNotificationRequests()).length, 2);
    await service.snooze(task.id, 10);
    expect((await service.sdk.pendingNotificationRequests()).length,
        dateKey(day) == dateKey(now) ? 2 : 3);
    await service.cancel(task.id);
    expect((await service.sdk.pendingNotificationRequests()), isEmpty);
    await service.schedule(task);
    expect((await service.sdk.pendingNotificationRequests()), isNotEmpty);
    await service.clearAll();
    uid = 'other-user';
    expect((await service.sdk.pendingNotificationRequests()), isEmpty);
    expect((await service.sdk.getActiveNotifications()), isEmpty);
    await service.dispose();
  });
}
