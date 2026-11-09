import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:an_nhien/models/app_notification.dart';
import 'package:an_nhien/services/local_reminder_service.dart';

class NotificationSpy implements FlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final calls = <Map<String, dynamic>>[];
  @override
  Future<void> show(
      {required int id,
      String? title,
      String? body,
      NotificationDetails? notificationDetails,
      String? payload}) async {
    calls.add({
      'id': id,
      'title': title,
      'details': notificationDetails,
      'payload': jsonDecode(payload!)
    });
  }
}

class ReadyReminders extends LocalReminderService {
  ReadyReminders(super.uid, NotificationSpy plugin) : super(plugin: plugin);
  @override
  Future<void> init() async {}
}

void main() {
  test(
      'foreground push alerts with sound and routes taps to its signed-in recipient',
      () async {
    final plugin = NotificationSpy();
    String? uid = 'parent';
    final service = ReadyReminders(() => uid, plugin);
    final item = AppNotification(
        id: 'campaign-1',
        title: 'Vận động',
        body: 'Đi bộ nhé',
        receivedAt: DateTime(2026),
        route: '/inbox',
        parentUid: 'parent');
    await service.showForegroundPush(item, 'parent');
    expect(plugin.calls, hasLength(1));
    final details =
        (plugin.calls.single['details'] as NotificationDetails).android!;
    expect(details.playSound, true);
    expect(details.importance, Importance.high);
    expect(details.channelId, 'an_nhien_updates');
    expect(plugin.calls.single['payload'], containsPair('uid', 'parent'));
    expect(plugin.calls.single['payload'], containsPair('parentUid', 'parent'));
    expect(plugin.calls.single['payload'], containsPair('route', '/inbox'));
    uid = 'other';
    await service.showForegroundPush(item, 'parent');
    expect(plugin.calls, hasLength(1));
    await service.dispose();
  });
}
