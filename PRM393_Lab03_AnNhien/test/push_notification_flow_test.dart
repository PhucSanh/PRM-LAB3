import 'dart:async';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/app_notification.dart';
import 'package:an_nhien/models/notification_target.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/screens/firebase_demo/inbox_screen.dart';
import 'package:an_nhien/services/messaging_service.dart';
import 'package:an_nhien/services/caregiver_suggestion_service.dart' as family;
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/caregiver_schedule_view_model.dart';
import 'package:an_nhien/viewmodels/inbox_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/demo_container.dart';

class LiveMessages extends FakeMessagingService {
  LiveMessages() : super(seed: []);
  final received = StreamController<AppNotification>.broadcast();
  @override
  Stream<AppNotification> get onReceived => received.stream;
  @override
  Future<void> dispose() async {
    await received.close();
    await super.dispose();
  }
}

class FailedRead extends FakeMessagingService {
  FailedRead({required super.seed});
  @override
  Future<void> markRead(String id) async => throw StateError('offline');
}

AppNotification item(String id, NotificationKind kind,
        {String route = '/inbox'}) =>
    AppNotification(
        id: id,
        title: 'Tin $id',
        body: 'Nội dung $id',
        receivedAt: DateTime(2026, 11, 5, 8),
        kind: kind,
        route: route);

void main() {
  test(
      'push routes accept known destinations and reject invalid dates and extra query',
      () {
    expect(firebaseNotificationTarget('/today/suggestions/legacy'),
        '/inbox/suggestions/legacy');
    for (final route in [
      '/today',
      '/inbox/suggestions/real-1',
      '/caregiver/schedule?date=2026-11-05'
    ]) {
      expect(notificationTarget(route), route);
    }
    for (final route in [
      '/caregiver/schedule?date=2026-02-31',
      '/caregiver/schedule?date=2026-11-05&uid=other',
      'https://bad.test/inbox',
      '/inbox/suggestions/../account'
    ]) {
      expect(notificationTarget(route), '/inbox');
    }
  });

  test('old parent notification does not open the newly paired parent schedule',
      () async {
    final c = demoContainer();
    await c.pump();
    final vm = c.read(inboxViewModelProvider.notifier);
    final old = AppNotification(
        id: 'old',
        title: 'Hoàn thành',
        body: '',
        receivedAt: DateTime(2026),
        route: '/caregiver/schedule?date=2026-11-03',
        kind: NotificationKind.family,
        parentUid: 'old-mom');
    expect(await vm.open(old), '/inbox');
    final current = AppNotification(
        id: 'current',
        title: 'Hoàn thành',
        body: '',
        receivedAt: DateTime(2026),
        route: '/caregiver/schedule?date=2026-11-03',
        kind: NotificationKind.family,
        parentUid: 'demo-mom');
    expect(await vm.open(current), '/caregiver/schedule?date=2026-11-03');
    await c.pump();
    c.dispose();
  });

  testWidgets('family/system filters and read-state are persisted by service',
      (tester) async {
    final messages = FakeMessagingService(seed: [
      item('family', NotificationKind.family),
      item('system', NotificationKind.system)
    ]);
    final c = demoContainer(messages: messages);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child:
            MaterialApp(theme: AppTheme.light(), home: const InboxScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Gia đình'));
    await tester.pumpAndSettle();
    expect(find.text('Tin family'), findsOneWidget);
    expect(find.text('Tin system'), findsNothing);
    final read = find.text('Đánh dấu đã đọc');
    await tester.ensureVisible(read);
    await tester.pumpAndSettle();
    await tester.tap(read);
    await tester.pumpAndSettle();
    expect((await tester.runAsync(() => messages.inbox().first))!.first.isRead,
        isTrue);
    expect(find.text('• Chưa đọc'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
    await messages.dispose();
  });

  testWidgets('read failure is visible and does not claim success',
      (tester) async {
    final messages =
        FailedRead(seed: [item('system', NotificationKind.system)]);
    final c = demoContainer(messages: messages);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child:
            MaterialApp(theme: AppTheme.light(), home: const InboxScreen())));
    await tester.pumpAndSettle();
    final read = find.text('Đánh dấu đã đọc');
    await tester.ensureVisible(read);
    await tester.pumpAndSettle();
    await tester.tap(read);
    await tester.pumpAndSettle();
    expect(find.text('Chưa đánh dấu được. Bạn thử lại nhé.'), findsOneWidget);
    expect((await tester.runAsync(() => messages.inbox().first))!.first.isRead,
        isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
    await messages.dispose();
  });

  testWidgets(
      'real suggestion push opens matching backend flow, not F12 sample',
      (tester) async {
    final suggestions = family.FakeSuggestionService();
    await suggestions.send('demo-mom', 'real', [
      TaskItem(
          id: 'walk',
          title: 'Lịch thật từ con',
          habitKey: 'move',
          hour: 8,
          minute: 0,
          startDate: dateKey(vietnamToday()))
    ]);
    await suggestions.send('demo-mom', 'other', [
      TaskItem(
          id: 'tea',
          title: 'Gợi ý khác',
          habitKey: 'tea',
          hour: 15,
          minute: 0,
          startDate: dateKey(vietnamToday()))
    ]);
    final c = demoContainer(suggestions: suggestions);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/inbox/suggestions/real');
    await tester.pumpAndSettle();
    expect(find.text('Lịch thật từ con'), findsOneWidget);
    expect(find.text('Gợi ý khác'), findsNothing);
    final accept = find.text('Thêm việc đã chọn vào lịch');
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(suggestions.acceptedTasks.single.title, 'Lịch thật từ con');
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
    await suggestions.dispose();
  });

  testWidgets(
      'foreground redelivery does not queue another banner; dated push selects correct day',
      (tester) async {
    final messages = LiveMessages();
    final c = demoContainer(messages: messages);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    final notification = item('one', NotificationKind.family);
    messages.received.add(notification);
    await tester.pumpAndSettle();
    expect(find.text('Có thông báo mới từ gia đình.'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    messages.received.add(notification);
    await tester.pumpAndSettle();
    expect(find.text('Có thông báo mới từ gia đình.'), findsNothing);
    c
        .read(caregiverScheduleViewModelProvider.notifier)
        .selectView(CalendarView.month);
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/caregiver/schedule?date=2026-11-03');
    await tester.pumpAndSettle();
    expect(
        c.read(caregiverScheduleViewModelProvider).date, DateTime(2026, 11, 3));
    expect(c.read(caregiverScheduleViewModelProvider).view, CalendarView.day);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
    await messages.dispose();
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('inbox 360px scale $scale handles long text without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final messages = FakeMessagingService(seed: [
        item('một thông báo dài cần hiển thị rõ ràng', NotificationKind.family)
      ]);
      final c = demoContainer(messages: messages);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: const InboxScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await messages.dispose();
    });
  }
}
