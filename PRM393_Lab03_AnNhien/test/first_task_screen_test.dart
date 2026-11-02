import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/screens/onboarding/first_task_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/habit_repository.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F2 bước 06: N04 Chọn việc đầu tiên → N05 Xem lại → N18 Đã lưu.
void main() {
  late FakeTaskRepository tasks;
  late FakeProfileService profiles;
  late FakeAnalyticsService analytics;

  Future<void> pumpN04(WidgetTester tester,
      {double width = 360, double textScale = 1.0}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    tasks = FakeTaskRepository(const []);
    profiles = FakeProfileService(
        [const UserProfile(uid: 'u1', role: UserRole.elder)]);
    addTearDown(profiles.dispose);
    analytics = FakeAnalyticsService();
    final container = ProviderContainer(overrides: [
      settingsServiceProvider
          .overrideWithValue(FakeSettingsService(delay: Duration.zero)),
      authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'u1'))),
      profileSetupServiceProvider
          .overrideWithValue(FakeProfileSetupService(delay: Duration.zero)),
      reminderServiceProvider.overrideWithValue(
          FakeReminderService(alreadyGranted: true, delay: Duration.zero)),
      habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
      taskRepositoryProvider.overrideWithValue(tasks),
      profileServiceProvider.overrideWithValue(profiles),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/setup/first-task', routes: [
      GoRoute(
          path: '/setup/notifications', builder: (_, __) => const Text('S13')),
      GoRoute(
          path: '/setup/first-task',
          builder: (_, __) => const FirstTaskScreen()),
      GoRoute(path: '/today', builder: (_, __) => const Text('S03')),
      GoRoute(path: '/today/add', builder: (_, __) => const Text('S05')),
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
          '$width dp × $scale: N04, N05, N18 không tràn, nút đáy luôn thấy',
          (tester) async {
        await pumpN04(tester, width: width, textScale: scale);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Tiếp tục');
        expectOnScreen(tester, 'Để sau');
        await tester.scrollUntilVisible(
            find.textContaining('Bác cứ chọn thử'), 200);
        expect(tester.takeException(), isNull);

        await tapText(tester, 'Tiếp tục');
        expect(find.text('Xem lại việc đầu tiên'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Lưu việc');
        await tester.scrollUntilVisible(find.text('Nhịp nhắc'), 100);
        expect(tester.takeException(), isNull);

        await tapText(tester, 'Lưu việc');
        expect(find.text('Đã lưu việc đầu tiên!'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Xem lịch');
        expectOnScreen(tester, 'Thêm việc khác');
      });
    }
  }

  testWidgets('đi hết N04 → N05 → N18 → "Xem lịch" → /today, đã onboarding',
      (tester) async {
    await pumpN04(tester);
    expect(find.text('Bác muốn làm gì?'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Trà chiều cùng bạn'), 200);
    await tapText(tester, 'Trà chiều cùng bạn');
    await tapText(tester, 'Tiếp tục');
    await tapText(tester, 'Lưu việc');

    final saved =
        (await tester.runAsync(() => tasks.tasksForDay(DateTime.now())))!;
    expect(saved.single.habitKey, 'tea');
    expect(find.text('Trà chiều cùng bạn'), findsOneWidget);

    await tapText(tester, 'Xem lịch');
    expect(find.text('S03'), findsOneWidget);
    expect((await tester.runAsync(() => profiles.watch('u1').first))!.onboarded,
        isTrue);
    expect(analytics.logged, ['add_task', 'tutorial_complete']);
  });

  testWidgets('"Thêm việc khác" ở N18 → /today/add', (tester) async {
    await pumpN04(tester);
    await tapText(tester, 'Tiếp tục');
    await tapText(tester, 'Lưu việc');
    await tapText(tester, 'Thêm việc khác');
    expect(find.text('S05'), findsOneWidget);
  });

  testWidgets('"Để sau" ở N04 → /today, không lưu việc, vẫn onboarding',
      (tester) async {
    await pumpN04(tester);
    await tapText(tester, 'Để sau');
    expect(find.text('S03'), findsOneWidget);
    expect((await tester.runAsync(() => tasks.tasksForDay(DateTime.now())))!,
        isEmpty);
    expect((await tester.runAsync(() => profiles.watch('u1').first))!.onboarded,
        isTrue);
    expect(analytics.logged, ['tutorial_complete']);
  });

  testWidgets('"Quay lại": N05 → N04 → /setup/notifications', (tester) async {
    await pumpN04(tester);
    await tapText(tester, 'Tiếp tục');
    await tapText(tester, 'Quay lại');
    expect(find.text('Bác muốn làm gì?'), findsOneWidget);
    await tapText(tester, 'Quay lại');
    expect(find.text('S13'), findsOneWidget);
  });

  testWidgets('chạm ô giờ ở N05 → mở hộp chọn giờ', (tester) async {
    await pumpN04(tester);
    await tapText(tester, 'Tiếp tục');
    await tester.scrollUntilVisible(find.text('9:00 sáng'), 100);
    await tapText(tester, '9:00 sáng');
    expect(find.text('Bác muốn làm việc này lúc mấy giờ?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
