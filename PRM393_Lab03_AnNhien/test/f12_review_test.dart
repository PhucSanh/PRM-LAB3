import 'dart:async';

import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/suggestion.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/screens/suggestion/suggestion_review_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/suggestion_compose_view_model.dart'
    show suggestionClockProvider;
import 'package:an_nhien/viewmodels/suggestion_review_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F12 bước 03: G03 → G04 → G03b → G05 / G05b (Bác xem và nhận gợi ý).
const momUid = 'mom-uid';
final now = DateTime(2026, 11, 4, 10);
final tomorrow = DateTime(2026, 11, 5);

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

class RecordingCrash extends FakeCrashService {
  final reasons = <String?>[];

  @override
  Future<void> recordError(Object error, StackTrace? stack,
          {String? reason}) async =>
      reasons.add(reason);
}

/// Lịch Bác trong bộ nhớ, đọc được ngay (không có độ trễ); lỗi ở lần lưu thứ [failOnSaveNo].
class RecordingTasks extends FakeTaskRepository {
  RecordingTasks() : super(const []);
  final saved = <String, TaskItem>{};
  int? failOnSaveNo;
  int _saves = 0;

  @override
  Future<void> save(TaskItem task) async {
    _saves++;
    if (_saves == failOnSaveNo) throw const AppException('Chưa lưu được việc.');
    saved[task.id] = task;
  }

  @override
  Future<void> delete(String taskId) async => saved.remove(taskId);
}

class Harness {
  Harness({SuggestionEntry entry = SuggestionEntry.card, bool seed = true}) {
    args = (id: 'g1', entry: entry);
    suggestions = FakeSuggestionService(delay: Duration.zero);
    if (seed) {
      suggestions.send(
          momUid, FakeSuggestionService.figmaSample(id: 'g1', now: now));
    }
    container = ProviderContainer(overrides: [
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
  }

  late final SuggestionReviewArgs args;
  late final FakeSuggestionService suggestions;
  final tasks = RecordingTasks();
  final analytics = RecordingAnalytics();
  final crash = RecordingCrash();
  late final ProviderContainer container;

  SuggestionReviewViewModel get vm =>
      container.read(suggestionReviewViewModelProvider(args).notifier);
  UiState<SuggestionReview> get state =>
      container.read(suggestionReviewViewModelProvider(args));
  SuggestionReview get data => (state as UiData<SuggestionReview>).data;
  FakeReminderService get reminders =>
      container.read(reminderServiceProvider) as FakeReminderService;

  Future<void> ready() async {
    container.listen(suggestionReviewViewModelProvider(args), (_, __) {});
    final done = Completer<void>();
    final sub =
        container.listen(suggestionReviewViewModelProvider(args), (_, next) {
      if (next is! UiLoading && !done.isCompleted) done.complete();
    }, fireImmediately: true);
    await done.future.timeout(const Duration(seconds: 5));
    sub.close();
  }

  Future<Suggestion> stored() async => (await suggestions.byId(momUid, 'g1'))!;

  void dispose() {
    container.dispose();
    suggestions.dispose();
  }
}

void main() {
  group('SuggestionReviewViewModel', () {
    late Harness h;
    setUp(() => h = Harness());
    tearDown(() => h.dispose());

    test('G03: chưa bấm "Thêm vào lịch" thì lịch Bác không có việc mới',
        () async {
      await h.ready();
      expect(h.data.step, SuggestionReviewStep.reviewing);
      expect(h.data.dayLabel, 'ngày mai');
      expect(h.data.changeableIndex, 0);
      expect(h.data.changedIndex, isNull);
      expect(h.tasks.saved, isEmpty);
    });

    test(
        '"Thêm vào lịch" → đủ 2 việc một lần, đúng ngày mai + giờ, gợi ý accepted, đặt nhắc (G05)',
        () async {
      await h.ready();
      expect(await h.vm.acceptAll(), isTrue);
      expect(h.data.step, SuggestionReviewStep.accepted);
      expect(h.data.acceptedWithChangedTime, isFalse);
      final tasks = h.tasks.saved.values.toList();
      expect([for (final t in tasks) t.title],
          ['Đi bộ nhẹ nhàng', 'Thư giãn nhẹ nhàng']);
      expect([for (final t in tasks) (t.hour, t.minute)], [(8, 0), (9, 0)]);
      expect(
          tasks.every((t) =>
              t.startDate == dateKey(tomorrow) && t.repeat == RepeatRule.once),
          isTrue);
      expect([for (final t in tasks) t.durationMinutes], [20, 15]);
      expect((await h.stored()).status, SuggestionStatus.accepted);
      expect(h.reminders.scheduled.keys, unorderedEquals(h.tasks.saved.keys));
      expect(h.suggestions.senderNotified, 0);
    });

    test(
        'đổi giờ: G04 → chọn 9:00 → Lưu giờ mới → G03b; lịch chưa đổi; nhận → giờ mới (G05b)',
        () async {
      await h.ready();
      h.vm.startChangeTime(0);
      expect(h.data.step, SuggestionReviewStep.changingTime);
      expect(h.data.pendingTime, const SuggestionTime(8, 0));
      h.vm.pickTime(const SuggestionTime(9, 0));
      h.vm.saveNewTime();
      expect(h.data.step, SuggestionReviewStep.reviewing);
      expect(h.data.changedIndex, 0);
      expect(h.tasks.saved, isEmpty, reason: 'đổi giờ chưa ghi gì vào lịch');

      await h.vm.acceptAll();
      expect(h.data.acceptedWithChangedTime, isTrue);
      final walk = h.tasks.saved.values.firstWhere((t) => t.habitKey == 'move');
      expect((walk.hour, walk.minute), (9, 0));
      final p = h.analytics.paramsOf('accept_suggestion').single!;
      expect(p['changed_time'], isTrue);
    });

    test('G04 "Quay lại" bỏ giờ đang chọn; giờ ngoài danh sách bị bỏ qua',
        () async {
      await h.ready();
      h.vm.startChangeTime(0);
      h.vm.pickTime(const SuggestionTime(15, 0));
      expect(h.data.pendingTime, const SuggestionTime(8, 0));
      h.vm.pickTime(const SuggestionTime(9, 0));
      h.vm.cancelChangeTime();
      expect(h.data.step, SuggestionReviewStep.reviewing);
      expect(h.data.times.first, const SuggestionTime(8, 0));
      expect(h.data.changedIndex, isNull);
    });

    test('M6: vào từ popup + "Thêm vào lịch" = 2 chạm; event chỉ có số / cờ',
        () async {
      final p = Harness(entry: SuggestionEntry.popup);
      addTearDown(p.dispose);
      await p.ready();
      await p.vm.acceptAll();
      final params = p.analytics.paramsOf('accept_suggestion').single!;
      expect(params,
          {'count': 2, 'changed_time': false, 'partial': false, 'taps': 2});
      expect(params.values.whereType<String>(), isEmpty);
    });

    test(
        'lỗi lưu việc thứ 2 → xoá việc đã lưu, gợi ý vẫn pending, có câu lỗi; Thử lại được',
        () async {
      await h.ready();
      h.tasks.failOnSaveNo = 2;
      expect(await h.vm.acceptAll(), isFalse);
      expect(h.tasks.saved, isEmpty, reason: 'không để lịch nửa vời');
      expect(h.data.step, SuggestionReviewStep.reviewing);
      expect(h.data.busy, isFalse);
      expect(h.data.actionError, 'Chưa lưu được việc.');
      expect((await h.stored()).status, SuggestionStatus.pending);
      expect(h.crash.reasons, ['accept_suggestion']);
      expect(h.analytics.paramsOf('accept_suggestion'), isEmpty);
      expect(h.reminders.scheduled, isEmpty);

      h.tasks.failOnSaveNo = null;
      expect(await h.vm.acceptAll(), isTrue);
      expect(h.tasks.saved, hasLength(2));
    });

    test('lỗi ghi trạng thái gợi ý → cũng xoá các việc vừa lưu', () async {
      await h.ready();
      h.suggestions.failOnAccept = true;
      expect(await h.vm.acceptAll(), isFalse);
      expect(h.tasks.saved, isEmpty);
      expect(h.data.actionError, FakeSuggestionService.acceptError.userMessage);
    });

    test('bấm "Thêm vào lịch" 2 lần liền chỉ lưu 1 lần', () async {
      await h.ready();
      final r = await Future.wait([h.vm.acceptAll(), h.vm.acceptAll()]);
      expect(r.where((x) => x), hasLength(1));
      expect(h.tasks.saved, hasLength(2));
    });

    test('gợi ý partial → chỉ hiện / nhận việc còn lại', () async {
      final s = await h.stored();
      await h.suggestions.accept(momUid, 'g1', [s.items.first]);
      await h.ready();
      expect(h.data.remaining, [1]);
      await h.vm.acceptAll();
      expect([for (final t in h.tasks.saved.values) t.title],
          ['Thư giãn nhẹ nhàng']);
      expect((await h.stored()).status, SuggestionStatus.accepted);
    });

    test('gợi ý đã nhận hết / không có → Empty', () async {
      final s = await h.stored();
      await h.suggestions.accept(momUid, 'g1', s.items);
      await h.ready();
      expect(h.state, isA<UiEmpty<SuggestionReview>>());

      final none = Harness(seed: false);
      addTearDown(none.dispose);
      await none.ready();
      expect(none.state, isA<UiEmpty<SuggestionReview>>());
    });

    test('lỗi tải → Error; load() lại → Data', () async {
      h.suggestions.failOnLoad = true;
      await h.ready();
      expect(h.state, isA<UiError<SuggestionReview>>());
      h.suggestions.failOnLoad = false;
      await h.vm.load();
      expect(h.state, isA<UiData<SuggestionReview>>());
    });

    test('SuggestionEntry.fromQuery', () {
      expect(SuggestionEntry.fromQuery('popup'), SuggestionEntry.popup);
      expect(SuggestionEntry.fromQuery(null), SuggestionEntry.direct);
      expect(SuggestionEntry.fromQuery('lạ'), SuggestionEntry.direct);
      expect(SuggestionEntry.direct.openTaps, 0);
      expect(SuggestionEntry.card.openTaps, 1);
    });
  });

  group('SuggestionReviewScreen', () {
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
            GoRoute(path: '/calendar', builder: (_, __) => const Text('S03')),
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

    const g03 = [
      'Quay lại',
      'Mai gửi lịch cho Bác',
      'Mai',
      'Con gái',
      '“Mẹ ơi, mai mình đi bộ với cô Tám nhé?”',
      'Đọc to',
      '2 việc gợi ý',
      'Đi bộ nhẹ nhàng',
      'Thư giãn nhẹ nhàng',
      'Chưa làm',
      '8 giờ sáng',
      '9 giờ sáng',
      '20 phút',
      '15 phút',
      'Chưa thêm vào lịch. Bác tự chọn.',
      'Thêm vào lịch',
      'Đổi giờ đi bộ nhẹ nhàng',
      'Chọn từng việc',
      'Bỏ qua gợi ý',
    ];
    const g04 = [
      'Đổi giờ đi bộ nhẹ nhàng',
      'Đọc to',
      '2 việc gợi ý',
      'Chọn giờ đi bộ nhẹ nhàng:',
      '8:00 sáng',
      '9:00 sáng',
      'Đang chọn',
      'Chưa đổi trên máy của Bác. Lịch chỉ thay đổi khi Bác bấm Lưu giờ mới.',
      'Lưu giờ mới',
      'Quay lại',
    ];
    const g05b = [
      'Quay lại',
      'Đã thêm vào lịch',
      '2 việc của Mai đã vào lịch ngày mai.',
      'Đọc to',
      '2 việc đã nhận',
      'Đi bộ nhẹ nhàng',
      'Vận động tự nhiên · 20 phút',
      'Thư giãn nhẹ nhàng',
      'Thư giãn mỗi ngày · 15 phút',
      'Chưa làm',
      'Bác có thể đổi giờ hoặc ngưng nhắc.',
      'Xem lịch ngày mai',
      'Về Hôm nay',
    ];

    testWidgets(
        'G03 → Đổi giờ → G04 → 9:00 → Lưu giờ mới → G03b → Thêm vào lịch → G05b',
        (tester) async {
      await pump(tester);
      expectTexts(g03);

      await tap(tester, find.text('Đổi giờ đi bộ nhẹ nhàng'));
      expectTexts(g04);
      expect(find.text('Thêm vào lịch'), findsNothing);

      await tap(tester, find.text('9:00 sáng'));
      await tap(tester, find.text('Lưu giờ mới'));
      expect(
          find.text('Bác đã chọn giờ đi bộ nhẹ nhàng. Chưa thêm vào lịch.',
              skipOffstage: false),
          findsOneWidget);
      // Thẻ đi bộ hiện giờ đã đổi (DT-31): 2 việc đều 9 giờ sáng.
      expect(find.text('9 giờ sáng', skipOffstage: false), findsNWidgets(2));
      expect(h.tasks.saved, isEmpty);

      await tap(tester, find.text('Thêm vào lịch'));
      expectTexts(g05b);
      expect(
          h.tasks.saved.values.firstWhere((t) => t.habitKey == 'move').hour, 9);

      await tap(tester, find.text('Xem lịch ngày mai'));
      expect(find.text('S11 2026-11-05'), findsOneWidget);
    });

    testWidgets(
        'G03 → Thêm vào lịch → G05 (không có khối "đổi giờ hoặc ngưng nhắc")',
        (tester) async {
      await pump(tester);
      await tap(tester, find.text('Thêm vào lịch'));
      expect(find.text('Đã thêm vào lịch'), findsOneWidget);
      expect(
          find.text('Bác có thể đổi giờ hoặc ngưng nhắc.', skipOffstage: false),
          findsNothing);
      expect(find.text('8 giờ sáng', skipOffstage: false), findsOneWidget);
      await tap(tester, find.text('Về Hôm nay'));
      expect(find.text('S03'), findsOneWidget);
    });

    testWidgets(
        'mở từ Gia đình: back "Gia đình" → G05 "Quay lại Gia đình" + "Về Gia đình"',
        (tester) async {
      await pump(tester, entry: SuggestionEntry.family);
      expect(find.text('Gia đình'), findsOneWidget);
      await tap(tester, find.text('Thêm vào lịch'));
      expect(find.text('Quay lại Gia đình'), findsOneWidget);
      await tap(tester, find.text('Về Gia đình'));
      expect(find.text('S09'), findsOneWidget);
    });

    testWidgets('lỗi lưu → câu lỗi + "Thử lại", lịch không có việc',
        (tester) async {
      await pump(tester);
      h.tasks.failOnSaveNo = 1;
      await tap(tester, find.text('Thêm vào lịch'));
      expect(find.text('Chưa lưu được việc.', skipOffstage: false),
          findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(h.tasks.saved, isEmpty);
    });

    // Chiều cao 704 = 800 trừ thanh tab của shell (96).
    for (final width in [360.0, 412.0]) {
      for (final scale in [1.3, 2.0]) {
        testWidgets(
            '$width dp × $scale: G03, G04, G05b không tràn, nút chính luôn thấy',
            (tester) async {
          await pump(tester, width: width, height: 704, scale: scale);
          expect(tester.takeException(), isNull);
          void visible(String label) {
            final r = tester.getRect(find.text(label));
            expect(r.bottom, lessThanOrEqualTo(704), reason: label);
            expect(r.top, greaterThanOrEqualTo(0), reason: label);
          }

          visible('Thêm vào lịch');
          await tap(tester, find.text('Đổi giờ đi bộ nhẹ nhàng'));
          expect(tester.takeException(), isNull);
          visible('Lưu giờ mới');
          await tap(tester, find.text('9:00 sáng'));
          await tap(tester, find.text('Lưu giờ mới'));
          await tap(tester, find.text('Thêm vào lịch'));
          expect(tester.takeException(), isNull);
          visible('Xem lịch ngày mai');
        });
      }
    }
  });
}
