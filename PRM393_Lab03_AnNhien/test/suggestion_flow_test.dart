import 'package:an_nhien/models/app_user.dart';
import 'package:an_nhien/models/suggestion.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/screens/suggestion/suggestion_compose_screen.dart';
import 'package:an_nhien/services/auth_service.dart';
import 'package:an_nhien/services/habit_repository.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/suggestion_compose_view_model.dart'
    show suggestionClockProvider;
import 'package:an_nhien/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'f12_compose_test.dart' show OneShotProfileService;
import 'f12_inbox_popup_test.dart' show App, inPopup, now, popup, tap;
import 'f12_review_test.dart' show RecordingAnalytics, RecordingCrash;

/// F12 bước 06: cả luồng 2 máy dùng chung một `FakeSuggestionService`.
/// Máy con cháu (`/caregiver/suggest`) gửi → máy Bác (AppShell thật) nhận qua popup / thẻ.
const momUid = 'mom-uid';
const mai = AppUser(uid: 'mai-uid', displayName: 'Mai');

/// Máy con cháu: soạn 2 việc Figma, gửi. Trả analytics của máy này.
Future<RecordingAnalytics> caregiverSends(
    WidgetTester tester, FakeSuggestionService shared,
    {String message = 'Mẹ ơi, mai mình đi bộ nhé?'}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final analytics = RecordingAnalytics();
  final container = ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(FakeAuthService(signedIn: mai)),
    profileServiceProvider.overrideWithValue(OneShotProfileService(
        const UserProfile(
            uid: 'mai-uid',
            displayName: 'Mai',
            role: UserRole.caregiver,
            pairedMomUid: momUid))),
    habitRepositoryProvider.overrideWithValue(FakeHabitRepository()),
    suggestionServiceProvider.overrideWithValue(shared),
    analyticsServiceProvider.overrideWithValue(analytics),
    crashServiceProvider.overrideWithValue(RecordingCrash()),
    suggestionClockProvider.overrideWithValue(() => now),
  ]);
  final router = GoRouter(initialLocation: '/caregiver/suggest', routes: [
    GoRoute(
        path: '/caregiver/suggest',
        builder: (_, __) => const SuggestionComposeScreen()),
    GoRoute(path: '/caregiver/schedule', builder: (_, __) => const Text('C03')),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  ));
  await tester.pumpAndSettle();
  if (message.isNotEmpty) {
    await tester.enterText(find.byType(TextField), message);
    await tester.pumpAndSettle();
  }
  await tap(tester, find.text('Gửi gợi ý cho mẹ'));
  await tap(tester, find.text('Gửi gợi ý'));
  expect(find.text('Đã gửi gợi ý cho mẹ'), findsOneWidget);
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  router.dispose();
  return analytics;
}

/// Mọi giá trị tham số event là số / cờ / khoá – không chứa tên người gửi, lời nhắn, tên việc.
void expectNoPersonalData(List<RecordingAnalytics> devices) {
  const forbidden = ['Mai', 'Mẹ ơi', 'Đi bộ', 'Thư giãn', 'mai-uid', 'mom-uid'];
  for (final a in devices) {
    for (final (name, params) in a.events) {
      for (final v in (params ?? const {}).values) {
        if (v is String) {
          expect(forbidden.any(v.contains), isFalse, reason: '$name chứa "$v"');
        }
      }
    }
  }
}

void main() {
  late FakeSuggestionService shared;
  setUp(() => shared = FakeSuggestionService(delay: Duration.zero));
  tearDown(() => shared.dispose());

  testWidgets(
      'TC-26: con cháu gửi → lịch Bác chưa đổi → popup 1 lần → Xem gợi ý → Thêm vào lịch (≤ 2 chạm)',
      (tester) async {
    final cg = await caregiverSends(tester, shared);
    expect(cg.paramsOf('send_suggestion').single,
        {'items': 2, 'source': 'suggest'});
    expect(shared.momNotified, 1);

    final mom = App(shared);
    expect(mom.tasks.saved, isEmpty, reason: 'gửi không đổi lịch Bác');
    await mom.pump(tester, width: 412, height: 915);
    expect(popup, findsOneWidget);
    expect(inPopup('Mai vừa gửi lúc 5:00 chiều'), findsOneWidget);
    expect(inPopup('Mẹ ơi, mai mình đi bộ nhé?'), findsOneWidget);
    expect(mom.tasks.saved, isEmpty, reason: 'popup không đổi lịch');

    await tap(tester, inPopup('Xem gợi ý'));
    await tap(tester, find.text('Thêm vào lịch'));
    expect(find.text('Đã thêm vào lịch'), findsOneWidget);
    final tasks = mom.tasks.saved.values.toList();
    expect([
      for (final t in tasks) (t.title, t.hour, t.minute, t.startDate)
    ], [
      ('Đi bộ nhẹ nhàng', 8, 0, '2026-11-05'),
      ('Thư giãn nhẹ nhàng', 9, 0, '2026-11-05'),
    ]);
    final p = mom.analytics.paramsOf('accept_suggestion').single!;
    expect(p['taps'] as int, lessThanOrEqualTo(2));
    expect(p['partial'], isFalse);
    expect(shared.senderNotified, 0);
    expectNoPersonalData([cg, mom.analytics]);
    await mom.close(tester);
  });

  testWidgets(
      'đổi giờ: G03 → G04 → 9:00 → G03b → Thêm vào lịch → G05b, việc lưu 9:00',
      (tester) async {
    await caregiverSends(tester, shared, message: '');
    final mom = App(shared);
    await mom.pump(tester, width: 412, height: 915);
    await tap(tester, inPopup('Xem gợi ý'));
    await tap(tester, find.text('Đổi giờ đi bộ nhẹ nhàng'));
    await tap(tester, find.text('9:00 sáng'));
    await tap(tester, find.text('Lưu giờ mới'));
    expect(mom.tasks.saved, isEmpty);
    await tap(tester, find.text('Thêm vào lịch'));
    expect(find.text('Bác có thể đổi giờ hoặc ngưng nhắc.'), findsOneWidget);
    expect(
        mom.tasks.saved.values.firstWhere((t) => t.habitKey == 'move').hour, 9);
    expect(mom.analytics.paramsOf('accept_suggestion').single!['changed_time'],
        isTrue);
    await mom.close(tester);
  });

  testWidgets(
      'chọn từng việc: G06 → bỏ chọn thư giãn → Tiếp tục → G07, gợi ý partial',
      (tester) async {
    await caregiverSends(tester, shared);
    final mom = App(shared);
    await mom.pump(tester, width: 412, height: 915);
    await tap(tester, inPopup('Xem gợi ý'));
    await tap(tester, find.text('Chọn từng việc'));
    await tap(tester, find.text('Thư giãn nhẹ nhàng'));
    await tap(tester, find.text('Tiếp tục'));
    expect(find.text('1 việc đã nhận'), findsOneWidget);
    expect(
        [for (final t in mom.tasks.saved.values) t.title], ['Đi bộ nhẹ nhàng']);
    final s = (await tester.runAsync(() => shared.watchPending(momUid).first))!;
    expect(s, isEmpty, reason: 'partial không còn pending');
    expect(
        mom.analytics.paramsOf('accept_suggestion').single!['partial'], isTrue);
    expectNoPersonalData([mom.analytics]);
    await mom.close(tester);
  });

  testWidgets('TC-27: bỏ qua → G09 → Hoàn tác → G03; không báo người gửi',
      (tester) async {
    await caregiverSends(tester, shared);
    final mom = App(shared);
    await mom.pump(tester, width: 412, height: 915);
    await tap(tester, inPopup('Xem gợi ý'));
    await tap(tester, find.text('Bỏ qua gợi ý'));
    expect(find.text('Đã bỏ qua gợi ý'), findsOneWidget);
    expect(mom.tasks.saved, isEmpty);
    expect(shared.senderNotified, 0);
    await tap(tester, find.widgetWithText(AppButton, 'Hoàn tác'));
    expect(find.text('Mai gửi lịch cho Bác'), findsOneWidget);
    final pending =
        (await tester.runAsync(() => shared.watchPending(momUid).first))!;
    expect(pending.single.status, SuggestionStatus.pending);
    expect(shared.senderNotified, 0);
    expect(mom.analytics.paramsOf('dismiss_suggestion').single, {'items': 2});
    expect(mom.analytics.paramsOf('undo_action').single,
        {'action': 'dismiss_suggestion'});
    await mom.close(tester);
  });

  testWidgets('TC-28: "Để sau" → thẻ G12; mở lại app → popup không hiện lại',
      (tester) async {
    await caregiverSends(tester, shared);
    final first = App(shared);
    await first.pump(tester, width: 412, height: 915);
    await tap(tester, inPopup('Để sau'));
    expect(find.text('Mai gửi Bác 2 việc'), findsOneWidget);
    await first.close(tester);

    final again = App(shared);
    await again.pump(tester, width: 412, height: 915);
    expect(popup, findsNothing);
    expect(find.text('Mai gửi Bác 2 việc'), findsOneWidget);
    await tap(tester, find.text('Xem gợi ý'));
    await tap(tester, find.text('Thêm vào lịch'));
    expect(again.analytics.paramsOf('accept_suggestion').single!['taps'] as int,
        lessThanOrEqualTo(2));
    await again.close(tester);
  });
}
