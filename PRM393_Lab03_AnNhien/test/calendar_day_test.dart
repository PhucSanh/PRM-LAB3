import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/voice_task_draft.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/screens/calm/calendar_screen.dart';
import 'package:an_nhien/widgets/task_detail_parts.dart';
import 'package:an_nhien/services/voice_task_service.dart';
import 'package:an_nhien/viewmodels/daily_actions_view_model.dart';
import 'package:an_nhien/viewmodels/device_access_view_model.dart';
import 'package:an_nhien/viewmodels/session_view_model.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'device_access_flow_test.dart' show TestDevice;
import 'support/demo_container.dart';

/// 10:00 sáng giờ Việt Nam, 05/11/2026.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 5, 3));

TaskItem _task(String id, String title, int hour,
        {TaskStatus status = TaskStatus.pending, int duration = 30}) =>
    TaskItem(
        id: id,
        title: title,
        habitKey: 'move',
        hour: hour,
        minute: 0,
        durationMinutes: duration,
        status: status);

final _day = [
  _task('a', 'Tưới rau sáng sớm', 6, status: TaskStatus.done),
  _task('b', 'Uống thuốc buổi sáng', 8),
  _task('c', 'Đi bộ công viên', 11),
  _task('d', 'Ăn trưa nhẹ nhàng', 12),
  _task('e', 'Ngủ trưa thư giãn', 13),
  _task('f', 'Gọi điện cho Mai', 18),
];

Future<ProviderContainer> _pump(WidgetTester tester, String route,
    {VoiceTaskService? voice, double width = 360, double scale = 1}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = demoContainer(
      initialRoute: route,
      tasks: _day,
      voiceTasks: voice,
      device: TestDevice());
  addTearDown(c.dispose);
  await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const AnNhienApp()));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 400));
}

void _test(String name, WidgetTesterCallback body) =>
    testWidgets(name, (tester) => withClock(_clock, () => body(tester)));

void main() {
  test('việc còn lại hôm nay theo giờ, bỏ việc đã xong và đã kết thúc', () {
    final now = DateTime(2026, 11, 5, 11, 15);
    expect(upcomingTasks(_day, now).map((t) => t.id), ['c', 'd', 'e', 'f']);
    expect(upcomingTasks(_day, now, except: 'c').map((t) => t.id),
        ['d', 'e', 'f']);
  });

  _test('Trang chủ chỉ hiện việc kế tiếp + 2 việc sau đó', (tester) async {
    await _pump(tester, '/calendar');
    // 10:00: việc 8:00 đã qua giờ thì không hiện; việc kế tiếp là 11:00.
    expect(
        find.text('Uống thuốc buổi sáng', skipOffstage: false), findsNothing);
    expect(find.text('Đi bộ công viên', skipOffstage: false), findsOneWidget);
    expect(find.text('Ăn trưa nhẹ nhàng', skipOffstage: false), findsOneWidget);
    expect(find.text('Tiếp theo', skipOffstage: false), findsOneWidget);
    expect(find.text('Gọi điện cho Mai', skipOffstage: false), findsNothing);
    expect(find.text('Tưới rau sáng sớm', skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  testWidgets('Trang chủ: việc đang diễn ra vẫn hiện; hết việc thì ẩn thẻ',
      (tester) async {
    // 11:15: việc 11:00 (30 phút) đang diễn ra nên vẫn là việc sắp tới.
    await withClock(Clock.fixed(DateTime.utc(2026, 11, 5, 4, 15)), () async {
      await _pump(tester, '/calendar');
      expect(find.text('Đi bộ công viên', skipOffstage: false), findsOneWidget);
      await _close(tester);
    });
    // 23:30: mọi việc đã qua giờ → không còn thẻ "Việc sắp tới".
    await withClock(Clock.fixed(DateTime.utc(2026, 11, 5, 16, 30)), () async {
      await _pump(tester, '/calendar');
      expect(find.text('Việc sắp tới', skipOffstage: false), findsNothing);
      expect(find.text('Gọi điện cho Mai', skipOffstage: false), findsNothing);
      expect(find.byKey(const Key('calendar-day-detail'), skipOffstage: false),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  });

  _test('"Xem chi tiết lịch hôm nay" mở toàn bộ lịch trong ngày',
      (tester) async {
    final c = await _pump(tester, '/calendar');
    final button = find.byKey(const Key('calendar-day-detail'));
    await tester.scrollUntilVisible(button, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.toString(),
        '/calendar/day?date=2026-11-05');
    expect(find.text('Lịch của Bác'), findsOneWidget);
    expect(find.text('6 hoạt động'), findsOneWidget);
    for (final t in _day) {
      expect(
          find.descendant(
              of: find.byType(CalendarDayScreen),
              matching: find.text(t.title, skipOffstage: false),
              skipOffstage: false),
          findsOneWidget,
          reason: t.title);
    }
    await tester.tap(find.byTooltip('Ngày sau'));
    await tester.pumpAndSettle();
    expect(find.text('Về hôm nay'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  _test('link cũ /calendar?date= mở trang lịch của ngày đó', (tester) async {
    final c = await _pump(tester, '/calendar?date=2030-02-03');
    expect(c.read(routerProvider).state.uri.path, '/calendar/day');
    expect(find.text('Chủ Nhật, 3/2/2030'), findsOneWidget);
    await _close(tester);
  });

  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      _test('không tràn · $width dp · ×$scale', (tester) async {
        await _pump(tester, '/calendar', width: width, scale: scale);
        expect(tester.takeException(), isNull);
        await _close(tester);
        await _pump(tester, '/calendar/day?date=2026-11-05',
            width: width, scale: scale);
        expect(tester.takeException(), isNull);
        await _close(tester);
      });
    }
  }

  _test('AI thêm việc ngày mai → nút mở đúng lịch ngày đó', (tester) async {
    final voice = FakeVoiceTaskService(
        result: VoiceTaskInterpretation(
            draft: VoiceTaskDraft(
                title: 'Tưới cây',
                date: DateTime(2026, 11, 6),
                hour: 7,
                minute: 0,
                durationMinutes: 20,
                repeat: RepeatRule.once,
                weekdays: const [],
                habitKey: 'move'),
            question: null));
    final c = await _pump(tester, '/today/voice', voice: voice);
    await c.read(sessionProvider.future);
    final vm = c.read(voiceInputViewModelProvider.notifier)
      ..edit('Mai 7 giờ sáng tưới cây 20 phút');
    await tester.runAsync(() async {
      await vm.analyze();
      expect(await vm.addToSchedule(), isNotNull);
    });
    await tester.pumpAndSettle();
    expect(c.read(voiceInputViewModelProvider).reply, contains('6/11/2026'));
    final open = find.byKey(const Key('voice-open-day'));
    expect(find.text('Xem lịch ngày 6/11'), findsOneWidget);
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.toString(),
        '/calendar/day?date=2026-11-06');
    expect(find.text('Tưới cây', skipOffstage: false), findsOneWidget);
    await _close(tester);
  });

  _test('thanh dưới: Khám phá gộp Thói quen, có tab Lịch', (tester) async {
    final c = await _pump(tester, '/calendar');
    for (final label in [
      'Trang chủ',
      'Khám phá',
      'Lịch',
      'Gia đình',
      'Cá nhân'
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Thói quen'), findsNothing);
    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.path, '/calendar/day');
    expect(find.text('Lịch của Bác'), findsOneWidget);
    // Là tab nên không có nút Quay lại.
    expect(find.text('Quay lại'), findsNothing);
    await tester.tap(find.text('Khám phá'));
    await tester.pumpAndSettle();
    expect(find.text('Thói quen'), findsNothing); // đã gộp vào Khám phá
    expect(find.text('Gợi ý mỗi ngày'), findsOneWidget);
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.path, '/calendar');
    await _close(tester);
  });

  _test('chi tiết việc: nhiều thông tin, hình minh hoạ, Đọc to cả màn',
      (tester) async {
    final device = TestDevice();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = demoContainer(
        initialRoute: '/calendar/task/c?date=2026-11-05',
        tasks: _day,
        device: device);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    for (final label in [
      'Đi bộ công viên',
      'Giờ làm',
      '11:00 – 11:30',
      'Làm trong',
      '30 phút',
      'Lặp lại',
      'Nhắc nhở',
      'Vì sao tốt cho Bác',
      'Bác chuẩn bị',
      'Giày dép êm, vừa chân',
      'Cách làm',
    ]) {
      expect(find.text(label, skipOffstage: false), findsWidgets,
          reason: label);
    }
    expect(find.byType(TaskHeroArt), findsOneWidget);
    expect(find.byType(PrepareGallery, skipOffstage: false), findsOneWidget);
    expect(find.text('Đọc to', skipOffstage: false), findsOneWidget);
    await tester.ensureVisible(find.text('Đọc to'));
    await tester.tap(find.text('Đọc to'));
    await tester.pumpAndSettle();
    expect(device.spoken, contains('Đi bộ công viên'));
    expect(device.spoken, contains('11 giờ 0 phút'));
    expect(device.spoken, contains('Bác chuẩn bị: Giày dép êm'));
    expect(device.spoken, contains('Bước 1:'));
    expect(device.spoken, contains('Lưu ý:'));
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  for (final scale in [1.0, 2.0]) {
    _test('chi tiết việc không tràn · 360 dp · ×$scale', (tester) async {
      await _pump(tester, '/calendar/task/c?date=2026-11-05', scale: scale);
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  }
}
