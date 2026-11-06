import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/app_settings.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/local_reminder_service.dart';
import 'package:an_nhien/services/reminder_runtime.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/models/notification_target.dart';
import 'support/demo_container.dart';
import 'device_access_flow_test.dart' show TestDevice;

class TestUser implements User {
  @override
  String get uid => 'u';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuth implements FirebaseAuth {
  @override
  User? get currentUser => TestUser();
  @override
  Stream<User?> authStateChanges() => Stream.value(currentUser);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ReminderSpy extends LocalReminderService {
  ReminderSpy() : super(() => 'u');
  final observed = <bool>[];
  @override
  Future<void> init() async {}
  @override
  Future<void> clearAll({bool preservePending = false}) async {}
  @override
  Future<void> sync(List<ScheduleOccurrence> occurrences) async {
    observed.add(vibrate);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'notification vibration follows preference using independent Android channel IDs',
      () {
    final on = reminderNotificationDetails(true).android!;
    final off = reminderNotificationDetails(false).android!;
    expect(on.enableVibration, true);
    expect(off.enableVibration, false);
    expect(on.channelId, isNot(off.channelId));
  });
  test(
      'changing vibration preference updates runtime and reschedules pending reminders',
      () async {
    final settings = FakeSettingsService(delay: Duration.zero);
    final schedules = FakeCaregiverScheduleService();
    final reminders = ReminderSpy();
    final runtime = ReminderRuntime(
        TestAuth(), schedules, reminders, FakeCrashService(),
        settings: settings);
    addTearDown(settings.dispose);
    addTearDown(schedules.dispose);
    addTearDown(runtime.dispose);
    await runtime.init();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await settings.setVibrate(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(reminders.vibrate, false);
    expect(reminders.observed, contains(false));
    await settings.setVibrate(true);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(reminders.vibrate, true);
    expect(reminders.observed.last, true);
  });
  test('dated reminder is allowed only for a valid local date', () {
    expect(notificationTarget('/reminder/task?date=2099-11-07'),
        '/reminder/task?date=2099-11-07');
    expect(notificationTarget('/reminder/task?date=2099-02-31'), '/inbox');
    expect(
        notificationTarget(
            '/reminder/task?date=2099-11-07&next=https://bad.example'),
        '/inbox');
  });
  for (final automatic in [false, true]) {
    testWidgets(
        'opening reminder ${automatic ? 'automatically reads' : 'waits for manual read'} according to saved preference',
        (tester) async {
      final device = TestDevice();
      final settings = FakeSettingsService(
          initial: AppSettings(readAloud: automatic), delay: Duration.zero);
      final c = demoContainer(
          initialRoute: '/reminder/task?date=2099-11-07',
          device: device,
          settings: settings,
          tasks: const [
            TaskItem(
                id: 'task',
                title: 'Tưới rau',
                habitKey: 'plant',
                hour: 8,
                minute: 15),
          ]);
      addTearDown(c.dispose);
      await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const AnNhienApp()));
      await tester.pumpAndSettle();
      if (automatic) {
        expect(device.spoken, contains('Tưới rau'));
      } else {
        expect(device.spoken, isNull);
        await tester.ensureVisible(find.text('Đọc to'));
        await tester.tap(find.text('Đọc to'));
        await tester.pumpAndSettle();
        expect(device.spoken, contains('Tưới rau'));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    });
  }
}
