import 'package:an_nhien/screens/onboarding/notifications_screen.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F2 bước 04: S13 Cho phép nhắc việc + S13d Nhắc việc đang tắt.
void main() {
  late FakeReminderService reminder;

  Future<void> pumpS13(WidgetTester tester,
      {bool permissionGranted = true,
      bool alreadyGranted = false,
      double width = 360,
      double textScale = 1.0}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    reminder = FakeReminderService(
        permissionGranted: permissionGranted,
        alreadyGranted: alreadyGranted,
        delay: Duration.zero);
    final container = ProviderContainer(overrides: [
      settingsServiceProvider
          .overrideWithValue(FakeSettingsService(delay: Duration.zero)),
      authServiceProvider.overrideWithValue(FakeAuthService()),
      reminderServiceProvider.overrideWithValue(reminder),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/setup/notifications', routes: [
      GoRoute(path: '/setup', builder: (_, __) => const Text('S02')),
      GoRoute(
          path: '/setup/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: '/setup/try-reminder', builder: (_, __) => const Text('N01')),
      GoRoute(path: '/setup/first-task', builder: (_, __) => const Text('N04')),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  void expectOnScreen(WidgetTester tester, String text) {
    final rect = tester.getRect(find.text(text));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(800));
  }

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.3, 2.0]) {
      testWidgets(
          '$width dp × $scale: S13 và S13d không tràn, nút đáy luôn thấy',
          (tester) async {
        await pumpS13(tester, width: width, textScale: scale);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Bật nhắc việc');
        expectOnScreen(tester, 'Để sau');
        await tester.scrollUntilVisible(find.textContaining('Bác bấm'), 100);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Để sau'));
        await tester.pumpAndSettle();
        expect(find.text('Nhắc việc đang tắt'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Vẫn để sau');
        expectOnScreen(tester, 'Bật nhắc việc');
        await tester.scrollUntilVisible(
            find.textContaining('Muốn bật lại'), 100);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('cho phép → /setup/try-reminder', (tester) async {
    await pumpS13(tester);
    expect(find.text('Cho phép nhắc việc'), findsOneWidget);
    expect(find.text('Bước 2/2'), findsOneWidget);
    await tester.tap(find.text('Bật nhắc việc'));
    await tester.pumpAndSettle();
    expect(find.text('N01'), findsOneWidget);
    expect(reminder.requestCount, 1);
  });

  testWidgets('từ chối → S13d; "Vẫn để sau" → /setup/first-task',
      (tester) async {
    await pumpS13(tester, permissionGranted: false);
    await tester.tap(find.text('Bật nhắc việc'));
    await tester.pumpAndSettle();
    expect(find.text('Nhắc việc đang tắt'), findsOneWidget);
    expect(find.text('Đến giờ điện thoại sẽ không đổ chuông.'), findsOneWidget);

    await tester.tap(find.text('Vẫn để sau'));
    await tester.pumpAndSettle();
    expect(find.text('N04'), findsOneWidget);
  });

  testWidgets('S13d "Quay lại" → về S13; S13 "Quay lại" → /setup',
      (tester) async {
    await pumpS13(tester);
    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Cho phép nhắc việc'), findsOneWidget);
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('S02'), findsOneWidget);
  });

  testWidgets('đã có quyền sẵn → đi thẳng /setup/try-reminder, không hỏi',
      (tester) async {
    await pumpS13(tester, alreadyGranted: true);
    expect(find.text('N01'), findsOneWidget);
    expect(reminder.requestCount, 0);
  });
}
