import 'package:an_nhien/services/voice_task_service.dart';
import 'package:an_nhien/services/device_access_service.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/suggestion_service.dart' as incoming;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/family_repository.dart';
import 'package:an_nhien/services/habit_repository.dart';
import 'package:an_nhien/services/messaging_service.dart';
import 'package:an_nhien/services/pairing_service.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/remote_config_service.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/report_service.dart';
import 'package:an_nhien/services/session_data_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/services/caregiver_suggestion_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/caregiver_schedule_view_model.dart';

ProviderContainer demoContainer(
        {String initialRoute = '/today',
        UserRole? role = UserRole.elder,
        FakeCaregiverScheduleService? schedules,
        FakeSuggestionService? suggestions,
        MessagingService? messages,
        List<TaskItem>? tasks,
        TaskRepository? taskRepository,
        ProfileService? profiles,
        DeviceAccessService? device,
        ReminderService? reminders,
        incoming.SuggestionService? incomingSuggestions,
        SettingsService? settings,
        VoiceTaskService? voiceTasks}) =>
    ProviderContainer(overrides: [
      voiceTaskServiceProvider
          .overrideWithValue(voiceTasks ?? FakeVoiceTaskService()),
      deviceAccessServiceProvider
          .overrideWithValue(device ?? AndroidDeviceAccessService()),
      authGuardEnabledProvider.overrideWithValue(false),
      initialRouteProvider.overrideWithValue(initialRoute),
      suggestionServiceProvider.overrideWithValue(incomingSuggestions ??
          incoming.FakeSuggestionService(delay: Duration.zero)),
      authServiceProvider.overrideWithValue(FakeAuthService(
          signedIn: const AppUser(uid: 'demo-user', displayName: 'Bác Lan'))),
      profileServiceProvider.overrideWithValue(profiles ??
          FakeProfileService([
            UserProfile(
                uid: 'demo-user',
                displayName: 'Bác Lan',
                role: role,
                onboarded: true,
                pairedMomUid: 'demo-mom')
          ])),
      pairedMomUidProvider.overrideWithValue('demo-mom'),
      caregiverScheduleServiceProvider
          .overrideWithValue(schedules ?? FakeCaregiverScheduleService()),
      caregiverSuggestionServiceProvider
          .overrideWithValue(suggestions ?? FakeSuggestionService()),
      pairingServiceProvider.overrideWithValue(FakePairingService()),
      taskRepositoryProvider
          .overrideWithValue(taskRepository ?? FakeTaskRepository(tasks ?? [])),
      familyRepositoryProvider.overrideWithValue(FakeFamilyRepository()),
      habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
      settingsServiceProvider
          .overrideWithValue(settings ?? FakeSettingsService()),
      profileSetupServiceProvider.overrideWithValue(FakeProfileSetupService()),
      reminderServiceProvider
          .overrideWithValue(reminders ?? FakeReminderService()),
      sessionDataServiceProvider.overrideWithValue(FakeSessionDataService()),
      messagingServiceProvider
          .overrideWithValue(messages ?? FakeMessagingService()),
      reportServiceProvider.overrideWithValue(FakeReportService()),
      demoReportServiceProvider.overrideWithValue(FakeReportService()),
      remoteConfigServiceProvider.overrideWithValue(FakeRemoteConfigService()),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
