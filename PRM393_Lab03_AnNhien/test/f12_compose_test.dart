import 'dart:async';

import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/suggestion.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/screens/suggestion/suggestion_compose_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/habit_repository.dart';
import 'package:an_nhien/services/profile_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/suggestion_compose_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// F12 bước 02: G01 → G01b → G02 (con cháu soạn và gửi gợi ý).
const momUid = 'mom-uid';
const mai = AppUser(uid: 'mai-uid', displayName: 'Mai');
final now = DateTime(2026, 11, 4, 10);

class RecordingAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async =>
      events.add((name, params));

  @override
  Future<void> setUserId(String? uid) async {}
}

class RecordingCrash extends FakeCrashService {
  final reasons = <String?>[];

  @override
  Future<void> recordError(Object error, StackTrace? stack,
          {String? reason}) async =>
      reasons.add(reason);
}

/// `FakeProfileService.watch` không phát trong fake-async của `testWidgets`;
/// test chỉ cần đọc một lần nên dùng bản tối giản này.
class OneShotProfileService extends FakeProfileService {
  OneShotProfileService(this.profile);
  final UserProfile profile;

  @override
  Stream<UserProfile> watch(String uid) => Stream.value(profile);
}

class Harness {
  Harness({bool paired = true}) {
    suggestions = FakeSuggestionService(delay: Duration.zero);
    tasks = FakeTaskRepository(const []);
    container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(FakeAuthService(signedIn: mai)),
      profileServiceProvider.overrideWithValue(OneShotProfileService(
          UserProfile(
              uid: mai.uid,
              displayName: 'Mai',
              role: UserRole.caregiver,
              pairedMomUid: paired ? momUid : null))),
      habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
      suggestionServiceProvider.overrideWithValue(suggestions),
      taskRepositoryProvider.overrideWithValue(tasks),
      analyticsServiceProvider.overrideWithValue(analytics),
      crashServiceProvider.overrideWithValue(crash),
      suggestionClockProvider.overrideWithValue(() => now),
    ]);
  }

  late final FakeSuggestionService suggestions;
  late final FakeTaskRepository tasks;
  final analytics = RecordingAnalytics();
  final crash = RecordingCrash();
  late final ProviderContainer container;

  SuggestionComposeViewModel get vm =>
      container.read(suggestionComposeViewModelProvider.notifier);

  SuggestionCompose get data =>
      (container.read(suggestionComposeViewModelProvider)
              as UiData<SuggestionCompose>)
          .data;

  /// Giữ provider (autoDispose) sống + chờ tải xong.
  Future<void> ready() async {
    container.listen(suggestionComposeViewModelProvider, (_, __) {});
    final done = Completer<void>();
    final sub = container.listen(suggestionComposeViewModelProvider, (_, next) {
      if (next is! UiLoading && !done.isCompleted) done.complete();
    }, fireImmediately: true);
    await done.future.timeout(const Duration(seconds: 5));
    sub.close();
  }

  void dispose() {
    container.dispose();
    suggestions.dispose();
  }
}

void main() {
  group('SuggestionComposeViewModel', () {
    late Harness h;
    setUp(() => h = Harness());
    tearDown(() => h.dispose());

    test(
        'mở màn → G01 với 2 việc Figma cho ngày mai, tên thói quen từ HabitRepository',
        () async {
      await h.ready();
      final d = h.data;
      expect(d.step, SuggestionComposeStep.compose);
      expect(d.momUid, momUid);
      expect([for (final i in d.items) i.title],
          ['Đi bộ nhẹ nhàng', 'Thư giãn nhẹ nhàng']);
      expect([for (final i in d.items) i.time],
          const [SuggestionTime(8, 0), SuggestionTime(9, 0)]);
      expect(d.items.every((i) => i.date == DateTime(2026, 11, 5)), isTrue);
      expect(d.habitNames['move'], 'Vận động tự nhiên');
      expect(d.habitNames['downshift'], 'Thư giãn mỗi ngày');
    });

    test('chọn giờ → hỏi lại → gửi: Fake nhận đúng dữ liệu, lịch mẹ chưa đổi',
        () async {
      await h.ready();
      h.vm.selectTime(0, const SuggestionTime(9, 0));
      h.vm.setMessage('  Mẹ ơi, mai mình đi bộ nhé?  ');
      expect(await h.vm.send(), isFalse, reason: 'phải qua G01b trước');
      h.vm.requestSend();
      expect(h.data.step, SuggestionComposeStep.confirm);

      expect(await h.vm.send(), isTrue);
      expect(h.data.step, SuggestionComposeStep.sent);
      final sent = (await h.suggestions.watchPending(momUid).first).single;
      expect(sent.fromUid, 'mai-uid');
      expect(sent.fromName, 'Mai');
      expect(sent.message, 'Mẹ ơi, mai mình đi bộ nhé?');
      expect(sent.status, SuggestionStatus.pending);
      expect([for (final i in sent.items) i.time],
          const [SuggestionTime(9, 0), SuggestionTime(9, 0)]);
      expect(sent.createdAt, now);
      expect(await h.tasks.tasksForDay(DateTime(2026, 11, 5)), isEmpty);
      expect(h.suggestions.momNotified, 1);
    });

    test('event send_suggestion chỉ có số + khoá, không có tên / lời nhắn',
        () async {
      await h.ready();
      h.vm.setMessage('Mẹ ơi');
      h.vm.requestSend();
      await h.vm.send();
      final params =
          h.analytics.events.where((e) => e.$1 == 'send_suggestion').single.$2!;
      expect(params, {'items': 2, 'source': 'suggest'});
    });

    test('"Sửa lại" về G01, giữ giờ đã chọn và lời nhắn', () async {
      await h.ready();
      h.vm.selectTime(0, const SuggestionTime(9, 0));
      h.vm.setMessage('Mẹ ơi');
      h.vm.requestSend();
      h.vm.editAgain();
      expect(h.data.step, SuggestionComposeStep.compose);
      expect(h.data.items.first.time, const SuggestionTime(9, 0));
      expect(h.data.message, 'Mẹ ơi');
    });

    test(
        'lỗi gửi → giữ G01b + dữ liệu, có câu lỗi, ghi Crashlytics; Thử lại gửi được',
        () async {
      await h.ready();
      h.vm.selectTime(1, const SuggestionTime(8, 0));
      h.vm.requestSend();
      h.suggestions.failOnSend = true;
      expect(await h.vm.send(), isFalse);
      expect(h.data.step, SuggestionComposeStep.confirm);
      expect(h.data.sendError, FakeSuggestionService.sendError.userMessage);
      expect(h.data.sending, isFalse);
      expect(h.data.items[1].time, const SuggestionTime(8, 0));
      expect(h.crash.reasons, ['send_suggestion']);
      expect(h.analytics.events, isEmpty);

      h.suggestions.failOnSend = false;
      expect(await h.vm.send(), isTrue);
      expect(h.data.sendError, isNull);
    });

    test('bấm gửi 2 lần liền chỉ gửi 1 lần', () async {
      await h.ready();
      h.vm.requestSend();
      final results = await Future.wait([h.vm.send(), h.vm.send()]);
      expect(results.where((r) => r), hasLength(1));
      expect(h.suggestions.momNotified, 1);
    });

    test('chưa ghép nối → needsPairing, không gửi được', () async {
      final h2 = Harness(paired: false);
      addTearDown(h2.dispose);
      await h2.ready();
      expect(h2.data.step, SuggestionComposeStep.needsPairing);
      h2.vm.requestSend();
      expect(await h2.vm.send(), isFalse);
    });
  });

  group('SuggestionComposeScreen', () {
    late Harness h;

    Future<void> pump(WidgetTester tester,
        {double width = 412, double scale = 1.0, bool paired = true}) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      h = Harness(paired: paired);
      addTearDown(h.dispose);
      final router = GoRouter(initialLocation: '/caregiver/suggest', routes: [
        GoRoute(
            path: '/caregiver/suggest',
            builder: (_, __) => const SuggestionComposeScreen()),
        GoRoute(
            path: '/caregiver/schedule', builder: (_, __) => const Text('C03')),
        GoRoute(path: '/caregiver/pair', builder: (_, __) => const Text('C02')),
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

    const g01 = [
      'Quay lại',
      'Gợi ý lịch cho mẹ',
      'Mẹ sẽ tự chọn nhận, đổi giờ hoặc bỏ qua.',
      'Đi bộ nhẹ nhàng',
      'Vận động tự nhiên · 20 phút',
      'Thư giãn nhẹ nhàng',
      'Thư giãn mỗi ngày · 15 phút',
      '8:00 sáng',
      '9:00 sáng',
      'Lời nhắn gửi kèm (không bắt buộc)',
      'Ví dụ: Mẹ ơi, mai mình đi bộ nhé?',
      'Lịch của mẹ chỉ thay đổi khi mẹ bấm nhận.',
      'Gửi gợi ý cho mẹ',
    ];
    const g01b = [
      'Gửi gợi ý cho mẹ?',
      'Lịch của mẹ chỉ cập nhật khi mẹ bấm nhận.',
      'Gửi gợi ý',
      'Sửa lại',
    ];
    const g02 = [
      'Quay lại',
      'Mai',
      'Đã gửi gợi ý cho mẹ',
      'Mẹ sẽ tự chọn nhận, đổi giờ hoặc bỏ qua.',
      'Lịch của mẹ chưa thay đổi. Việc chỉ vào lịch khi mẹ bấm nhận.',
      '2 việc gợi ý cho ngày mai',
      'Đi bộ nhẹ nhàng',
      'Thư giãn nhẹ nhàng',
      '20 phút',
      '15 phút',
      'Chưa làm',
      'Về lịch của mẹ',
    ];

    testWidgets(
        'G01 → chọn giờ → G01b → Sửa lại → G01 → G01b → Gửi gợi ý → G02',
        (tester) async {
      await pump(tester);
      expectTexts(g01);
      expect(find.text('Đang chọn', skipOffstage: false), findsNWidgets(2));

      // Đi bộ: đổi 8:00 → 9:00 sáng (nút 9:00 đầu tiên thuộc thẻ đi bộ).
      await tap(tester, find.text('9:00 sáng').first);
      await tester.enterText(
          find.byType(TextField), 'Mẹ ơi, mai mình đi bộ nhé?');
      await tester.pumpAndSettle();

      await tap(tester, find.text('Gửi gợi ý cho mẹ'));
      expectTexts(g01b);
      expect(find.text('Gửi gợi ý cho mẹ'), findsNothing);

      await tap(tester, find.text('Sửa lại'));
      expect(find.text('Gửi gợi ý cho mẹ'), findsOneWidget);
      expect(find.text('Gửi gợi ý cho mẹ?'), findsNothing);
      expect(find.text('Mẹ ơi, mai mình đi bộ nhé?'), findsOneWidget);

      await tap(tester, find.text('Gửi gợi ý cho mẹ'));
      await tap(tester, find.text('Gửi gợi ý'));
      expectTexts(g02);
      expect(find.text('9 giờ sáng', skipOffstage: false), findsNWidgets(2));

      final sent = (await tester
              .runAsync(() => h.suggestions.watchPending(momUid).first))!
          .single;
      expect(sent.items.first.time, const SuggestionTime(9, 0));
      expect(sent.message, 'Mẹ ơi, mai mình đi bộ nhé?');

      await tap(tester, find.text('Về lịch của mẹ'));
      expect(find.text('C03'), findsOneWidget);
    });

    testWidgets('lỗi gửi → câu lỗi + "Thử lại", dữ liệu giữ nguyên',
        (tester) async {
      await pump(tester);
      h.suggestions.failOnSend = true;
      await tap(tester, find.text('Gửi gợi ý cho mẹ'));
      await tap(tester, find.text('Gửi gợi ý'));
      expect(
          find.text(FakeSuggestionService.sendError.userMessage,
              skipOffstage: false),
          findsOneWidget);
      expect(find.text('Thử lại', skipOffstage: false), findsOneWidget);
      expect(find.text('Sửa lại', skipOffstage: false), findsOneWidget);

      h.suggestions.failOnSend = false;
      await tap(tester, find.text('Thử lại'));
      expect(find.text('Đã gửi gợi ý cho mẹ'), findsOneWidget);
    });

    testWidgets('chưa ghép nối → EmptyView, "Ghép nối máy" đi /caregiver/pair',
        (tester) async {
      await pump(tester, paired: false);
      expect(find.text('Chưa ghép nối với máy của mẹ'), findsOneWidget);
      await tap(tester, find.text('Ghép nối máy'));
      expect(find.text('C02'), findsOneWidget);
    });

    testWidgets(
        '360 dp × 2.0 lỗi gửi: "Thử lại" + "Sửa lại" vẫn thấy, không tràn',
        (tester) async {
      await pump(tester, width: 360, scale: 2.0);
      h.suggestions.failOnSend = true;
      await tap(tester, find.text('Gửi gợi ý cho mẹ'));
      await tap(tester, find.text('Gửi gợi ý'));
      expect(tester.takeException(), isNull);
      for (final label in ['Thử lại', 'Sửa lại']) {
        final r = tester.getRect(find.text(label));
        expect(r.bottom, lessThanOrEqualTo(800), reason: label);
        expect(r.top, greaterThanOrEqualTo(0), reason: label);
      }
    });

    for (final width in [360.0, 412.0]) {
      for (final scale in [1.3, 2.0]) {
        testWidgets(
            '$width dp × $scale: G01, G01b, G02 không tràn, nút đáy luôn thấy',
            (tester) async {
          await pump(tester, width: width, scale: scale);
          expect(tester.takeException(), isNull);
          void footerVisible(String label) {
            final r = tester.getRect(find.text(label));
            expect(r.bottom, lessThanOrEqualTo(800), reason: label);
          }

          footerVisible('Gửi gợi ý cho mẹ');
          await tap(tester, find.text('Gửi gợi ý cho mẹ'));
          expect(tester.takeException(), isNull);
          await tap(tester, find.text('Gửi gợi ý'));
          expect(tester.takeException(), isNull);
          footerVisible('Về lịch của mẹ');
          expect(find.text('Đã gửi gợi ý cho mẹ', skipOffstage: false),
              findsOneWidget);
        });
      }
    }
  });
}
