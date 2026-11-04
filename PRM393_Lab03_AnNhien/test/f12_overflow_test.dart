import 'package:an_nhien/screens/suggestion/suggestion_compose_screen.dart';
import 'package:an_nhien/screens/suggestion/suggestion_review_screen.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/suggestion_review_view_model.dart';
import 'package:an_nhien/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'f12_compose_test.dart' as compose;
import 'f12_inbox_popup_test.dart' as inbox;
import 'f12_review_test.dart' as review;

/// F12 bước 06: mọi state F12 ở 360×800 / 412×915, chữ ×1.0 / 1.3 / 2.0, giao diện thường / tương phản
/// cao – không tràn (Flutter báo lỗi tràn qua `takeException`), nút chính luôn bấm được.
Future<void> pumpRoute(
    WidgetTester tester, ProviderContainer container, GoRouter router,
    {required Size size,
    required double scale,
    required ThemeData theme}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: theme,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> step(WidgetTester tester, Finder f, String state) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: state);
}

void noOverflow(WidgetTester tester, String state) =>
    expect(tester.takeException(), isNull, reason: state);

GoRouter reviewRouter() =>
    GoRouter(initialLocation: '/today/suggestions/g1?from=card', routes: [
      GoRoute(path: '/today', builder: (_, __) => const Text('S03'), routes: [
        GoRoute(
            path: 'suggestions/:id',
            builder: (_, s) => SuggestionReviewScreen(
                id: s.pathParameters['id']!,
                entry:
                    SuggestionEntry.fromQuery(s.uri.queryParameters['from']))),
      ]),
      GoRoute(path: '/week/:date', builder: (_, __) => const Text('S11')),
      GoRoute(path: '/family', builder: (_, __) => const Text('S09')),
    ]);

void main() {
  for (final size in const [Size(360, 800), Size(412, 915)]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      for (final (themeName, theme) in [
        ('thường', AppTheme.light()),
        ('tương phản cao', AppTheme.highContrast()),
      ]) {
        final tag =
            '${size.width.toInt()}×${size.height.toInt()} · ×$scale · $themeName';

        testWidgets('$tag: G01 → G01b → G02', (tester) async {
          addTearDown(tester.view.reset);
          final h = compose.Harness();
          addTearDown(h.dispose);
          final router =
              GoRouter(initialLocation: '/caregiver/suggest', routes: [
            GoRoute(
                path: '/caregiver/suggest',
                builder: (_, __) => const SuggestionComposeScreen()),
            GoRoute(
                path: '/caregiver/schedule',
                builder: (_, __) => const Text('C03')),
          ]);
          addTearDown(router.dispose);
          await pumpRoute(tester, h.container, router,
              size: size, scale: scale, theme: theme);
          noOverflow(tester, 'G01');
          await step(tester, find.text('9:00 sáng').first, 'G01 chọn giờ');
          await step(tester, find.text('Gửi gợi ý cho mẹ'), 'G01b');
          await step(tester, find.text('Gửi gợi ý'), 'G02');
          expect(find.text('Đã gửi gợi ý cho mẹ', skipOffstage: false),
              findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('$tag: G03 → G04 → G03b → G05b', (tester) async {
          addTearDown(tester.view.reset);
          final h = review.Harness();
          addTearDown(h.dispose);
          final router = reviewRouter();
          addTearDown(router.dispose);
          await pumpRoute(tester, h.container, router,
              size: size, scale: scale, theme: theme);
          noOverflow(tester, 'G03');
          await step(tester, find.text('Đổi giờ đi bộ nhẹ nhàng'), 'G04');
          await step(tester, find.text('9:00 sáng'), 'G04 chọn giờ');
          await step(tester, find.text('Lưu giờ mới'), 'G03b');
          await step(tester, find.text('Thêm vào lịch'), 'G05b');
          expect(find.text('Đã thêm vào lịch'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('$tag: G06 → G07 · G09', (tester) async {
          addTearDown(tester.view.reset);
          final h = review.Harness();
          addTearDown(h.dispose);
          final router = reviewRouter();
          addTearDown(router.dispose);
          await pumpRoute(tester, h.container, router,
              size: size, scale: scale, theme: theme);
          await step(tester, find.text('Bỏ qua gợi ý'), 'G09');
          await step(tester, find.widgetWithText(AppButton, 'Hoàn tác'),
              'G03 sau Hoàn tác');
          await step(tester, find.text('Chọn từng việc'), 'G06');
          await step(tester, find.text('Tiếp tục'), 'G06 → G05');
          await tester.pumpWidget(const SizedBox());

          final h2 = review.Harness();
          addTearDown(h2.dispose);
          final router2 = reviewRouter();
          addTearDown(router2.dispose);
          await pumpRoute(tester, h2.container, router2,
              size: size, scale: scale, theme: theme);
          await step(tester, find.text('Chọn từng việc'), 'G06');
          await step(tester, find.text('Thư giãn nhẹ nhàng'), 'G06 bỏ chọn');
          await step(tester, find.text('Tiếp tục'), 'G07');
          expect(find.text('1 việc đã nhận'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('$tag: popup G10 → thẻ G12', (tester) async {
          final app = inbox.App(inbox.seeded());
          await app.pump(tester,
              width: size.width,
              height: size.height,
              scale: scale,
              theme: theme);
          noOverflow(tester, 'G10');
          expect(inbox.popup, findsOneWidget);
          await step(tester, inbox.inPopup('Để sau'), 'G12');
          expect(find.text('Mai gửi Bác 2 việc'), findsOneWidget);
          await app.close(tester);
        });
      }
    }
  }
}
