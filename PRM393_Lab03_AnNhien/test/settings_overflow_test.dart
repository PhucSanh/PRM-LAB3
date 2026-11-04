import 'dart:async';

import 'package:an_nhien/models/app_settings.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/screens/settings/data_screen.dart';
import 'package:an_nhien/screens/settings/help_screen.dart';
import 'package:an_nhien/screens/settings/profile_screen.dart';
import 'package:an_nhien/screens/settings/settings_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/session_data_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F8 bước 05: mọi màn / state F8 không tràn ở 360×800 và 412×915,
/// `textScaler` 1.0 / 1.3 / 2.0, cả giao diện thường và tương phản cao.

/// `watch()` không bao giờ phát → S10 đứng ở Loading.
class SilentSettingsService extends FakeSettingsService {
  SilentSettingsService() : super(delay: Duration.zero);
  final _never = StreamController<AppSettings>();

  @override
  Stream<AppSettings> watch() => _never.stream;
}

class BrokenSettingsService extends FakeSettingsService {
  BrokenSettingsService() : super(delay: Duration.zero);

  @override
  Stream<AppSettings> watch() =>
      Stream.error(const AppException('Chưa tải được cài đặt.'));
}

/// `watchSetup` không phát → N06 đứng ở Loading; [broken] → N06 lỗi.
class OddProfileSetupService extends FakeProfileSetupService {
  OddProfileSetupService({this.silent = false, this.broken = false})
      : super(delay: Duration.zero);
  final bool silent;
  final bool broken;
  final _never = StreamController<ProfileSetup?>();

  @override
  Stream<ProfileSetup?> watchSetup(String uid) {
    if (silent) return _never.stream;
    if (broken) {
      return Stream.error(
          const AppException('Chưa có mạng. Bác thử lại sau nhé.'));
    }
    return super.watchSetup(uid);
  }
}

/// Xem `settings_flow_test.dart`: `.first` trên `FakeProfileService.watch`
/// treo trong `testWidgets`.
class StaticProfileService extends FakeProfileService {
  StaticProfileService() : super(const [_profile]);
  static const _profile =
      UserProfile(uid: 'u1', displayName: 'Lan', role: UserRole.elder);

  @override
  Stream<UserProfile> watch(String uid) => Stream.value(_profile);
}

const _lan = ProfileSetup(
    displayName: 'Lan', honorific: Honorific.ba, wakeHour: 5, wakeMinute: 30);

void main() {
  const sizes = [Size(360, 800), Size(412, 915)];
  const scales = [1.0, 1.3, 2.0];

  Future<void> pumpRoute(
    WidgetTester tester,
    String path, {
    required Size size,
    required double scale,
    required bool highContrast,
    SettingsService? settings,
    FakeProfileSetupService? profileSetup,
    bool settle = true,
  }) async {
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'u1'))),
      sessionDataServiceProvider.overrideWithValue(FakeSessionDataService()),
      settingsServiceProvider.overrideWithValue(
          settings ?? FakeSettingsService(delay: Duration.zero)),
      profileServiceProvider.overrideWithValue(StaticProfileService()),
      profileSetupServiceProvider.overrideWithValue(profileSetup ??
          FakeProfileSetupService(
              delay: Duration.zero, seed: const {'u1': _lan})),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: path, routes: [
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/settings/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/settings/data', builder: (_, __) => const DataScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Loading: vòng xoay chạy mãi, không chờ "settle".
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  /// Cuộn tới [text] (nếu cần) rồi kiểm không có lỗi tràn / layout.
  Future<void> reach(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    expect(find.text(text), findsWidgets, reason: text);
    expect(tester.takeException(), isNull, reason: text);
  }

  for (final size in sizes) {
    for (final scale in scales) {
      for (final highContrast in [false, true]) {
        final label = '${size.width.toInt()}×${size.height.toInt()} · ×$scale'
            '${highContrast ? ' · tương phản cao' : ''}';

        void setView(WidgetTester tester) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
        }

        testWidgets('$label: S10 Data + hộp hỏi đăng xuất', (tester) async {
          setView(tester);
          await pumpRoute(tester, '/settings',
              size: size, scale: scale, highContrast: highContrast);
          expect(tester.takeException(), isNull);
          await reach(tester, 'Rung khi có lời nhắc');
          await reach(tester, 'Đăng xuất');
          await tester.tap(find.text('Đăng xuất'));
          await tester.pumpAndSettle();
          await reach(tester, 'Bác muốn đăng xuất?');
          await reach(tester, 'Ở lại');
        });

        testWidgets('$label: S10 Loading + Error', (tester) async {
          setView(tester);
          await pumpRoute(tester, '/settings',
              size: size,
              scale: scale,
              highContrast: highContrast,
              settings: SilentSettingsService(),
              settle: false);
          expect(find.byType(LoadingView), findsOneWidget);
          expect(tester.takeException(), isNull);

          await pumpRoute(tester, '/settings',
              size: size,
              scale: scale,
              highContrast: highContrast,
              settings: BrokenSettingsService());
          expect(find.byType(ErrorView), findsOneWidget);
          await reach(tester, 'Thử lại');
        });

        testWidgets('$label: N06 Data + lỗi tên + hộp hỏi bỏ thay đổi',
            (tester) async {
          setView(tester);
          await pumpRoute(tester, '/settings/profile',
              size: size, scale: scale, highContrast: highContrast);
          expect(tester.takeException(), isNull);
          await reach(tester, 'Việc đã lưu vẫn giữ giờ cũ.');
          await reach(tester, 'Khu thử tính năng');

          await tester.ensureVisible(find.byType(TextField));
          await tester.enterText(find.byType(TextField), '');
          await tester.pump();
          await tester.tap(find.text('Lưu thông tin'));
          await tester.pumpAndSettle();
          await reach(tester, 'Bác chưa nhập tên gọi.');
          await reach(tester, 'Ví dụ: Lan');

          await tester.tap(find.text('Quay lại'));
          await tester.pumpAndSettle();
          await reach(tester, 'Bác chưa lưu thay đổi');
          await reach(tester, 'Bỏ thay đổi');
        });

        testWidgets('$label: N06 Loading + Error', (tester) async {
          setView(tester);
          await pumpRoute(tester, '/settings/profile',
              size: size,
              scale: scale,
              highContrast: highContrast,
              profileSetup: OddProfileSetupService(silent: true),
              settle: false);
          expect(find.byType(LoadingView), findsOneWidget);
          expect(tester.takeException(), isNull);

          await pumpRoute(tester, '/settings/profile',
              size: size,
              scale: scale,
              highContrast: highContrast,
              profileSetup: OddProfileSetupService(broken: true));
          expect(find.byType(ErrorView), findsOneWidget);
          await reach(tester, 'Thử lại');
        });

        testWidgets('$label: N08 + N20', (tester) async {
          setView(tester);
          await pumpRoute(tester, '/settings/help',
              size: size, scale: scale, highContrast: highContrast);
          expect(tester.takeException(), isNull);
          await reach(tester, 'Việc chỉ vào lịch khi Bác bấm nhận.');
          await reach(tester, 'Mở cài đặt');

          await pumpRoute(tester, '/settings/data',
              size: size, scale: scale, highContrast: highContrast);
          expect(tester.takeException(), isNull);
          await reach(
              tester, 'Chỉ người thân Bác đã ghép nối mới xem được lịch.');
          await reach(tester, 'Về Cài đặt');
        });
      }
    }
  }
}
