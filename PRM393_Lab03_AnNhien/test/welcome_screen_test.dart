import 'package:an_nhien/screens/onboarding/welcome_screen.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F2 bước 02: S01 Chào mừng – chọn cỡ chữ.
void main() {
  late FakeSettingsService settings;

  Future<ProviderContainer> pumpWelcome(WidgetTester tester,
      {double width = 360, double textScale = 1.0}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    settings = FakeSettingsService(delay: Duration.zero);
    final container = ProviderContainer(overrides: [
      settingsServiceProvider.overrideWithValue(settings),
      authServiceProvider.overrideWithValue(FakeAuthService()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/welcome', routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const Text('S02')),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        // Như app.dart nhưng ép đúng hệ số cần kiểm tra.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openFontOptions(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Cỡ chữ'));
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.3, maxTextScale]) {
      testWidgets('$width dp × $scale: không tràn, nút "Bắt đầu" luôn thấy',
          (tester) async {
        await pumpWelcome(tester, width: width, textScale: scale);
        expect(tester.takeException(), isNull);

        final button = tester.getRect(find.text('Bắt đầu'));
        expect(button.bottom, lessThanOrEqualTo(800));
        expect(button.top, greaterThanOrEqualTo(0));

        await openFontOptions(tester);
        // Cuộn tới lựa chọn cuối vẫn chạm được.
        await tester.scrollUntilVisible(find.text('Rất lớn'), 100,
            scrollable: find.byType(Scrollable).last);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('mặc định "Lớn", không có nút Quay lại', (tester) async {
    final c = await pumpWelcome(tester);
    expect(c.read(fontScaleProvider), AppFontScale.lon);
    await openFontOptions(tester);
    expect(find.text('Đang chọn'), findsOneWidget);
    expect(find.text('Quay lại'), findsNothing);
  });

  testWidgets('chạm "Rất lớn" → chữ toàn app đổi ngay và được lưu',
      (tester) async {
    final c = await pumpWelcome(tester);
    await openFontOptions(tester);
    await tester.scrollUntilVisible(find.text('Rất lớn'), 100,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Rất lớn'));
    await tester.pumpAndSettle();
    expect(c.read(fontScaleProvider), AppFontScale.ratLon);
    expect(settings.current.fontScale, AppFontScale.ratLon);
  });

  testWidgets('"Bắt đầu" → /setup', (tester) async {
    await pumpWelcome(tester);
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(find.text('S02'), findsOneWidget);
  });
}
