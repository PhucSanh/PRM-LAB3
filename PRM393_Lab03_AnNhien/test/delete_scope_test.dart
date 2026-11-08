import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/habit_guide.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart' as schedule;
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/viewmodels/task_form_view_model.dart';
import 'package:an_nhien/widgets/task_detail_parts.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/demo_container.dart';

/// 10:00 sáng giờ Việt Nam, 05/11/2026.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 5, 3));

const _daily = TaskItem(
    id: 'walk',
    title: 'Đi bộ công viên',
    habitKey: 'move',
    hour: 16,
    minute: 0,
    durationMinutes: 30,
    repeat: RepeatRule.daily,
    startDate: '2026-11-01');

/// Repository ghi lại phạm vi xoá mà ViewModel gửi xuống.
class _ScopeSpy extends FakeTaskRepository implements ScopedTaskRepository {
  _ScopeSpy() : super([_daily]);
  final scopes = <schedule.ChangeScope>[];
  @override
  Future<schedule.ScheduleUndo> changeOccurrence(TaskItem original,
      DateTime day, TaskItem? replacement, schedule.ChangeScope scope) async {
    scopes.add(scope);
    return schedule.ScheduleUndo('demo-user', const {}, const {});
  }

  @override
  Future<void> undoOccurrence(schedule.ScheduleUndo change) async {}
}

Future<(ProviderContainer, _ScopeSpy)> _pump(WidgetTester tester,
    {double scale = 1}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final spy = _ScopeSpy();
  final c = demoContainer(taskRepository: spy);
  addTearDown(c.dispose);
  await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const AnNhienApp()));
  await tester.pumpAndSettle();
  c.read(routerProvider).go('/today/task/walk/edit?date=2026-11-05');
  await tester.pumpAndSettle();
  return (c, spy);
}

Future<void> _openDelete(WidgetTester tester) async {
  final button = find.text('Xóa việc');
  await tester.scrollUntilVisible(button, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 400));
}

void _test(String name, WidgetTesterCallback body) =>
    testWidgets(name, (tester) => withClock(_clock, () => body(tester)));

void main() {
  for (final (label, scope) in [
    ('Xóa lần này', schedule.ChangeScope.occurrence),
    ('Xóa hết trong lịch', schedule.ChangeScope.all),
  ]) {
    _test('hộp xoá việc lặp: "$label" → $scope', (tester) async {
      final (_, spy) = await _pump(tester);
      await _openDelete(tester);
      expect(find.text('Xóa lần này'), findsOneWidget);
      expect(find.text('Xóa hết trong lịch'), findsOneWidget);
      expect(find.text('Không xóa, giữ lại'), findsOneWidget);
      // Ở 360×800, chữ ×1: cả 3 nút phải thấy ngay, không cần cuộn.
      for (final b in [
        'Không xóa, giữ lại',
        'Xóa lần này',
        'Xóa hết trong lịch'
      ]) {
        expect(tester.getRect(find.text(b)).bottom, lessThan(800), reason: b);
      }
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(spy.scopes, [scope]);
      expect(find.text('Hoàn tác'), findsOneWidget);
      await _close(tester);
    });
  }

  _test('"Không xóa, giữ lại" thì không xoá gì', (tester) async {
    final (_, spy) = await _pump(tester);
    await _openDelete(tester);
    await tester.tap(find.text('Không xóa, giữ lại'));
    await tester.pumpAndSettle();
    expect(spy.scopes, isEmpty);
    await _close(tester);
  });

  _test('hộp xoá không tràn khi chữ ×2', (tester) async {
    await _pump(tester, scale: 2);
    await _openDelete(tester);
    expect(tester.takeException(), isNull);
    await _close(tester);
  });

  test('ViewModel: việc một lần xoá cả việc; ChangeScope.all xoá mọi lần',
      () async {
    final spy = _ScopeSpy();
    final c = demoContainer(taskRepository: spy);
    addTearDown(c.dispose);
    final vm = c.read(taskFormViewModelProvider.notifier);
    await withClock(_clock, () async {
      expect(await vm.startEdit('walk', day: DateTime(2026, 11, 5)), isTrue);
      expect(await vm.delete(ChangeScope.all), isTrue);
    });
    expect(spy.scopes, [schedule.ChangeScope.all]);
  });

  test('mỗi thói quen có ảnh thật trong assets', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final key in [
      'move',
      'downshift',
      'family',
      'tea',
      'plant',
      'eighty',
      'purpose',
      'belong',
      'tribe'
    ]) {
      final photos = habitPhotosOf(key);
      expect(photos, isNotEmpty, reason: key);
      for (final photo in photos) {
        expect((await rootBundle.load(photo)).lengthInBytes, greaterThan(10000),
            reason: photo);
      }
    }
  });

  _test('màn chi tiết có ảnh lớn và dải "Hình ảnh"', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = demoContainer(
        initialRoute: '/calendar/task/walk?date=2026-11-05',
        taskRepository: FakeTaskRepository([_daily]));
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    final hero = find.descendant(
        of: find.byType(TaskHeroArt), matching: find.byType(Image));
    expect(hero, findsOneWidget);
    expect((tester.widget<Image>(hero).image as AssetImage).assetName,
        'assets/images/habits/move_0.jpg');
    expect(find.text('Hình ảnh', skipOffstage: false), findsOneWidget);
    expect(find.byType(HabitPhotoStrip, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester);
  });
}
