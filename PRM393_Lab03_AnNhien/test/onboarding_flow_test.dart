import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/screens/onboarding/first_task_screen.dart';
import 'package:an_nhien/screens/onboarding/notifications_screen.dart';
import 'package:an_nhien/screens/onboarding/setup_profile_screen.dart';
import 'package:an_nhien/screens/onboarding/try_reminder_screen.dart';
import 'package:an_nhien/screens/onboarding/welcome_screen.dart';
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

/// F2 bước 07: đi hết Flow 1 (S01 → S02 → S13 → N01 → N04 → N05 → N18 → Hôm nay)
/// bằng service giả, và các nhánh phụ (tên trống, từ chối quyền, chưa nhận lời nhắc).
/// Route giống `app_router.dart` (5 route F2); `/today` là chỗ giữ của S03 (Khang).
void main() {
  late FakeProfileSetupService profileSetup;
  late FakeReminderService reminder;
  late FakeTaskRepository tasks;
  late FakeProfileService profiles;
  late FakeAnalyticsService analytics;

  Future<void> pumpFlow(WidgetTester tester,
      {bool permissionGranted = true}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    profileSetup = FakeProfileSetupService(delay: Duration.zero);
    reminder = FakeReminderService(
        permissionGranted: permissionGranted, delay: Duration.zero);
    tasks = FakeTaskRepository(const []);
    profiles = FakeProfileService([
      const UserProfile(uid: 'u1', displayName: 'Lan', role: UserRole.elder)
    ]);
    addTearDown(profiles.dispose);
    analytics = FakeAnalyticsService();
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(FakeAuthService(
          signedIn: const AppUser(uid: 'u1', displayName: 'Lan'))),
      settingsServiceProvider
          .overrideWithValue(FakeSettingsService(delay: Duration.zero)),
      profileSetupServiceProvider.overrideWithValue(profileSetup),
      profileServiceProvider.overrideWithValue(profiles),
      reminderServiceProvider.overrideWithValue(reminder),
      habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
      taskRepositoryProvider.overrideWithValue(tasks),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/welcome', routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupProfileScreen()),
      GoRoute(
          path: '/setup/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: '/setup/try-reminder',
          builder: (_, __) => const TryReminderScreen()),
      GoRoute(
          path: '/setup/first-task',
          builder: (_, __) => const FirstTaskScreen()),
      GoRoute(path: '/today', builder: (_, __) => const Text('S03 Hôm nay')),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// S01 → S02 xác nhận tên.
  Future<void> throughWelcome(WidgetTester tester) async {
    expect(find.text('Chào mừng Bác!'), findsOneWidget);
    await tapText(tester, 'Bắt đầu');
    expect(find.text('Bác là Lan, đúng không?'), findsOneWidget);
  }

  /// S02: nhập lại tên, đổi giờ thức dậy → S13.
  Future<void> throughProfile(WidgetTester tester) async {
    await tapText(tester, 'Nhập lại tên');
    await tester.enterText(find.byType(TextField), 'Lan');
    await tapText(tester, 'Tiếp tục');
    expect(find.text('Giới thiệu về Bác'), findsOneWidget);
    await tapText(tester, '6:00 sáng');
    await tapText(tester, '5');
    await tapText(tester, 'Lưu giờ');
    expect(find.text('5:00 sáng'), findsOneWidget);
    await tapText(tester, 'Tiếp tục');
    expect(find.text('Cho phép nhắc việc'), findsOneWidget);
  }

  testWidgets('đi hết S01 → … → N18 → Hôm nay có việc đầu tiên',
      (tester) async {
    await pumpFlow(tester);
    await throughWelcome(tester);
    await throughProfile(tester);
    final saved = profileSetup.saved['u1']!;
    expect(saved.displayName, 'Lan');
    expect((saved.wakeHour, saved.wakeMinute), (5, 0));

    // S13 cho phép → N01.
    await tapText(tester, 'Bật nhắc việc');
    expect(find.text('Thử lời nhắc'), findsOneWidget);

    // N01 gửi thử → N02 đã nhận → N04.
    await tapText(tester, 'Gửi thử');
    expect(find.text('Bác đã nhận được chưa?'), findsOneWidget);
    await tapText(tester, 'Đã nhận được');
    expect(find.text('Bác muốn làm gì?'), findsOneWidget);

    // N04 → N05 → N18.
    await tapText(tester, 'Tiếp tục');
    expect(find.text('Xem lại việc đầu tiên'), findsOneWidget);
    await tapText(tester, 'Lưu việc');
    expect(find.text('Đã lưu việc đầu tiên!'), findsOneWidget);

    // N18 → Hôm nay.
    await tapText(tester, 'Xem lịch');
    expect(find.text('S03 Hôm nay'), findsOneWidget);

    final today =
        (await tester.runAsync(() => tasks.tasksForDay(DateTime.now())))!;
    expect(today, hasLength(1));
    expect(reminder.scheduled.keys, [today.single.id]);
    final profile = (await tester.runAsync(() => profiles.watch('u1').first))!;
    expect(profile.onboarded, isTrue);
    expect(
        analytics.logged.where((e) => e == 'tutorial_complete'), hasLength(1));
    expect(analytics.logged,
        containsAllInOrder(['test_reminder', 'add_task', 'tutorial_complete']));
  });

  testWidgets('tên trống → báo lỗi, ở lại ô nhập', (tester) async {
    await pumpFlow(tester);
    await throughWelcome(tester);
    await tapText(tester, 'Nhập lại tên');
    await tester.enterText(find.byType(TextField), '   ');
    await tapText(tester, 'Tiếp tục');
    expect(find.text('Bác chưa nhập tên gọi.'), findsOneWidget);
    expect(find.text('Bác tên là gì?'), findsOneWidget);
    expect(profileSetup.saved, isEmpty);
  });

  testWidgets('từ chối quyền → S13d → "Vẫn để sau" → N04 → onboarding xong',
      (tester) async {
    await pumpFlow(tester, permissionGranted: false);
    await throughWelcome(tester);
    await throughProfile(tester);
    await tapText(tester, 'Bật nhắc việc');
    expect(find.text('Nhắc việc đang tắt'), findsOneWidget);
    await tapText(tester, 'Vẫn để sau');
    expect(find.text('Bác muốn làm gì?'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Để sau'), 200);
    await tapText(tester, 'Để sau');
    expect(find.text('S03 Hôm nay'), findsOneWidget);
    expect(reminder.scheduled, isEmpty);
    expect(
        analytics.logged.where((e) => e == 'tutorial_complete'), hasLength(1));
  });

  testWidgets('thử lời nhắc chưa nhận → N03 → "Dùng lịch trước" → N04',
      (tester) async {
    await pumpFlow(tester);
    await throughWelcome(tester);
    await tapText(tester, 'Đúng rồi');
    await tapText(tester, 'Tiếp tục');
    await tapText(tester, 'Bật nhắc việc');
    await tapText(tester, 'Gửi thử');
    await tapText(tester, 'Chưa nhận được');
    expect(find.text('Chưa nhận lời nhắc'), findsOneWidget);
    await tapText(tester, 'Dùng lịch trước');
    expect(find.text('Bác muốn làm gì?'), findsOneWidget);
  });
}
