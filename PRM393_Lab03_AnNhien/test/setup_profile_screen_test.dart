import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/screens/onboarding/setup_profile_screen.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/settings_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F2 bước 03: S02 Thiết lập hồ sơ – 3 state cùng route `/setup`.
void main() {
  late FakeProfileSetupService setup;

  Future<void> pumpSetup(WidgetTester tester,
      {String? displayName = 'Lan',
      bool failOnSave = false,
      double width = 360,
      double textScale = 1.0}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    setup =
        FakeProfileSetupService(failOnSave: failOnSave, delay: Duration.zero);
    final container = ProviderContainer(overrides: [
      settingsServiceProvider
          .overrideWithValue(FakeSettingsService(delay: Duration.zero)),
      authServiceProvider.overrideWithValue(FakeAuthService(
          signedIn: AppUser(uid: 'u1', displayName: displayName))),
      profileSetupServiceProvider.overrideWithValue(setup),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/setup', routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const Text('S01')),
      GoRoute(path: '/setup', builder: (_, __) => const SetupProfileScreen()),
      GoRoute(
          path: '/setup/notifications', builder: (_, __) => const Text('S13')),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  void expectOnScreen(WidgetTester tester, String text) {
    final rect = tester.getRect(find.text(text));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(800));
  }

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.3, 2.0]) {
      testWidgets('$width dp × $scale: 3 state không tràn, nút đáy luôn thấy',
          (tester) async {
        await pumpSetup(tester, width: width, textScale: scale);

        // Xác nhận tên (1:58).
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Đúng rồi');
        expectOnScreen(tester, 'Nhập lại tên');

        // Nhập lại tên (1:176) + lỗi tên trống.
        await tester.tap(find.text('Nhập lại tên'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '');
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Tiếp tục');

        // Giới thiệu về Bác (1:103).
        await tester.enterText(find.byType(TextField), 'Lan');
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();
        expect(find.text('Giới thiệu về Bác'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expectOnScreen(tester, 'Tiếp tục');
        await tester.scrollUntilVisible(find.text('6:00 sáng'), 100);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('có tên Google → hỏi lại tên; "Đúng rồi" → phần chi tiết',
      (tester) async {
    await pumpSetup(tester);
    expect(find.text('Bác là Lan, đúng không?'), findsOneWidget);
    expect(find.text('Bước 1/2'), findsOneWidget);
    await tester.tap(find.text('Đúng rồi'));
    await tester.pumpAndSettle();
    expect(find.text('Giới thiệu về Bác'), findsOneWidget);
    expect(find.text('Ông'), findsOneWidget);
    expect(find.text('Bà'), findsOneWidget);
  });

  testWidgets('không có tên gợi ý → ô nhập; tên trống báo lỗi có liveRegion',
      (tester) async {
    await pumpSetup(tester, displayName: null);
    expect(find.text('Bác tên là gì?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    const error = 'Bác chưa nhập tên gọi.';
    expect(find.text(error), findsOneWidget);
    expect(find.text('Ví dụ: Lan, Sáu, Tư'), findsOneWidget);
    expect(
        find.ancestor(
            of: find.text(error),
            matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.liveRegion == true)),
        findsOneWidget);
  });

  testWidgets('"Tiếp tục" lưu được → /setup/notifications', (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Đúng rồi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bà'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('S13'), findsOneWidget);
    expect(setup.saved['u1']?.honorific, Honorific.ba);
  });

  testWidgets('lưu lỗi → hiện lỗi + "Thử lại", giữ lựa chọn', (tester) async {
    await pumpSetup(tester, failOnSave: true);
    await tester.tap(find.text('Đúng rồi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bà'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chưa lưu được'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Giới thiệu về Bác'), findsOneWidget);

    setup.failOnSave = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('S13'), findsOneWidget);
    expect(setup.saved['u1']?.honorific, Honorific.ba);
  });

  testWidgets('chạm ô giờ → mở DLG-WakeTime', (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Đúng rồi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6:00 sáng'));
    await tester.pumpAndSettle();
    expect(find.text('Bác thường thức dậy lúc mấy giờ?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Quay lại" → /welcome', (tester) async {
    await pumpSetup(tester);
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('S01'), findsOneWidget);
  });
}
