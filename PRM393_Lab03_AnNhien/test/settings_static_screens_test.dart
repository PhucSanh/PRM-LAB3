import 'package:an_nhien/screens/settings/data_screen.dart';
import 'package:an_nhien/screens/settings/help_screen.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F8 bước 04: N08 Cách dùng đơn giản + N20 Dữ liệu trên điện thoại (màn tĩnh).
void main() {
  late GoRouter router;

  Future<void> pumpAt(
    WidgetTester tester,
    String path, {
    double width = 360,
    double textScale = 1.15,
    bool highContrast = false,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(initialLocation: '/settings', routes: [
      GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('S10'))),
      GoRoute(path: '/settings/help', builder: (_, __) => const HelpScreen()),
      GoRoute(path: '/settings/data', builder: (_, __) => const DataScreen()),
      GoRoute(
          path: '/reminder/:taskId',
          builder: (_, state) => Scaffold(
              body: Text('S14 ${state.pathParameters['taskId']} '
                  '${state.uri.queryParameters['preview']}'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      theme: highContrast ? AppTheme.highContrast() : AppTheme.light(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ));
    await tester.pumpAndSettle();
    router.push(path);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// Nút ghim ở đáy luôn nằm trong màn 800 dp, không cần cuộn.
  void expectPinned(WidgetTester tester, String text) {
    final rect = tester.getRect(find.text(text));
    expect(rect.top, greaterThanOrEqualTo(0), reason: text);
    expect(rect.bottom, lessThanOrEqualTo(800), reason: text);
  }

  group('N08 Cách dùng đơn giản', () {
    testWidgets('có tiêu đề, 3 bước, câu về gợi ý lịch, 2 nút', (tester) async {
      await pumpAt(tester, '/settings/help');
      for (final text in [
        'Quay lại',
        'Cách dùng đơn giản',
        'Ba bước nhẹ nhàng để bắt đầu mỗi ngày cùng An Nhiên.',
        'Chọn việc',
        'Nhắc nhẹ nhàng',
        'Gần gũi người thân',
        'Con cháu gửi gợi ý lịch. Bác chọn nhận hoặc bỏ qua.',
        'Bác tự chọn nhận gợi ý lịch.',
        'Việc chỉ vào lịch khi Bác bấm nhận.',
        'Thử lời nhắc',
        'Mở cài đặt',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(
          find.bySemanticsLabel(RegExp(r'^Bước 1: Chọn việc')), findsOneWidget);
    });

    testWidgets('"Thử lời nhắc" → /reminder/preview?preview=true',
        (tester) async {
      await pumpAt(tester, '/settings/help');
      await tapText(tester, 'Thử lời nhắc');
      expect(find.text('S14 preview true'), findsOneWidget);
    });

    testWidgets('"Mở cài đặt" → về S10', (tester) async {
      await pumpAt(tester, '/settings/help');
      await tapText(tester, 'Mở cài đặt');
      expect(find.text('S10'), findsOneWidget);
    });
  });

  group('N20 Dữ liệu trên điện thoại', () {
    testWidgets('câu chữ đúng Lab 3 (DT-30), không còn "chỉ ở điện thoại này"',
        (tester) async {
      await pumpAt(tester, '/settings/data');
      for (final text in [
        'Dữ liệu trên điện thoại',
        'Lịch của Bác được lưu trên tài khoản Google của Bác.',
        'Dùng được khi mất mạng',
        'Mất mạng, Bác vẫn xem được lịch đã tải về máy.',
        'Đổi điện thoại vẫn còn lịch',
        'Bác đăng nhập lại là thấy lịch cũ.',
        'Chia sẻ do Bác quyết định',
        'Chỉ người thân Bác đã ghép nối mới xem được lịch.',
        'Về Cài đặt',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.textContaining('chỉ ở điện thoại này'), findsNothing);
      expect(find.textContaining('chưa chuyển sang máy khác'), findsNothing);
    });

    testWidgets('"Về Cài đặt" → về S10', (tester) async {
      await pumpAt(tester, '/settings/data');
      await tapText(tester, 'Về Cài đặt');
      expect(find.text('S10'), findsOneWidget);
    });
  });

  for (final (path, lastText, buttons) in [
    (
      '/settings/help',
      'Việc chỉ vào lịch khi Bác bấm nhận.',
      ['Thử lời nhắc', 'Mở cài đặt']
    ),
    (
      '/settings/data',
      'Chỉ người thân Bác đã ghép nối mới xem được lịch.',
      ['Về Cài đặt']
    ),
  ]) {
    for (final width in [360.0, 412.0]) {
      for (final scale in [1.3, 2.0]) {
        for (final highContrast in [false, true]) {
          testWidgets(
              '$path · $width dp × $scale'
              '${highContrast ? ' · tương phản cao' : ''}: không tràn, '
              'nút đáy luôn thấy', (tester) async {
            await pumpAt(tester, path,
                width: width, textScale: scale, highContrast: highContrast);
            expect(tester.takeException(), isNull);
            for (final b in buttons) {
              expectPinned(tester, b);
            }

            // Cuộn tới cuối nội dung: vẽ được, nút đáy vẫn đứng yên.
            await tester.ensureVisible(find.text(lastText));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            for (final b in buttons) {
              expectPinned(tester, b);
            }
          });
        }
      }
    }
  }
}
