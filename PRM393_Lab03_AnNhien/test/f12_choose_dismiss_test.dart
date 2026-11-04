import 'package:an_nhien/models/suggestion.dart';
import 'package:an_nhien/screens/suggestion/suggestion_review_screen.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/suggestion_review_view_model.dart';
import 'package:an_nhien/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'f12_review_test.dart' show Harness, momUid;

/// F12 bước 04: G06 chọn từng việc → G07 / G07b; G03 bỏ qua → G09 → Hoàn tác.
void main() {
  group('SuggestionReviewViewModel – chọn từng việc', () {
    late Harness h;
    setUp(() => h = Harness());
    tearDown(() => h.dispose());

    test('"Chọn từng việc" → G06, mặc định chọn hết; "Quay lại" → G03',
        () async {
      await h.ready();
      h.vm.startChoosing();
      expect(h.data.step, SuggestionReviewStep.choosing);
      expect(h.data.selected, {0, 1});
      h.vm.backToReview();
      expect(h.data.step, SuggestionReviewStep.reviewing);
      expect(h.tasks.saved, isEmpty);
    });

    test('chọn 1 việc (đi bộ) → đúng 1 việc trong lịch, status partial, G07',
        () async {
      await h.ready();
      h.vm.startChoosing();
      h.vm.toggle(1); // bỏ chọn thư giãn
      expect(h.tasks.saved, isEmpty, reason: 'chọn chưa ghi gì vào lịch');
      expect(await h.vm.continueChoosing(), isTrue);

      expect(h.data.step, SuggestionReviewStep.acceptedPartial);
      expect(h.data.acceptedNow, [0]);
      expect(h.data.remaining, [1]);
      expect(
          [for (final t in h.tasks.saved.values) t.title], ['Đi bộ nhẹ nhàng']);
      final stored = await h.stored();
      expect(stored.status, SuggestionStatus.partial);
      expect(stored.remaining.single.title, 'Thư giãn nhẹ nhàng');

      final p = h.analytics.paramsOf('accept_suggestion').single!;
      // card (1) + Chọn từng việc + bỏ chọn + Tiếp tục.
      expect(
          p, {'count': 1, 'changed_time': false, 'partial': true, 'taps': 4});
    });

    test('chọn thư giãn → G07b (thư giãn đã nhận, đi bộ còn là gợi ý)',
        () async {
      await h.ready();
      h.vm.startChoosing();
      h.vm.toggle(0);
      await h.vm.continueChoosing();
      expect(h.data.acceptedNow, [1]);
      expect(h.data.remaining, [0]);
      expect([for (final t in h.tasks.saved.values) t.habitKey], ['downshift']);
    });

    test('chọn hết + "Tiếp tục" = nhận hết → G05, partial: false', () async {
      await h.ready();
      h.vm.startChoosing();
      await h.vm.continueChoosing();
      expect(h.data.step, SuggestionReviewStep.accepted);
      expect(h.tasks.saved, hasLength(2));
      expect((await h.stored()).status, SuggestionStatus.accepted);
      expect(h.analytics.paramsOf('accept_suggestion').single!['partial'],
          isFalse);
    });

    test('chưa chọn việc nào → câu nhắc, không lưu, không log', () async {
      await h.ready();
      h.vm.startChoosing();
      h.vm.toggle(0);
      h.vm.toggle(1);
      expect(await h.vm.continueChoosing(), isFalse);
      expect(h.data.needSelection, isTrue);
      expect(h.data.step, SuggestionReviewStep.choosing);
      expect(h.tasks.saved, isEmpty);
      expect(h.analytics.paramsOf('accept_suggestion'), isEmpty);
      h.vm.toggle(0);
      expect(h.data.needSelection, isFalse);
    });

    test('đổi giờ rồi chọn từng việc → việc lưu đúng giờ mới', () async {
      await h.ready();
      h.vm.startChangeTime(0);
      h.vm.pickTime(const SuggestionTime(9, 0));
      h.vm.saveNewTime();
      h.vm.startChoosing();
      h.vm.toggle(1);
      await h.vm.continueChoosing();
      expect(h.tasks.saved.values.single.hour, 9);
      expect(h.analytics.paramsOf('accept_suggestion').single!['changed_time'],
          isTrue);
    });
  });

  group('SuggestionReviewViewModel – bỏ qua + Hoàn tác', () {
    late Harness h;
    setUp(() => h = Harness());
    tearDown(() => h.dispose());

    test(
        'bỏ qua → G09, rời pending, lịch không đổi, không báo người gửi; Hoàn tác → pending, G03',
        () async {
      await h.ready();
      expect(await h.vm.dismiss(), isTrue);
      expect(h.data.step, SuggestionReviewStep.dismissed);
      expect(await h.suggestions.watchPending(momUid).first, isEmpty);
      expect((await h.stored()).status, SuggestionStatus.dismissed);
      expect(h.tasks.saved, isEmpty);
      expect(h.suggestions.senderNotified, 0);
      expect(h.suggestions.momNotified, 1, reason: 'chỉ lần gửi ban đầu');
      expect(h.analytics.paramsOf('dismiss_suggestion').single, {'items': 2});

      expect(await h.vm.undoDismiss(), isTrue);
      expect(h.data.step, SuggestionReviewStep.reviewing);
      expect((await h.suggestions.watchPending(momUid).first).single.id, 'g1');
      expect(h.analytics.paramsOf('undo_action').single,
          {'action': 'dismiss_suggestion'});
      expect(h.suggestions.senderNotified, 0);
      expect(h.tasks.saved, isEmpty);
    });

    test('Hoàn tác giữ giờ đã đổi; chỉ bỏ qua được từ G03', () async {
      await h.ready();
      h.vm.startChangeTime(0);
      expect(await h.vm.dismiss(), isFalse, reason: 'đang ở G04');
      h.vm.pickTime(const SuggestionTime(9, 0));
      h.vm.saveNewTime();
      await h.vm.dismiss();
      await h.vm.undoDismiss();
      expect(h.data.changedIndex, 0);
    });
  });

  group('SuggestionReviewScreen – G06 / G07 / G09', () {
    late Harness h;

    Future<void> pump(WidgetTester tester,
        {double width = 412,
        double height = 800,
        double scale = 1.0,
        SuggestionEntry entry = SuggestionEntry.card}) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      h = Harness(entry: entry);
      addTearDown(h.dispose);
      final router = GoRouter(
          initialLocation: '/today/suggestions/g1?from=${entry.name}',
          routes: [
            GoRoute(
                path: '/today',
                builder: (_, __) => const Text('S03'),
                routes: [
                  GoRoute(
                      path: 'suggestions/:id',
                      builder: (_, s) => SuggestionReviewScreen(
                          id: s.pathParameters['id']!,
                          entry: SuggestionEntry.fromQuery(
                              s.uri.queryParameters['from']))),
                ]),
            GoRoute(path: '/family', builder: (_, __) => const Text('S09')),
            GoRoute(
                path: '/week/:date',
                builder: (_, s) => Text('S11 ${s.pathParameters['date']}')),
          ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
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

    Future<void> tap(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    void expectTexts(List<String> texts) {
      for (final t in texts) {
        expect(find.text(t, skipOffstage: false), findsWidgets, reason: t);
      }
    }

    const g06 = [
      'Quay lại',
      'Chọn từng việc',
      'Mai',
      'Con gái',
      '“Mẹ ơi, mai mình đi bộ với cô Tám nhé?”',
      'Đọc to',
      'Bác muốn nhận việc nào?',
      'Đi bộ nhẹ nhàng',
      'Thư giãn nhẹ nhàng',
      '8:00 sáng',
      '9:00 sáng',
      'Đã chọn',
      'Chưa thêm vào lịch của Bác. Lịch chỉ thay đổi khi Bác bấm Tiếp tục.',
      'Tiếp tục',
    ];
    const g07 = [
      'Đã thêm vào lịch',
      '1 việc của Mai đã vào lịch ngày mai.',
      'Đọc to',
      '1 việc đã nhận',
      'Đi bộ nhẹ nhàng',
      'Vận động tự nhiên · 20 phút',
      'Chưa làm',
      'Thư giãn nhẹ nhàng',
      'Gợi ý của Mai · 9:00 sáng · 15 phút',
      'Chưa thêm vào lịch. Bác có thể thêm sau trong Gia đình.',
      'Bác có thể đổi giờ hoặc ngưng nhắc.',
      'Xem lịch ngày mai',
      'Về Hôm nay',
    ];
    const g09 = [
      'Quay lại',
      'Đã bỏ qua gợi ý',
      'Chưa việc nào của Mai vào lịch ngày mai.',
      'Đọc to',
      '2 việc đã bỏ qua',
      'Đi bộ nhẹ nhàng',
      'Thư giãn nhẹ nhàng',
      'Bỏ qua',
      '20 phút',
      '15 phút',
      'Bác có thể xem lại gợi ý bất cứ lúc nào trong Gia đình.',
      'Hoàn tác',
      'Về Hôm nay',
    ];

    testWidgets(
        'G03 → Chọn từng việc → G06 → bỏ chọn thư giãn → Tiếp tục → G07',
        (tester) async {
      await pump(tester);
      await tap(tester, find.text('Chọn từng việc'));
      expectTexts(g06);
      expect(find.text('Đã chọn', skipOffstage: false), findsNWidgets(2));

      await tap(tester, find.text('Thư giãn nhẹ nhàng'));
      expect(find.text('Chọn', skipOffstage: false), findsOneWidget);
      await tap(tester, find.text('Tiếp tục'));
      expectTexts(g07);
      expect(
          [for (final t in h.tasks.saved.values) t.title], ['Đi bộ nhẹ nhàng']);
    });

    testWidgets('G06 "Quay lại" về G03', (tester) async {
      await pump(tester);
      await tap(tester, find.text('Chọn từng việc'));
      await tap(tester, find.widgetWithText(AppButton, 'Quay lại'));
      expect(find.text('Mai gửi lịch cho Bác'), findsOneWidget);
    });

    testWidgets(
        'G06 bỏ chọn hết → "Tiếp tục" hiện câu nhắc có Ví dụ, không lưu',
        (tester) async {
      await pump(tester);
      await tap(tester, find.text('Chọn từng việc'));
      await tap(tester, find.text('Đi bộ nhẹ nhàng'));
      await tap(tester, find.text('Thư giãn nhẹ nhàng'));
      await tap(tester, find.text('Tiếp tục'));
      expect(find.text('Bác chưa chọn việc nào.', skipOffstage: false),
          findsOneWidget);
      expect(
          find.text('Ví dụ: chạm vào “Đi bộ nhẹ nhàng” ở trên.',
              skipOffstage: false),
          findsOneWidget);
      expect(h.tasks.saved, isEmpty);
    });

    testWidgets('G03 → Bỏ qua gợi ý → G09 → Hoàn tác → G03', (tester) async {
      await pump(tester);
      await tap(tester, find.text('Bỏ qua gợi ý'));
      expectTexts(g09);
      expect(find.byType(SnackBar), findsNothing,
          reason: 'Hoàn tác là nút trên màn (DT-32)');
      expect(h.tasks.saved, isEmpty);

      await tap(tester, find.text('Hoàn tác'));
      expect(find.text('Mai gửi lịch cho Bác'), findsOneWidget);
      expect(find.text('Thêm vào lịch'), findsOneWidget);
    });

    testWidgets(
        'mở từ Gia đình: G06 back "Gia đình", G09 "Quay lại Gia đình" + "Về Gia đình"',
        (tester) async {
      await pump(tester, entry: SuggestionEntry.family);
      await tap(tester, find.text('Chọn từng việc'));
      expect(find.text('Gia đình'), findsOneWidget);
      await tap(tester, find.widgetWithText(AppButton, 'Quay lại'));
      await tap(tester, find.text('Bỏ qua gợi ý'));
      expect(find.text('Quay lại Gia đình'), findsOneWidget);
      await tap(tester, find.text('Về Gia đình'));
      expect(find.text('S09'), findsOneWidget);
    });

    // Chiều cao 704 = 800 trừ thanh tab của shell (96).
    for (final width in [360.0, 412.0]) {
      for (final scale in [1.3, 2.0]) {
        testWidgets(
            '$width dp × $scale: G06, G07, G09 không tràn, nút chính luôn thấy',
            (tester) async {
          await pump(tester, width: width, height: 704, scale: scale);
          void visible(String label) {
            final r = tester.getRect(find.text(label));
            expect(r.bottom, lessThanOrEqualTo(704), reason: label);
            expect(r.top, greaterThanOrEqualTo(0), reason: label);
          }

          await tap(tester, find.text('Chọn từng việc'));
          expect(tester.takeException(), isNull);
          visible('Tiếp tục');
          await tap(tester, find.text('Thư giãn nhẹ nhàng'));
          await tap(tester, find.text('Tiếp tục'));
          expect(tester.takeException(), isNull);
          visible('Xem lịch ngày mai');
        });

        testWidgets('$width dp × $scale: G09 không tràn, "Hoàn tác" luôn thấy',
            (tester) async {
          await pump(tester, width: width, height: 704, scale: scale);
          await tap(tester, find.text('Bỏ qua gợi ý'));
          expect(tester.takeException(), isNull);
          final r = tester.getRect(find.text('Hoàn tác'));
          expect(r.bottom, lessThanOrEqualTo(704));
        });
      }
    }
  });
}
