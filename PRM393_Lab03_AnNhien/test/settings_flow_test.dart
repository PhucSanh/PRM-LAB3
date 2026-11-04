import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/screens/settings/data_screen.dart';
import 'package:an_nhien/screens/settings/help_screen.dart';
import 'package:an_nhien/screens/settings/profile_screen.dart';
import 'package:an_nhien/screens/settings/settings_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/messaging_service.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/session_data_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F8 bước 05: cả luồng Cài đặt trên `AnNhienApp` **thật** (theme + `textScaler`
/// + `displaySettingsSyncProvider` trong `app.dart`), mọi service bằng Fake.
/// Router test có đủ 4 route F8 thật; `/today`, `/sign-in`, `/reminder/:id` giả.

/// Ghi lại cả tham số event (FakeAnalyticsService chỉ ghi tên).
class RecordingAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async =>
      events.add((name, params));

  @override
  Future<void> setUserId(String? uid) async {}

  List<Map<String, Object>?> paramsOf(String name) => [
        for (final (n, p) in events)
          if (n == name) p
      ];
}

/// Đếm số lần đăng xuất.
class CountingAuthService extends FakeAuthService {
  CountingAuthService()
      : super(signedIn: const AppUser(uid: 'u1', displayName: 'Lan'));
  int signOutCount = 0;

  @override
  Future<void> signOut() {
    signOutCount++;
    return super.signOut();
  }
}

/// `FakeProfileService.watch` dùng `Stream.multi` + `onCancel` trả Future ở
/// root zone nên `.first` treo trong `testWidgets` (đã nhờ Hiếu sửa).
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
  late FakeSettingsService settings;
  late FakeProfileSetupService profileSetup;
  late CountingAuthService auth;
  late RecordingAnalytics analytics;
  late GoRouter router;
  late ProviderContainer container;

  /// Mở app (lần đầu hoặc "mở lại") với **cùng** Fake cài đặt / hồ sơ.
  Future<void> openApp(WidgetTester tester) async {
    auth = CountingAuthService();
    analytics = RecordingAnalytics();
    router = GoRouter(initialLocation: '/today', routes: [
      GoRoute(
          path: '/today',
          builder: (_, __) => const Scaffold(body: Text('S03 Hôm nay'))),
      GoRoute(
          path: '/sign-in',
          builder: (_, __) => const Scaffold(body: Text('A01 Đăng nhập'))),
      GoRoute(
          path: '/reminder/:taskId',
          builder: (_, __) => const Scaffold(body: Text('S14'))),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/settings/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/settings/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/settings/data', builder: (_, __) => const DataScreen()),
      GoRoute(
          path: '/settings/reminders',
          builder: (_, __) => const Scaffold(body: Text('N07'))),
      GoRoute(
          path: '/settings/firebase-demo',
          builder: (_, __) => const Scaffold(body: Text('F10 demo'))),
    ]);
    container = ProviderContainer(overrides: [
      routerProvider.overrideWithValue(router),
      messagingServiceProvider.overrideWithValue(FakeMessagingService()),
      authServiceProvider.overrideWithValue(auth),
      sessionDataServiceProvider.overrideWithValue(FakeSessionDataService()),
      settingsServiceProvider.overrideWithValue(settings),
      profileServiceProvider.overrideWithValue(StaticProfileService()),
      profileSetupServiceProvider.overrideWithValue(profileSetup),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pumpAndSettle();
  }

  /// "Đóng app": gỡ cây widget + huỷ container (Fake vẫn giữ dữ liệu đã lưu).
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    router.dispose();
  }

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    settings = FakeSettingsService(delay: Duration.zero);
    profileSetup =
        FakeProfileSetupService(delay: Duration.zero, seed: const {'u1': _lan});
    await openApp(tester);
    addTearDown(() {
      container.dispose();
      router.dispose();
    });
  }

  Future<void> go(WidgetTester tester, String path) async {
    router.push(path);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  double scaleAt(WidgetTester tester, String text) =>
      MediaQuery.textScalerOf(tester.element(find.text(text).first)).scale(1);

  ColorScheme schemeAt(WidgetTester tester, String text) =>
      Theme.of(tester.element(find.text(text).first)).colorScheme;

  testWidgets(
      '"Xong khi": chọn Rất lớn → cả app ×1.3, mở lại app vẫn ×1.3; '
      'change_font_size đúng from / to, không có tên Bác', (tester) async {
    await start(tester);
    expect(scaleAt(tester, 'S03 Hôm nay'), closeTo(1.15, 0.001));

    await go(tester, '/settings');
    await tapText(tester, 'Rất lớn');
    expect(scaleAt(tester, 'Cài đặt hiển thị'), closeTo(1.3, 0.001));

    // Về Hôm nay: chữ vẫn ×1.3.
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('S03 Hôm nay'), findsOneWidget);
    expect(scaleAt(tester, 'S03 Hôm nay'), closeTo(1.3, 0.001));

    expect(analytics.paramsOf('change_font_size'), [
      {'from': 'lon', 'to': 'rat_lon'}
    ]);
    for (final (_, params) in analytics.events) {
      for (final value in params?.values ?? const <Object>[]) {
        expect('$value', isNot(contains('Lan')));
      }
    }

    // Mở lại app (không qua S01): cài đặt đã lưu được áp ngay.
    await closeApp(tester);
    await openApp(tester);
    expect(find.text('S03 Hôm nay'), findsOneWidget);
    expect(scaleAt(tester, 'S03 Hôm nay'), closeTo(1.3, 0.001));
  });

  testWidgets('tương phản cao: bật → cả app đổi; Hoàn tác → tắt lại',
      (tester) async {
    await start(tester);
    await go(tester, '/settings');
    await tapText(tester, 'Chữ và nền rõ hơn');
    expect(schemeAt(tester, 'Cài đặt hiển thị').onSurface,
        AppTheme.highContrastScheme.onSurface);
    expect(settings.current.highContrast, isTrue);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(schemeAt(tester, 'Cài đặt hiển thị').onSurface,
        AppTheme.colorScheme.onSurface);
    expect(settings.current.highContrast, isFalse);

    // Về Hôm nay vẫn là giao diện thường.
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(schemeAt(tester, 'S03 Hôm nay').onSurface,
        AppTheme.colorScheme.onSurface);
  });

  testWidgets(
      'S10 → N06 (sửa tên, lưu, Hoàn tác) → S10 → N08 → S10 → N20 → S10',
      (tester) async {
    await start(tester);
    await go(tester, '/settings');

    await tapText(tester, 'Thông tin của Bác');
    expect(find.text('Bác đổi lại khi cần nhé.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Lan Anh');
    await tester.pump();
    await tapText(tester, 'Lưu thông tin');
    expect(find.text('Cài đặt hiển thị'), findsOneWidget);
    expect(profileSetup.saved['u1']!.displayName, 'Lan Anh');
    expect(find.text('Đã lưu thông tin của Bác.'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(profileSetup.saved['u1']!.displayName, 'Lan');

    await tapText(tester, 'Cách dùng đơn giản');
    expect(find.text('Ba bước nhẹ nhàng để bắt đầu mỗi ngày cùng An Nhiên.'),
        findsOneWidget);
    await tapText(tester, 'Mở cài đặt');
    expect(find.text('Cài đặt hiển thị'), findsOneWidget);

    await tapText(tester, 'Dữ liệu trên điện thoại');
    expect(find.text('Lịch của Bác được lưu trên tài khoản Google của Bác.'),
        findsOneWidget);
    await tapText(tester, 'Về Cài đặt');
    expect(find.text('Cài đặt hiển thị'), findsOneWidget);
  });

  testWidgets(
      'Đăng xuất: "Ở lại" không đăng xuất; xác nhận → signOut, '
      'logout đúng 1 lần, về A01', (tester) async {
    await start(tester);
    await go(tester, '/settings');

    await tapText(tester, 'Đăng xuất');
    expect(find.text('Bác muốn đăng xuất?'), findsOneWidget);
    await tapText(tester, 'Ở lại');
    expect(auth.signOutCount, 0);
    expect(auth.currentUser, isNotNull);
    expect(analytics.paramsOf('logout'), isEmpty);

    await tapText(tester, 'Đăng xuất');
    final confirm = find.descendant(
        of: find.byType(Dialog), matching: find.text('Đăng xuất'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(auth.signOutCount, 1);
    expect(auth.currentUser, isNull);
    expect(analytics.paramsOf('logout').length, 1);
    expect(find.text('A01 Đăng nhập'), findsOneWidget);
  });
}
