import 'firebase_family_suggestion_service.dart';
import 'caregiver_suggestion_service.dart' as caregiver;
import 'local_reminder_service.dart';
import 'reminder_runtime.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'caregiver_schedule_service.dart';
import 'firebase_caregiver_schedule_service.dart';
import 'firebase_pairing_service.dart';
import 'pairing_service.dart';
import 'firebase_suggestion_service.dart';
import 'firebase_settings_service.dart';
import 'demo_pdf.dart';
import 'profile_service.dart';
import 'firebase_profile_service.dart';
import 'session_data_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_auth_service.dart';
import 'firebase_repositories.dart';
import 'firebase_telemetry_services.dart';
import 'firebase_messaging_service.dart';
import 'firebase_report_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';
import 'auth_service.dart';
import 'crash_service.dart';
import 'family_repository.dart';
import 'habit_repository.dart';
import 'messaging_service.dart';
import 'profile_setup_service.dart';
import 'remote_config_service.dart';
import 'reminder_service.dart';
import 'report_service.dart';
import 'settings_service.dart';
import 'suggestion_service.dart';
import 'task_repository.dart';

final nativeReminderEventsEnabledProvider = Provider<bool>((ref) => false);

/// Có thể override bằng named Firebase app khi chạy Emulator; mặc định giữ project thật.
final firestoreSdkProvider = Provider((ref) => FirebaseFirestore.instance);
final authSdkProvider = Provider((ref) => FirebaseAuth.instance);
final functionsSdkProvider =
    Provider((ref) => FirebaseFunctions.instanceFor(region: 'asia-southeast1'));

/// Nơi DUY NHẤT chọn bản giả hay bản Firebase. Chủ file: B – Hiếu.
/// Production dùng Firebase. Fake vẫn có sẵn để override trong test.
/// Test: `ProviderContainer(overrides: [taskRepositoryProvider.overrideWithValue(...)])`.
final authServiceProvider = Provider<AuthService>(
    (ref) => FirebaseAuthService(ref.watch(authSdkProvider)));
final taskRepositoryProvider = Provider<TaskRepository>(
    (ref) => FirebaseTaskRepository(ref.watch(_userDataProvider)));
final habitRepositoryProvider = Provider<HabitRepository>(
    (ref) => FirebaseHabitRepository(ref.watch(_userDataProvider)));
final familyRepositoryProvider = Provider<FamilyRepository>(
    (ref) => FirebaseFamilyRepository(ref.watch(_userDataProvider)));
final analyticsServiceProvider = Provider<AnalyticsService>(
    (ref) => FirebaseAnalyticsService(FirebaseAnalytics.instance));
final crashServiceProvider = Provider<CrashService>(
    (ref) => FirebaseCrashService(FirebaseCrashlytics.instance));
final remoteConfigServiceProvider = Provider<RemoteConfigService>(
    (ref) => FirebaseRemoteConfigService(FirebaseRemoteConfig.instance));
final messagingServiceProvider = Provider<MessagingService>((ref) {
  final service = FirebaseMessagingService(FirebaseMessaging.instance,
      ref.watch(firestoreSdkProvider), ref.watch(authSdkProvider));
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
final reportServiceProvider = Provider<ReportService>((ref) =>
    FirebaseReportService(FirebaseAuth.instance, FirebaseStorage.instance));

final _userDataProvider = Provider((ref) => FirebaseUserData(
    ref.watch(firestoreSdkProvider), ref.watch(authSdkProvider)));

final profileServiceProvider = Provider<ProfileService>((ref) =>
    FirebaseProfileService(
        ref.watch(firestoreSdkProvider), ref.watch(authSdkProvider)));
final sessionDataServiceProvider = Provider<SessionDataService>((ref) =>
    FirebaseSessionDataService(ref.watch(firestoreSdkProvider),
        beforeClear: () async {
      final reminders = ref.read(reminderServiceProvider);
      if (reminders is LocalReminderService) await reminders.clearAll();
      await (ref.read(messagingServiceProvider) as FirebaseMessagingService)
          .prepareSignOut();
    }));

// Contract F2 (Hương), adapter Firebase (Hiếu).
// Firebase giữ nguyên contract F2, lưu theo UID.
final settingsServiceProvider = Provider<SettingsService>(
    (ref) => FirebaseSettingsService(ref.watch(_userDataProvider)));
// Android native: F2/F6 qua cùng interface; Fake chỉ dùng demo/test.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final auth = ref.watch(authSdkProvider);
  final service = LocalReminderService(() => auth.currentUser?.uid);
  ref.onDispose(service.dispose);
  return service;
});
// S02 giữ interface riêng để tương thích ViewModel của Hương.
final profileSetupServiceProvider = Provider<ProfileSetupService>(
    (ref) => FirebaseProfileSetupService(ref.watch(_userDataProvider)));

// Main family screens and inbox share the Firebase tasks/callables schema.
final suggestionServiceProvider = Provider<SuggestionService>((ref) =>
    FirebaseFamilySuggestionService(
        ref.watch(_userDataProvider), ref.watch(callableClientProvider)));

/// F10 uses a labelled test PDF; F7 retains its own renderer contract.
final demoReportServiceProvider = Provider<ReportService>((ref) =>
    FirebaseReportService(FirebaseAuth.instance, FirebaseStorage.instance,
        renderPdf: renderDemoPdf));

final callableClientProvider =
    Provider((ref) => FirebaseCallableClient(ref.watch(functionsSdkProvider)));
final pairingServiceProvider = Provider<PairingService>((ref) =>
    FirebasePairingService(
        ref.watch(callableClientProvider), ref.watch(_userDataProvider)));
final caregiverScheduleServiceProvider = Provider<CaregiverScheduleService>(
    (ref) => FirebaseCaregiverScheduleService(ref.watch(_userDataProvider)));
final caregiverSuggestionServiceProvider =
    Provider<caregiver.SuggestionService>((ref) => FirebaseSuggestionService(
        ref.watch(_userDataProvider), ref.watch(callableClientProvider)));

final reminderRuntimeProvider = Provider<ReminderRuntime>((ref) {
  final runtime = ReminderRuntime(
      ref.watch(authSdkProvider),
      ref.watch(caregiverScheduleServiceProvider),
      ref.watch(reminderServiceProvider) as LocalReminderService,
      ref.watch(crashServiceProvider), onNativePermissionGranted: () async {
    final messaging = ref.read(messagingServiceProvider);
    if (messaging is FirebaseMessagingService) {
      try {
        await messaging.syncRegistration();
      } catch (_) {
        // Permission is already granted; registration retries on app resume.
      }
    }
  });
  ref.onDispose(runtime.dispose);
  return runtime;
});
