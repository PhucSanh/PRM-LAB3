import 'package:an_nhien/screens/onboarding/try_reminder_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F2 bước 05: N01 Thử lời nhắc · N02 hỏi đã nhận · N03 Chưa nhận lời nhắc.
void main() {
  late FakeReminderService reminder;
  late FakeAnalyticsService analytics;

  Future<void> pumpN01(WidgetTester tester,
      {bool failOnShowTest = false,
      double width = 360,
      double textScale = 1.0}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    reminder = FakeReminderService(
        alreadyGranted: true,
        failOnShowTest: failOnShowTest,
        delay: Duration.zero);
    analytics = FakeAnalyticsService();
    final container = ProviderContainer(overrides: [
      reminderServiceProvider.overrideWithValue(reminder),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/setup/try-reminder', routes: [
      GoRoute(
          path: '/setup/notifications', builder: (_, __) => const Text('S13')),
      GoRoute(
          path: '/setup/try-reminder',
          builder: (_, __) => const TryReminderScreen()),
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

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.3, 2.0]) {
      testWidgets(
          '$width dp × $scale: N01, N02, N03 không tràn, nút đáy luôn thấy',
          (tester) async {
        await pumpN01(tester, width: width, textScale: scale);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Gửi thử');
        expectOnScreen(tester, 'Để sau');
        await tester.scrollUntilVisible(
            find.textContaining('bất cứ khi nào'), 100);
        expect(tester.takeException(), isNull);

        await tapText(tester, 'Gửi thử');
        expect(find.text('Bác đã nhận được chưa?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Đã nhận được');
        expectOnScreen(tester, 'Chưa nhận được');

        await tapText(tester, 'Chưa nhận được');
        expect(find.text('Chưa nhận lời nhắc'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Dùng lịch trước');
        await tester.scrollUntilVisible(find.text('3. Thử lại'), 100);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('gửi thử → "Đã nhận được" → /setup/first-task, log 1 lần',
      (tester) async {
    await pumpN01(tester);
    await tapText(tester, 'Gửi thử');
    expect(reminder.testShownCount, 1);
    await tapText(tester, 'Đã nhận được');
    expect(find.text('N04'), findsOneWidget);
    expect(analytics.logged, ['test_reminder']);
  });

  testWidgets('chưa nhận → N03; "Thử lại" gửi lại; "Dùng lịch trước" đi tiếp',
      (tester) async {
    await pumpN01(tester);
    await tapText(tester, 'Gửi thử');
    await tapText(tester, 'Chưa nhận được');
    expect(analytics.logged, ['test_reminder']);

    await tapText(tester, 'Thử lại');
    expect(reminder.testShownCount, 2);
    expect(find.text('Bác đã nhận được chưa?'), findsOneWidget);

    await tapText(tester, 'Chưa nhận được');
    await tapText(tester, 'Dùng lịch trước');
    expect(find.text('N04'), findsOneWidget);
  });

  testWidgets('gửi lỗi → câu lỗi + "Thử lại" ở N01', (tester) async {
    await pumpN01(tester, failOnShowTest: true);
    await tapText(tester, 'Gửi thử');
    expect(find.textContaining('Chưa gửi được'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Thử lời nhắc'), findsOneWidget);

    reminder.failOnShowTest = false;
    await tapText(tester, 'Thử lại');
    expect(find.text('Bác đã nhận được chưa?'), findsOneWidget);
  });

  testWidgets('"Để sau" → /setup/first-task, không gửi thử', (tester) async {
    await pumpN01(tester);
    await tapText(tester, 'Để sau');
    expect(find.text('N04'), findsOneWidget);
    expect(reminder.testShownCount, 0);
    expect(analytics.logged, isEmpty);
  });

  testWidgets('"Quay lại": N03 → N01 → /setup/notifications', (tester) async {
    await pumpN01(tester);
    await tapText(tester, 'Gửi thử');
    await tapText(tester, 'Chưa nhận được');
    await tapText(tester, 'Quay lại');
    expect(find.text('Thử lời nhắc'), findsOneWidget);
    await tapText(tester, 'Quay lại');
    expect(find.text('S13'), findsOneWidget);
  });
}
