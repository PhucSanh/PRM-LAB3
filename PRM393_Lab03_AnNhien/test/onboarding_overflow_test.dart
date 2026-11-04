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
import 'package:an_nhien/viewmodels/first_task_view_model.dart';
import 'package:an_nhien/viewmodels/onboarding_view_model.dart';
import 'package:an_nhien/viewmodels/try_reminder_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F2 bước 07: mọi màn / state F2 không tràn ở 360×800 và 412×915,
/// `textScaler` 1.0 / 1.3 / 2.0, cả giao diện thường và tương phản cao.
void main() {
  const sizes = [Size(360, 800), Size(412, 915)];
  const scales = [1.0, 1.3, 2.0];

  for (final size in sizes) {
    for (final scale in scales) {
      for (final highContrast in [false, true]) {
        final label = '${size.width.toInt()}×${size.height.toInt()} · ×$scale'
            '${highContrast ? ' · tương phản cao' : ''}';
        testWidgets('$label: 12 state F2 không tràn', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final profiles = FakeProfileService(
              [const UserProfile(uid: 'u1', role: UserRole.elder)]);
          addTearDown(profiles.dispose);
          final c = ProviderContainer(overrides: [
            authServiceProvider.overrideWithValue(FakeAuthService(
                signedIn: const AppUser(uid: 'u1', displayName: 'Lan'))),
            settingsServiceProvider
                .overrideWithValue(FakeSettingsService(delay: Duration.zero)),
            profileSetupServiceProvider.overrideWithValue(
                FakeProfileSetupService(delay: Duration.zero)),
            profileServiceProvider.overrideWithValue(profiles),
            reminderServiceProvider.overrideWithValue(FakeReminderService(
                alreadyGranted: true, delay: Duration.zero)),
            habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
            taskRepositoryProvider
                .overrideWithValue(FakeTaskRepository(const [])),
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
            crashServiceProvider.overrideWithValue(FakeCrashService()),
          ]);
          addTearDown(c.dispose);
          final router = GoRouter(initialLocation: '/welcome', routes: [
            GoRoute(
                path: '/welcome', builder: (_, __) => const WelcomeScreen()),
            GoRoute(
                path: '/setup', builder: (_, __) => const SetupProfileScreen()),
            GoRoute(
                path: '/setup/notifications',
                builder: (_, __) => const NotificationsScreen()),
            GoRoute(
                path: '/setup/try-reminder',
                builder: (_, __) => const TryReminderScreen()),
            GoRoute(
                path: '/setup/first-task',
                builder: (_, __) => const FirstTaskScreen()),
          ]);
          addTearDown(router.dispose);

          await tester.pumpWidget(UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(
              theme: highContrast ? AppTheme.highContrast() : AppTheme.light(),
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          ));

          final seen = <String>[];
          Future<void> check(String state, String marker) async {
            await tester.pumpAndSettle();
            final error = tester.takeException();
            expect(error, isNull, reason: '$state ($label): $error');
            expect(find.text(marker), findsWidgets, reason: state);
            seen.add(state);
          }

          final onboarding = c.read(onboardingViewModelProvider.notifier);
          await check('S01', 'Chào mừng Bác!');

          router.go('/setup');
          await check('S02 xác nhận tên', 'Bác là Lan, đúng không?');
          onboarding.editName();
          await tester.pumpAndSettle();
          onboarding.setName('');
          onboarding.submitName();
          await check('S02 nhập lại tên + lỗi', 'Bác chưa nhập tên gọi.');
          onboarding.setName('Nguyễn Thị Lan');
          onboarding.submitName();
          await check('S02 giới thiệu về Bác', 'Giới thiệu về Bác');

          // Vào S13 lần đầu tự đi tiếp vì Fake có quyền sẵn → vẽ lại S13 sau đó.
          router.go('/setup/notifications');
          await tester.pumpAndSettle();
          router.go('/setup/notifications');
          onboarding.showReminderPrompt();
          await check('S13', 'Cho phép nhắc việc');
          onboarding.skipReminders();
          await check('S13d', 'Nhắc việc đang tắt');

          router.go('/setup/try-reminder');
          await check('N01', 'Thử lời nhắc');
          final tryVm = c.read(tryReminderViewModelProvider.notifier);
          tryVm.sendTest();
          await check('N02', 'Bác đã nhận được chưa?');
          tryVm.answer(false);
          await check('N03', 'Chưa nhận lời nhắc');

          router.go('/setup/first-task');
          await check('N04', 'Bác muốn làm gì?');
          final firstVm = c.read(firstTaskViewModelProvider.notifier);
          firstVm.confirmPick();
          await check('N05', 'Xem lại việc đầu tiên');
          firstVm.save();
          await check('N18', 'Đã lưu việc đầu tiên!');

          expect(seen, hasLength(12));
        });
      }
    }
  }
}
