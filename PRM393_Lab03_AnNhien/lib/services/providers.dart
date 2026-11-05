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
import 'contact_launcher_service.dart';
import 'contacts_service.dart';
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

/// Nơi DUY NHẤT chọn bản giả hay bản Firebase. Chủ file: B – Hiếu.
/// Production dùng Firebase. Fake vẫn có sẵn để override trong test.
/// Test: `ProviderContainer(overrides: [taskRepositoryProvider.overrideWithValue(...)])`.
final authServiceProvider =
    Provider<AuthService>((ref) => FirebaseAuthService(FirebaseAuth.instance));
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
      FirebaseFirestore.instance, FirebaseAuth.instance);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
final reportServiceProvider = Provider<ReportService>((ref) =>
    FirebaseReportService(FirebaseAuth.instance, FirebaseStorage.instance));

final _userDataProvider = Provider((ref) =>
    FirebaseUserData(FirebaseFirestore.instance, FirebaseAuth.instance));

final profileServiceProvider = Provider<ProfileService>((ref) =>
    FirebaseProfileService(FirebaseFirestore.instance, FirebaseAuth.instance));
final sessionDataServiceProvider = Provider<SessionDataService>((ref) =>
    FirebaseSessionDataService(FirebaseFirestore.instance,
        beforeClear: () async {
      await (ref.read(messagingServiceProvider) as FirebaseMessagingService)
          .prepareSignOut();
    }));

// F2 (Hương) thêm, đang trỏ bản Fake.
// TODO(Hiếu): bản Firebase (Firestore users/{uid} + cache máy).
final settingsServiceProvider =
    Provider<SettingsService>((ref) => FakeSettingsService());
// TODO(Hiếu): bản thật (flutter_local_notifications – đề xuất package trong PR).
final reminderServiceProvider =
    Provider<ReminderService>((ref) => FakeReminderService());
// TODO(Hiếu): tạm cho S02; gộp `saveSetup` vào ProfileService (bản Firebase) rồi bỏ.
final profileSetupServiceProvider =
    Provider<ProfileSetupService>((ref) => FakeProfileSetupService());

// F12 (Sanh) thêm, đang trỏ bản Fake có dữ liệu mẫu Figma (Mai · Con gái, 2 việc ngày mai),
// không độ trễ (để test dựng cả app không còn Timer treo).
// TODO(Hiếu): bản Firebase – Firestore users/{momUid}/suggestions + FCM "có gợi ý mới"
// mở /today/suggestions/:id; rules cho con cháu đã ghép nối tạo, mẹ cập nhật status / popupShown.
final suggestionServiceProvider = Provider<SuggestionService>(
    (ref) => FakeSuggestionService(withSample: true, delay: Duration.zero));

// F11 (Hương) thêm, đang trỏ bản Fake (danh bạ mẫu Figma S12 `1:2146`, đã cho phép khi hỏi).
// TODO(Hiếu): bản thật khi có package (đề xuất trong PR F11: flutter_contacts, url_launcher).
final contactsServiceProvider =
    Provider<ContactsService>((ref) => FakeContactsService());
final contactLauncherServiceProvider =
    Provider<ContactLauncherService>((ref) => FakeContactLauncherService());

/// F10 uses a labelled test PDF; F7 retains its own renderer contract.
final demoReportServiceProvider = Provider<ReportService>((ref) =>
    FirebaseReportService(FirebaseAuth.instance, FirebaseStorage.instance,
        renderPdf: renderDemoPdf));
