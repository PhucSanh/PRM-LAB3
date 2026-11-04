import 'dart:async';

import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/screens/suggestion/suggestion_review_screen.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/suggestion_compose_view_model.dart'
    show suggestionClockProvider;
import 'package:an_nhien/viewmodels/suggestion_inbox_view_model.dart';
import 'package:an_nhien/viewmodels/suggestion_review_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:an_nhien/widgets/app_shell.dart';
import 'package:an_nhien/widgets/confirm_dialog.dart';
import 'package:an_nhien/widgets/suggestion_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'f12_review_test.dart'
    show RecordingAnalytics, RecordingCrash, RecordingTasks;

/// F12 bước 05: popup G10 / G11 (một lần, không tự đóng) + thẻ G12 trên Hôm nay.
const momUid = 'mom-uid';
final now = DateTime(2026, 11, 4, 17);

/// S03 giả: đặt thẻ G12 **đúng như đoạn code gửi Khang** (comment trong `suggestion_card.dart`).
class TodayStub extends StatelessWidget {
  const TodayStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          ListView(padding: const EdgeInsets.all(AppSpacing.screen), children: [
        Consumer(builder: (context, ref, _) {
          final inbox =
              ref.watch(suggestionInboxViewModelProvider); // F12 – Sanh
          return switch (inbox) {
            UiData(:final data) when data.pendingCard != null => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.base),
                child: SuggestionCard(
                  fromName: data.pendingCard!.fromName,
                  itemCount: data.pendingCard!.items.length,
                  onOpen: () => context.push(
                      '/today/suggestions/${data.pendingCard!.id}?from=card'),
                ),
              ),
            _ => const SizedBox
                .shrink(), // Đang tải / lỗi / không có gợi ý: không chiếm chỗ trên S03.
          };
        }),
        const Text('Việc tiếp theo'),
      ]),
    );
  }
}

class App {
  App(this.suggestions);

  final FakeSuggestionService suggestions;
  final tasks = RecordingTasks();
  final analytics = RecordingAnalytics();
  final crash = RecordingCrash();
  late final ProviderContainer container = ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(FakeAuthService(
        signedIn: const AppUser(uid: momUid, displayName: 'Bác Lan'))),
    suggestionServiceProvider.overrideWithValue(suggestions),
    taskRepositoryProvider.overrideWithValue(tasks),
    reminderServiceProvider.overrideWithValue(
        FakeReminderService(alreadyGranted: true, delay: Duration.zero)),
    analyticsServiceProvider.overrideWithValue(analytics),
    crashServiceProvider.overrideWithValue(crash),
    suggestionClockProvider.overrideWithValue(() => now),
  ]);

  /// App có `AppShell` thật (4 tab) – popup gắn trong `AppShell`.
  Future<void> pump(WidgetTester tester,
      {double width = 360,
      double height = 800,
      double scale = 1.0,
      String at = '/today',
      ThemeData? theme}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: at, routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/today',
                builder: (_, __) => const TodayStub(),
                routes: [
                  GoRoute(
                      path: 'suggestions/:id',
                      builder: (_, s) => SuggestionReviewScreen(
                          id: s.pathParameters['id']!,
                          entry: SuggestionEntry.fromQuery(
                              s.uri.queryParameters['from']))),
                ]),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/week', builder: (_, __) => const Text('S07'))
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/habits', builder: (_, __) => const Text('S08'))
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/family', builder: (_, __) => const Text('S09'))
          ]),
        ],
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light(),
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

  /// Gỡ app khỏi cây widget (như tắt app) rồi giải phóng container.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  }
}

FakeSuggestionService seeded({DateTime? createdAt}) {
  final s = FakeSuggestionService(delay: Duration.zero);
  final sample = FakeSuggestionService.figmaSample(id: 'g1', now: now);
  s.send(momUid,
      createdAt == null ? sample : sample.copyWith(createdAt: createdAt));
  return s;
}

Finder get popup => find.byType(ConfirmDialog<bool>);

Future<void> tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder inPopup(String text) =>
    find.descendant(of: popup, matching: find.text(text));

void main() {
  group('SuggestionInboxViewModel', () {
    test('pendingCard / popupToShow; G10 khi gửi hôm nay, G11 khi gửi trước đó',
        () async {
      final service = seeded();
      final app = App(service);
      addTearDown(app.container.dispose);
      final done = Completer<void>();
      app.container.listen(suggestionInboxViewModelProvider, (_, next) {
        if (next is UiData && !done.isCompleted) done.complete();
      }, fireImmediately: true);
      await done.future.timeout(const Duration(seconds: 5));
      final data = (app.container.read(suggestionInboxViewModelProvider)
              as UiData<SuggestionInbox>)
          .data;
      expect(data.pendingCard!.id, 'g1');
      expect(data.popupToShow!.id, 'g1');
      expect(data.sentToday(data.pendingCard!), isTrue);
      expect(data.dayLabel(data.pendingCard!), 'ngày mai');
      expect(
          data.sentToday(
              data.pendingCard!.copyWith(createdAt: DateTime(2026, 11, 3, 16))),
          isFalse);

      await app.container
          .read(suggestionInboxViewModelProvider.notifier)
          .markPopupShown('g1');
      await pumpEventQueue();
      final after = (app.container.read(suggestionInboxViewModelProvider)
              as UiData<SuggestionInbox>)
          .data;
      expect(after.popupToShow, isNull);
      expect(after.pendingCard, isNotNull,
          reason: '"Để sau" vẫn để lại thẻ G12');
      expect(service.senderNotified, 0);
    });
  });

  group('Popup G10 / G11 + thẻ G12', () {
    testWidgets('G10 tự hiện ở Hôm nay, đủ chữ Figma, đã đánh dấu popupShown',
        (tester) async {
      final service = seeded();
      final app = App(service);
      await app.pump(tester);
      expect(popup, findsOneWidget);
      for (final t in [
        'Mai gửi lịch cho Bác',
        'Mai vừa gửi lúc 4:20 chiều',
        '2 việc cho ngày mai',
        '“Mẹ ơi, mai mình đi bộ với cô Tám nhé?”',
        'Chưa thêm vào lịch. Bác tự chọn.',
        'Xem gợi ý',
        'Để sau',
      ]) {
        expect(inPopup(t), findsOneWidget, reason: t);
      }
      expect(
          (await tester.runAsync(() => service.byId(momUid, 'g1')))!.popupShown,
          isTrue);
      await app.close(tester);
    });

    testWidgets('G11: gợi ý gửi hôm trước → không có dòng "vừa gửi lúc"',
        (tester) async {
      final app = App(seeded(createdAt: DateTime(2026, 11, 3, 16, 20)));
      await app.pump(tester);
      expect(inPopup('Mai gửi lịch cho Bác'), findsOneWidget);
      expect(find.textContaining('vừa gửi lúc'), findsNothing);
      expect(inPopup('2 việc cho ngày mai'), findsOneWidget);
      await app.close(tester);
    });

    testWidgets('không tự đóng: chạm ra ngoài / Back không đóng popup',
        (tester) async {
      final app = App(seeded());
      await app.pump(tester);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(popup, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(popup, findsOneWidget);
      await app.close(tester);
    });

    testWidgets(
        '"Để sau" → còn thẻ G12; mở lại app → popup không hiện lại, thẻ vẫn còn',
        (tester) async {
      final service = seeded();
      final first = App(service);
      await first.pump(tester);
      await tap(tester, inPopup('Để sau'));
      expect(popup, findsNothing);
      expect(find.text('Mai gửi Bác 2 việc'), findsOneWidget);
      expect(find.text('Chưa thêm vào lịch. Bác tự chọn.'), findsOneWidget);
      expect(find.text('Xem gợi ý'), findsOneWidget);
      // Figma G12: không có tên việc, không có "Bỏ qua gợi ý".
      expect(find.text('• Đi bộ nhẹ nhàng'), findsNothing);
      expect(find.text('Bỏ qua gợi ý'), findsNothing);
      await first.close(tester);

      final second = App(service);
      await second.pump(tester);
      expect(popup, findsNothing);
      expect(find.text('Mai gửi Bác 2 việc'), findsOneWidget);
      await second.close(tester);
    });

    testWidgets('TC-26: popup "Xem gợi ý" → G03 → "Thêm vào lịch" = 2 chạm',
        (tester) async {
      final app = App(seeded());
      await app.pump(tester);
      await tap(tester, inPopup('Xem gợi ý'));
      expect(find.text('Mai gửi lịch cho Bác'), findsOneWidget);
      await tap(tester, find.text('Thêm vào lịch'));
      expect(find.text('Đã thêm vào lịch'), findsOneWidget);
      expect(app.analytics.paramsOf('accept_suggestion').single!['taps'], 2);
      expect(app.tasks.saved, hasLength(2));
      await app.close(tester);
    });

    testWidgets('thẻ G12 "Xem gợi ý" → G03 (from=card)', (tester) async {
      final app = App(seeded());
      await app.pump(tester);
      await tap(tester, inPopup('Để sau'));
      await tap(tester, find.text('Xem gợi ý'));
      expect(find.text('Mai gửi lịch cho Bác'), findsOneWidget);
      await tap(tester, find.text('Thêm vào lịch'));
      expect(app.analytics.paramsOf('accept_suggestion').single!['taps'], 2);
      await app.close(tester);
    });

    testWidgets('đang ở tab khác → không hiện; về tab Hôm nay → hiện',
        (tester) async {
      final app = App(seeded());
      await app.pump(tester, at: '/week');
      expect(popup, findsNothing);
      await tap(tester, find.bySemanticsLabel('Hôm nay'));
      expect(popup, findsOneWidget);
      await app.close(tester);
    });

    testWidgets('không có gợi ý → không popup, thẻ không chiếm chỗ',
        (tester) async {
      final app = App(FakeSuggestionService(delay: Duration.zero));
      await app.pump(tester);
      expect(popup, findsNothing);
      expect(find.byType(SuggestionCard), findsNothing);
      expect(
          tester.getTopLeft(find.text('Việc tiếp theo')).dy, AppSpacing.screen);
      await app.close(tester);
    });

    testWidgets('lỗi tải → không popup, thẻ không chiếm chỗ', (tester) async {
      final service = seeded()..failOnLoad = true;
      final app = App(service);
      await app.pump(tester);
      expect(popup, findsNothing);
      expect(find.byType(SuggestionCard), findsNothing);
      await app.close(tester);
    });

    for (final width in [360.0, 412.0]) {
      for (final scale in [1.3, 2.0]) {
        testWidgets('$width dp × $scale: popup không tràn, 2 nút bấm được',
            (tester) async {
          final app = App(seeded());
          await app.pump(tester, width: width, scale: scale);
          expect(tester.takeException(), isNull);
          expect(popup, findsOneWidget);
          await tester.ensureVisible(inPopup('Để sau'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tap(tester, inPopup('Để sau'));
          expect(popup, findsNothing);
          expect(tester.takeException(), isNull, reason: 'thẻ G12 không tràn');
          await app.close(tester);
        });
      }
    }
  });
}
