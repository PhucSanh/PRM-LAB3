// Bản chạy DEV: bỏ qua Google Sign-In và Firebase, mọi service dùng bản Fake.
// Dùng để code / xem màn khi chưa đăng nhập được. KHÔNG dùng cho bản nộp.
//
//   flutter run -d emulator-5554 -t lib/main_dev.dart
//
// Muốn mở thẳng màn cần làm: sửa `initialLocation` trong app_router.dart
// tạm thời, hoặc bấm điều hướng trong app. Bản thật vẫn chạy bằng lib/main.dart.
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
import 'services/providers.dart';
import 'services/remote_config_service.dart';
import 'services/report_service.dart';
import 'services/task_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(
    overrides: [
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
      reportServiceProvider.overrideWithValue(FakeReportService()),
    ],
    child: const AnNhienApp(),
  ));
}
