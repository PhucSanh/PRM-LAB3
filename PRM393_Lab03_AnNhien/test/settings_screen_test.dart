import 'package:an_nhien/models/app_settings.dart';
import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/screens/settings/settings_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/session_data_service.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/display_settings_sync.dart';
import 'package:an_nhien/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F8 bước 02: S10 Cài đặt hiển thị (`/settings`).
class BrokenSettingsService extends FakeSettingsService {
  BrokenSettingsService() : super(delay: Duration.zero);
  bool broken = true;

  @override
  Stream<AppSettings> watch() => broken
      ? Stream.error(const AppException('Chưa tải được cài đặt.'))
      : super.watch();
}

/// Đếm số lần đăng xuất.
class CountingAuthService extends FakeAuthService {
  CountingAuthService() : super(signedIn: const AppUser(uid: 'u1'));
  int signOutCount = 0;

  @override
  Future<void> signOut() {
    signOutCount++;
    return super.signOut();
  }
}

/// Dựng lại đúng phần `app.dart` dùng để áp cỡ chữ + tương phản cao (không kéo
/// Firebase vào test): theme theo `highContrastProvider`, `textScaler` =
/// cỡ hệ thống × cỡ Bác chọn, trần 2.0.
class _TestApp extends ConsumerWidget {
  const _TestApp({required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(displaySettingsSyncProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final highContrast = ref.watch(highContrastProvider);
    return MaterialApp.router(
      theme: highContrast ? AppTheme.highContrast() : AppTheme.light(),
      routerConfig: router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scale = (media.textScaler.scale(1) * fontScale.factor)
            .clamp(1.0, maxTextScale);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
  }
}

void main() {
  late FakeSettingsService settings;
  late CountingAuthService auth;
  late FakeSessionDataService session;
  late GoRouter router;

  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    FakeSettingsService? service,
    double width = 360,
    double systemScale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = systemScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    settings = service ?? FakeSettingsService(delay: Duration.zero);
    auth = CountingAuthService();
    session = FakeSessionDataService();
    final container = ProviderContainer(overrides: [
      settingsServiceProvider.overrideWithValue(settings),
      authServiceProvider.overrideWithValue(auth),
      sessionDataServiceProvider.overrideWithValue(session),
      analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    router = GoRouter(initialLocation: '/settings', routes: [
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const Text('A01')),
      GoRoute(path: '/settings/help', builder: (_, __) => const Text('N08')),
      GoRoute(path: '/settings/profile', builder: (_, __) => const Text('N06')),
      GoRoute(
          path: '/settings/reminders', builder: (_, __) => const Text('N07')),
      GoRoute(path: '/settings/data', builder: (_, __) => const Text('N20')),
      GoRoute(
          path: '/reminder/:taskId',
          builder: (_, state) =>
              Text('S14 ${state.uri.queryParameters['preview']}')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: _TestApp(router: router)));
    await tester.pumpAndSettle();
    return container;
  }

  double appScale(WidgetTester tester) =>
      MediaQuery.textScalerOf(tester.element(find.text('Cài đặt hiển thị')))
          .scale(1);

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('vẽ đủ phần S10 với giá trị đã lưu', (tester) async {
    await pumpSettings(tester);
    expect(find.text('Quay lại'), findsOneWidget);
    expect(find.text('Cài đặt hiển thị'), findsOneWidget);
    for (final text in [
      'Vừa',
      'Lớn',
      'Rất lớn',
      'Đi bộ 20 phút lúc 9:30 sáng',
      'Chữ và nền rõ hơn',
      'Đọc to nội dung',
      'Rung khi có lời nhắc',
      'Xem thử lời nhắc',
      'Cách dùng đơn giản',
      'Thông tin của Bác',
      'Lời nhắc',
      'Dữ liệu trên điện thoại',
      'Đăng xuất',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
  });

  testWidgets('chạm "Rất lớn" → textScaler cả app đổi; Hoàn tác trả lại',
      (tester) async {
    final c = await pumpSettings(tester);
    expect(appScale(tester), closeTo(1.15, 0.001));

    await tapText(tester, 'Rất lớn');
    expect(appScale(tester), closeTo(1.3, 0.001));
    expect(c.read(fontScaleProvider), AppFontScale.ratLon);
    expect(settings.current.fontScale, AppFontScale.ratLon);
    expect(find.text('Đã đổi cỡ chữ sang Rất lớn.'), findsOneWidget);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(appScale(tester), closeTo(1.15, 0.001));
    expect(settings.current.fontScale, AppFontScale.lon);
  });

  testWidgets('bật tương phản cao → theme đổi ngay; Hoàn tác tắt lại',
      (tester) async {
    await pumpSettings(tester);
    ColorScheme scheme() =>
        Theme.of(tester.element(find.text('Cài đặt hiển thị'))).colorScheme;
    expect(scheme().onSurface, AppTheme.colorScheme.onSurface);

    await tapText(tester, 'Chữ và nền rõ hơn');
    expect(scheme().onSurface, AppTheme.highContrastScheme.onSurface);
    expect(settings.current.highContrast, isTrue);
    expect(find.text('Đã bật chữ và nền rõ hơn.'), findsOneWidget);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(scheme().onSurface, AppTheme.colorScheme.onSurface);
    expect(settings.current.highContrast, isFalse);
  });

  testWidgets('lưu lỗi: vẫn đổi trên máy, Snackbar có câu báo nhẹ',
      (tester) async {
    await pumpSettings(tester,
        service: FakeSettingsService(failOnSave: true, delay: Duration.zero));
    await tapText(tester, 'Đọc to nội dung');
    expect(find.text('Đã bật đọc to nội dung.'), findsOneWidget);
    expect(
        find.text('Chưa lưu được cài đặt. Bác thử lại nhé.'), findsOneWidget);
    expect(find.text('Đang bật'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fake lỗi → ErrorView + "Thử lại" → Data', (tester) async {
    final broken = BrokenSettingsService();
    await pumpSettings(tester, service: broken);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Chưa tải được cài đặt.'), findsOneWidget);

    broken.broken = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Cài đặt hiển thị'), findsOneWidget);
  });

  testWidgets('4 hàng + Xem thử lời nhắc điều hướng đúng route',
      (tester) async {
    await pumpSettings(tester);
    for (final (label, target) in [
      ('Cách dùng đơn giản', 'N08'),
      ('Thông tin của Bác', 'N06'),
      ('Lời nhắc', 'N07'),
      ('Dữ liệu trên điện thoại', 'N20'),
      ('Xem thử lời nhắc', 'S14 true'),
    ]) {
      await tapText(tester, label);
      expect(find.text(target), findsOneWidget, reason: label);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Đăng xuất hỏi lại; "Ở lại" không gọi signOut', (tester) async {
    await pumpSettings(tester);
    await tapText(tester, 'Đăng xuất');
    expect(find.text('Bác muốn đăng xuất?'), findsOneWidget);

    await tester.ensureVisible(find.text('Ở lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ở lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bác muốn đăng xuất?'), findsNothing);
    expect(auth.signOutCount, 0);
    expect(session.clearCount, 0);
  });

  testWidgets('Đăng xuất → xác nhận → signOut + về A01', (tester) async {
    await pumpSettings(tester);
    await tapText(tester, 'Đăng xuất');
    final confirm = find.descendant(
        of: find.byType(Dialog), matching: find.text('Đăng xuất'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(auth.signOutCount, 1);
    expect(auth.currentUser, isNull);
    expect(find.text('A01'), findsOneWidget);
  });

  for (final width in [360.0, 412.0]) {
    for (final font in [AppFontScale.ratLon, AppFontScale.vua]) {
      // ratLon × 1.0 = 1.3; vua × 2.0 = 2.0 (trần).
      final systemScale = font == AppFontScale.vua ? 2.0 : 1.0;
      for (final highContrast in [false, true]) {
        testWidgets(
            '$width dp · chữ ×${(font.factor * systemScale).toStringAsFixed(1)}'
            '${highContrast ? ' · tương phản cao' : ''}: không tràn',
            (tester) async {
          await pumpSettings(tester,
              width: width,
              systemScale: systemScale,
              service: FakeSettingsService(
                  initial:
                      AppSettings(fontScale: font, highContrast: highContrast),
                  delay: Duration.zero));
          expect(tester.takeException(), isNull);

          // Cuộn tới cuối: mọi phần vẽ được, không lỗi tràn.
          await tester.ensureVisible(find.text('Đăng xuất'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Hộp hỏi đăng xuất cũng không tràn.
          await tester.tap(find.text('Đăng xuất'));
          await tester.pumpAndSettle();
          expect(find.text('Bác muốn đăng xuất?'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
