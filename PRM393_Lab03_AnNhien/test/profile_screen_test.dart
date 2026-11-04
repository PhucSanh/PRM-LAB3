import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/screens/settings/profile_screen.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F8 bước 03: N06 Thông tin của Bác (`/settings/profile`).

/// `FakeProfileService.watch` dùng `Stream.multi` + `onCancel` trả Future ở
/// root zone nên `.first` treo trong `testWidgets`; bản này phát `Stream.value`.
class _StaticProfileService extends FakeProfileService {
  _StaticProfileService()
      : super(const [
          UserProfile(uid: 'u1', displayName: 'Lan', role: UserRole.elder),
        ]);

  @override
  Stream<UserProfile> watch(String uid) => Stream.value(
      const UserProfile(uid: 'u1', displayName: 'Lan', role: UserRole.elder));
}

const _lan = ProfileSetup(
    displayName: 'Lan', honorific: Honorific.ba, wakeHour: 5, wakeMinute: 30);

void main() {
  late FakeProfileSetupService setup;
  late GoRouter router;

  Future<void> pumpProfile(
    WidgetTester tester, {
    double width = 360,
    double textScale = 1.15,
    bool highContrast = false,
    bool failOnSave = false,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    setup = FakeProfileSetupService(
        delay: Duration.zero, failOnSave: failOnSave, seed: const {'u1': _lan});
    final container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(
          FakeAuthService(signedIn: const AppUser(uid: 'u1'))),
      profileServiceProvider.overrideWithValue(_StaticProfileService()),
      profileSetupServiceProvider.overrideWithValue(setup),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(container.dispose);
    router = GoRouter(initialLocation: '/settings', routes: [
      // S10 thật có Scaffold → Snackbar Hoàn tác hiện được sau khi quay về.
      GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('S10'))),
      GoRoute(
          path: '/settings/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: '/settings/firebase-demo',
          builder: (_, __) => const Text('F10 demo')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: highContrast ? AppTheme.highContrast() : AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    router.push('/settings/profile');
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder nameField() => find.byType(TextField);

  testWidgets('vẽ form với giá trị đã lưu + lối vào khu thử tính năng',
      (tester) async {
    await pumpProfile(tester);
    expect(find.text('Thông tin của Bác'), findsOneWidget);
    expect(find.text('Bác đổi lại khi cần nhé.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Lan'), findsOneWidget);
    expect(find.text('Ví dụ: Lan'), findsOneWidget);
    expect(find.text('Đang chọn: Bà'), findsOneWidget);
    expect(find.text('5:30 sáng'), findsOneWidget);
    expect(find.text('Việc đã lưu vẫn giữ giờ cũ.'), findsOneWidget);
    expect(find.text('Lưu thông tin'), findsOneWidget);
    expect(find.text('Hủy'), findsOneWidget);

    await tapText(tester, 'Khu thử tính năng');
    expect(find.text('F10 demo'), findsOneWidget);
  });

  testWidgets('chưa sửa gì: Quay lại rời màn ngay, không hỏi', (tester) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bác chưa lưu thay đổi'), findsNothing);
    expect(find.text('S10'), findsOneWidget);
  });

  testWidgets('sửa tên rồi bấm Quay lại → hỏi; "Ở lại sửa" giữ chữ đã gõ',
      (tester) async {
    await pumpProfile(tester);
    await tester.enterText(nameField(), 'Lan Anh');
    await tester.pump();
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bác chưa lưu thay đổi'), findsOneWidget);

    await tapText(tester, 'Ở lại sửa');
    expect(find.text('Bác chưa lưu thay đổi'), findsNothing);
    expect(find.widgetWithText(TextField, 'Lan Anh'), findsOneWidget);
  });

  testWidgets('"Bỏ thay đổi" rời màn, không lưu', (tester) async {
    await pumpProfile(tester);
    await tester.enterText(nameField(), 'Lan Anh');
    await tester.pump();
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Bỏ thay đổi');
    expect(find.text('S10'), findsOneWidget);
    expect(setup.saved['u1']!.toMap(), _lan.toMap());
  });

  testWidgets('back hệ thống khi đã sửa cũng hỏi lại', (tester) async {
    await pumpProfile(tester);
    await tester.enterText(nameField(), 'Lan Anh');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bác chưa lưu thay đổi'), findsOneWidget);
  });

  testWidgets('Hủy khi đã sửa cũng hỏi lại', (tester) async {
    await pumpProfile(tester);
    await tester.enterText(nameField(), 'Lan Anh');
    await tester.pump();
    await tapText(tester, 'Hủy');
    expect(find.text('Bác chưa lưu thay đổi'), findsOneWidget);
  });

  testWidgets('tên trống → lỗi có icon + "Ví dụ: Lan", không lưu',
      (tester) async {
    await pumpProfile(tester);
    await tester.enterText(nameField(), '');
    await tester.pump();
    await tapText(tester, 'Lưu thông tin');
    expect(find.text('Bác chưa nhập tên gọi.'), findsOneWidget);
    expect(find.text('Ví dụ: Lan'), findsOneWidget);
    expect(setup.saved['u1']!.toMap(), _lan.toMap());
    expect(find.text('S10'), findsNothing);
  });

  testWidgets('Lưu thông tin → Snackbar, về S10; Hoàn tác lưu lại bản cũ',
      (tester) async {
    await pumpProfile(tester);
    await tester.enterText(nameField(), 'Lan Anh');
    await tester.pump();
    await tapText(tester, 'Ông');
    await tapText(tester, 'Lưu thông tin');

    expect(setup.saved['u1']!.displayName, 'Lan Anh');
    expect(setup.saved['u1']!.honorific, Honorific.ong);
    expect(find.text('S10'), findsOneWidget);
    expect(find.text('Đã lưu thông tin của Bác.'), findsOneWidget);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(setup.saved['u1']!.toMap(), _lan.toMap());
  });

  testWidgets('lưu lỗi → câu lỗi trên nút, ở lại màn, giữ chữ đã gõ',
      (tester) async {
    await pumpProfile(tester, failOnSave: true);
    await tester.enterText(nameField(), 'Lan Anh');
    await tester.pump();
    await tapText(tester, 'Lưu thông tin');
    expect(find.text('Chưa lưu được. Bác kiểm tra mạng rồi thử lại nhé.'),
        findsOneWidget);
    expect(find.widgetWithText(TextField, 'Lan Anh'), findsOneWidget);
    expect(find.text('S10'), findsNothing);
  });

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.3, 2.0]) {
      for (final highContrast in [false, true]) {
        testWidgets(
            '$width dp × $scale${highContrast ? ' · tương phản cao' : ''}: '
            'không tràn, bàn phím mở vẫn thấy nút Lưu', (tester) async {
          await pumpProfile(tester,
              width: width, textScale: scale, highContrast: highContrast);
          expect(tester.takeException(), isNull);

          // Cuộn tới cuối: mọi phần vẽ được.
          await tester.ensureVisible(find.text('Khu thử tính năng'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Bàn phím mở (300 dp): nút Lưu vẫn nằm trên bàn phím.
          await tester.ensureVisible(nameField());
          await tester.pumpAndSettle();
          await tester.showKeyboard(nameField());
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final save = tester.getRect(find.text('Lưu thông tin'));
          expect(save.bottom, lessThanOrEqualTo(800 - 300));

          // Hộp hỏi bỏ thay đổi cũng không tràn.
          tester.view.resetViewInsets();
          await tester.enterText(nameField(), 'Lan Anh');
          await tester.tap(find.text('Quay lại'));
          await tester.pumpAndSettle();
          expect(find.text('Bác chưa lưu thay đổi'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
