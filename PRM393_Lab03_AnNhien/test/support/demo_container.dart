import 'package:an_nhien/services/suggestion_service.dart' as incoming;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:an_nhien/models/app_user.dart';
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
        {FakeCaregiverScheduleService? schedules,
        FakeSuggestionService? suggestions,
        MessagingService? messages}) =>
    ProviderContainer(overrides: [
      suggestionServiceProvider.overrideWithValue(
          incoming.FakeSuggestionService(delay: Duration.zero)),
      authServiceProvider.overrideWithValue(FakeAuthService(
          signedIn: const AppUser(uid: 'demo-user', displayName: 'Bác Lan'))),
      profileServiceProvider.overrideWithValue(FakeProfileService([
        const UserProfile(
            uid: 'demo-user',
            displayName: 'Bác Lan',
            role: UserRole.elder,
            onboarded: true,
            pairedMomUid: 'demo-mom')
      ])),
      pairedMomUidProvider.overrideWithValue('demo-mom'),
      caregiverScheduleServiceProvider
          .overrideWithValue(schedules ?? FakeCaregiverScheduleService()),
      caregiverSuggestionServiceProvider
          .overrideWithValue(suggestions ?? FakeSuggestionService()),
      pairingServiceProvider.overrideWithValue(FakePairingService()),
      taskRepositoryProvider.overrideWithValue(FakeTaskRepository([])),
      familyRepositoryProvider.overrideWithValue(FakeFamilyRepository()),
      habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
      settingsServiceProvider.overrideWithValue(FakeSettingsService()),
      profileSetupServiceProvider.overrideWithValue(FakeProfileSetupService()),
      reminderServiceProvider.overrideWithValue(FakeReminderService()),
      sessionDataServiceProvider.overrideWithValue(FakeSessionDataService()),
      messagingServiceProvider
          .overrideWithValue(messages ?? FakeMessagingService()),
      reportServiceProvider.overrideWithValue(FakeReportService()),
      demoReportServiceProvider.overrideWithValue(FakeReportService()),
      remoteConfigServiceProvider.overrideWithValue(FakeRemoteConfigService()),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
