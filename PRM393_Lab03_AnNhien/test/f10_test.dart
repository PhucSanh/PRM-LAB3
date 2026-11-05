import 'dart:async';
import 'package:an_nhien/models/app_notification.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/notification_target.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/demo_pdf.dart';
import 'package:an_nhien/services/messaging_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/remote_config_service.dart';
import 'package:an_nhien/services/report_service.dart';
import 'package:an_nhien/screens/firebase_demo/firebase_demo_screen.dart';
import 'package:an_nhien/screens/firebase_demo/inbox_screen.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/firebase_demo_view_model.dart';
import 'package:an_nhien/viewmodels/inbox_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestMessages extends FakeMessagingService {
  final items = StreamController<List<AppNotification>>.broadcast();
  bool allowed = false;
  @override
  Stream<List<AppNotification>> inbox() => items.stream;
  @override
  Future<bool> requestPermission() async => allowed;
}

class RecordingCrash extends FakeCrashService {
  int errors = 0, crashes = 0;
  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {String? reason}) async {
    errors++;
  }

  @override
  void testCrash() {
    crashes++;
  }
}

class BrokenReport implements ReportService {
  @override
  Stream<UploadProgress> exportWeek(DateTime day) =>
      Stream.error(StateError('upload failed'));
}

class CompleteReport implements ReportService {
  @override
  Stream<UploadProgress> exportWeek(DateTime day) => Stream.fromIterable([
        const UploadProgress(.5),
        const UploadProgress(1, downloadUrl: 'https://example.test/demo.pdf'),
      ]);
}

class BrokenConfig extends FakeRemoteConfigService {
  @override
  Future<void> init() async => throw StateError('offline');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'notification target rejects external, traversal and unknown destinations',
      () {
    for (final route in [
      null,
      'https://evil.test',
      '//evil.test',
      '/account',
      '/reminder/../account',
      '/reminder/a?uid=x',
      '/today/suggestions/a/b',
      '/reminder/a\n'
    ]) {
      expect(notificationTarget(route), '/inbox');
    }
    expect(notificationTarget('/reminder/a-1'), '/reminder/a-1');
    expect(
        notificationTarget('/today/suggestions/b_2'), '/today/suggestions/b_2');
  });
  test('inbox loading/empty/data/error/retry and permission denied', () async {
    final messages = TestMessages();
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'u'))),
      messagingServiceProvider.overrideWithValue(messages),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
    ]);
    final sub = container.listen(inboxViewModelProvider, (_, __) {});
    addTearDown(() async {
      sub.close();
      container.dispose();
      await messages.items.close();
    });
    await container.pump();
    expect(container.read(inboxViewModelProvider), isA<UiLoading>());
    messages.items.add([]);
    await container.pump();
    expect(container.read(inboxViewModelProvider), isA<UiEmpty>());
    final item = AppNotification(
        id: 'n',
        title: 'Đi bộ',
        body: '9:30 sáng',
        receivedAt: DateTime(2026),
        route: '/reminder/a');
    messages.items.add([item]);
    await container.pump();
    expect(container.read(inboxViewModelProvider), isA<UiData>());
    expect(await container.read(inboxViewModelProvider.notifier).open(item),
        '/reminder/a');
    expect(await container.read(inboxViewModelProvider.notifier).permission(),
        contains('đang tắt'));
    messages.items.addError(StateError('offline'));
    await container.pump();
    expect(container.read(inboxViewModelProvider), isA<UiError>());
    container.read(inboxViewModelProvider.notifier).retry();
    await container.pump();
    messages.items.add([]);
    await container.pump();
    expect(container.read(inboxViewModelProvider), isA<UiEmpty>());
  });
  for (final failing in [false, true]) {
    test('demo upload failing=$failing records real failures without fake URLs',
        () async {
      final crash = RecordingCrash();
      final container = ProviderContainer(overrides: [
        remoteConfigServiceProvider
            .overrideWithValue(FakeRemoteConfigService()),
        demoReportServiceProvider
            .overrideWithValue(failing ? BrokenReport() : CompleteReport()),
        crashServiceProvider.overrideWithValue(crash),
        analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      ]);
      final sub = container.listen(firebaseDemoViewModelProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });
      await container.pump();
      await Future<void>.delayed(Duration.zero);
      await container.read(firebaseDemoViewModelProvider.notifier).export();
      final data = (container.read(firebaseDemoViewModelProvider)
              as UiData<FirebaseDemoData>)
          .data;
      expect(data.busy, false);
      expect(data.url, failing ? null : 'https://example.test/demo.pdf');
      expect(crash.errors, failing ? 1 : 0);
    });
  }
  test('remote config failure has retry state', () async {
    final container = ProviderContainer(overrides: [
      remoteConfigServiceProvider.overrideWithValue(BrokenConfig()),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
    ]);
    final sub = container.listen(firebaseDemoViewModelProvider, (_, __) {});
    await container.pump();
    await Future<void>.delayed(Duration.zero);
    expect(container.read(firebaseDemoViewModelProvider), isA<UiError>());
    sub.close();
    container.dispose();
  });
  test('demo renderer produces a real PDF with bundled font', () async {
    final bytes = await renderDemoPdf(DateTime(2026));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
  for (final width in [360.0, 412.0]) {
    testWidgets(
        'F10 screens fit $width dp at 200% text; crash requires confirmation',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final crash = RecordingCrash();
      await tester.pumpWidget(ProviderScope(
          overrides: [
            remoteConfigServiceProvider
                .overrideWithValue(FakeRemoteConfigService()),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            crashServiceProvider.overrideWithValue(crash),
          ],
          child: MaterialApp(
              theme: AppTheme.light(), home: const FirebaseDemoScreen())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Thử lỗi ứng dụng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lỗi ứng dụng'));
      await tester.pumpAndSettle();
      expect(crash.crashes, 0);
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(crash.crashes, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(
                FakeAuthService(signedIn: const AppUser(uid: 'u'))),
            messagingServiceProvider.overrideWithValue(FakeMessagingService()),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
          child:
              MaterialApp(theme: AppTheme.light(), home: const InboxScreen())));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Đến giờ đi bộ'), 250,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Đến giờ đi bộ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
