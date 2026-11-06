import 'services/contact_launcher_service.dart';
import 'services/local_voice_task_service.dart';
import 'main.dart' as production;
import 'models/user_profile.dart';
import 'models/task_item.dart';
import 'services/pairing_service.dart';
import 'services/profile_service.dart';
import 'services/profile_setup_service.dart';
import 'services/settings_service.dart';
import 'services/reminder_service.dart';
import 'services/session_data_service.dart';
import 'services/caregiver_schedule_service.dart';
import 'services/caregiver_suggestion_service.dart';
import 'router/app_router.dart';
import 'viewmodels/caregiver_schedule_view_model.dart';
// Entry mặc định dùng Google Sign-In/Firebase thật qua main.dart.
// UI_PREVIEW=true mới bật dữ liệu Fake đăng nhập sẵn; chỉ dành cho xem UI.
//
//   flutter run -d emulator-5554 -t lib/main_dev.dart
// Xem UI không đăng nhập: thêm --dart-define=UI_PREVIEW=true
//
// Chọn vai trò demo: --dart-define=DEMO_ROLE=elder|caregiver.
// Mở thẳng màn: --dart-define=INITIAL_ROUTE=/caregiver/schedule. Bản thật vẫn chạy bằng lib/main.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'models/app_user.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/crash_service.dart';
import 'services/family_repository.dart';
import 'services/habit_repository.dart';
import 'services/messaging_service.dart';
import 'services/suggestion_service.dart' as incoming;
import 'services/providers.dart';
import 'services/remote_config_service.dart';
import 'services/report_service.dart';
import 'services/task_repository.dart';

Future<void> main() async {
  // Existing launch configurations also use real Google/Firebase login by default.
  // Fake pre-authenticated data is available only by explicit UI_PREVIEW opt-in.
  const preview = bool.fromEnvironment('UI_PREVIEW', defaultValue: false);
  if (!preview) {
    await production.main();
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  const roleName = String.fromEnvironment('DEMO_ROLE', defaultValue: 'elder');
  final demoRole = UserRole.values.byName(roleName);
  final schedules = FakeCaregiverScheduleService([
    TaskItem(
        id: 'demo-walk',
        title: 'Đi bộ buổi sáng',
        habitKey: 'move',
        hour: 8,
        minute: 0,
        startDate: dateKey(vietnamToday()),
        repeat: RepeatRule.weekly,
        weekdays: [1, 3, 5]),
    TaskItem(
        id: 'demo-breakfast',
        title: 'Ăn sáng chậm rãi',
        habitKey: 'eighty',
        hour: 7,
        minute: 30,
        startDate: dateKey(vietnamToday())),
  ]);
  runApp(ProviderScope(
    overrides: [
      contactLauncherServiceProvider
          .overrideWithValue(FakeContactLauncherService()),
      voiceTaskServiceProvider.overrideWithValue(LocalVoiceTaskService()),
      authGuardEnabledProvider.overrideWithValue(false),
      initialRouteProvider.overrideWithValue(const String.fromEnvironment(
          'INITIAL_ROUTE',
          defaultValue: '/intro')),
      profileServiceProvider.overrideWithValue(FakeProfileService([
        UserProfile(
            uid: 'dev-uid',
            displayName: 'Bác Lan',
            role: demoRole,
            onboarded: true,
            pairedMomUid: 'demo-mom'),
      ])),
      sessionDataServiceProvider.overrideWithValue(FakeSessionDataService()),
      settingsServiceProvider.overrideWithValue(FakeSettingsService()),
      profileSetupServiceProvider.overrideWithValue(FakeProfileSetupService()),
      reminderServiceProvider.overrideWithValue(FakeReminderService()),
      pairedMomUidProvider.overrideWithValue('demo-mom'),
      pairingServiceProvider.overrideWithValue(FakePairingService()),
      caregiverScheduleServiceProvider.overrideWithValue(schedules),
      caregiverSuggestionServiceProvider.overrideWithValue(
          FakeSuggestionService(onAccept: schedules.acceptTasks)),
      demoReportServiceProvider.overrideWithValue(FakeReportService()),
      // Đã đăng nhập sẵn → router không chặn ở /sign-in.
      authServiceProvider.overrideWithValue(FakeAuthService(
          signedIn: const AppUser(uid: 'dev-uid', displayName: 'Bác Lan'))),
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository()),
      habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
      familyRepositoryProvider.overrideWithValue(FakeFamilyRepository()),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
      remoteConfigServiceProvider.overrideWithValue(FakeRemoteConfigService()),
      messagingServiceProvider.overrideWithValue(FakeMessagingService()),
      suggestionServiceProvider.overrideWithValue(
          incoming.FakeSuggestionService(
              withSample: true, delay: Duration.zero)),
      reportServiceProvider.overrideWithValue(FakeReportService()),
    ],
    child: const AnNhienApp(),
  ));
}
