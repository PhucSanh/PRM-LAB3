import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';
import 'auth_service.dart';
import 'crash_service.dart';
import 'family_repository.dart';
import 'habit_repository.dart';
import 'messaging_service.dart';
import 'remote_config_service.dart';
import 'report_service.dart';
import 'task_repository.dart';

/// Nơi DUY NHẤT chọn bản giả hay bản Firebase. Chủ file: B – Hiếu.
/// Ngày 4: đổi `Fake…()` thành `Firebase…()` ở đây, màn và ViewModel không phải sửa.
/// Test: `ProviderContainer(overrides: [taskRepositoryProvider.overrideWithValue(...)])`.
final authServiceProvider = Provider<AuthService>((ref) => FakeAuthService());
final taskRepositoryProvider = Provider<TaskRepository>((ref) => FakeTaskRepository());
final habitRepositoryProvider = Provider<HabitRepository>((ref) => FakeHabitRepository());
final familyRepositoryProvider = Provider<FamilyRepository>((ref) => FakeFamilyRepository());
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => FakeAnalyticsService());
final crashServiceProvider = Provider<CrashService>((ref) => FakeCrashService());
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) => FakeRemoteConfigService());
final messagingServiceProvider = Provider<MessagingService>((ref) => FakeMessagingService());
final reportServiceProvider = Provider<ReportService>((ref) => FakeReportService());
