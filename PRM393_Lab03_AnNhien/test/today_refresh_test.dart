import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/screens/today/today_screen.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/crash_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/today_view_model.dart';
import 'package:an_nhien/viewmodels/ui_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class BrokenAnalytics extends FakeAnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    throw StateError('offline analytics');
  }
}

class BrokenRepository extends FakeTaskRepository {
  BrokenRepository(super.seed);
  @override
  Future<void> setStatus(String taskId, TaskStatus status) async {
    throw StateError('offline write');
  }
}

const task = TaskItem(
    id: 'a', title: 'Đi bộ quanh vườn', habitKey: 'move', hour: 7, minute: 0);
void main() {
  setUpAll(() async {
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('BeVietnamPro')
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf')))
        .load();
  });

  final boundary = GlobalKey();
  Future<ProviderContainer> open(WidgetTester tester,
      {double scale = 1,
      TaskRepository? repository,
      bool contrast = false}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = ProviderContainer(overrides: [
      taskRepositoryProvider
          .overrideWithValue(repository ?? FakeTaskRepository([task])),
      analyticsServiceProvider.overrideWithValue(BrokenAnalytics()),
      crashServiceProvider.overrideWithValue(FakeCrashService()),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
            theme: contrast ? AppTheme.highContrast() : AppTheme.light(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: RepaintBoundary(key: boundary, child: const TodayScreen()))));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('save survives analytics error, undo restores pending',
      (tester) async {
    final c = await open(tester);
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('/tmp/annhien-today.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.ensureVisible(find.text('Đã làm xong'));
    await tester.tap(find.text('Đã làm xong'));
    await tester.pumpAndSettle();
    expect((c.read(todayViewModelProvider) as UiData<TodayData>).data.doneCount,
        1);
    expect(find.text('Hoàn tác'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect((c.read(todayViewModelProvider) as UiData<TodayData>).data.doneCount,
        0);
    expect(find.text('Việc tiếp theo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed write keeps task and reports failure', (tester) async {
    final c = await open(tester, repository: BrokenRepository([task]));
    await tester.ensureVisible(find.text('Đã làm xong'));
    await tester.tap(find.text('Đã làm xong'));
    await tester.pumpAndSettle();
    expect((c.read(todayViewModelProvider) as UiData<TodayData>).data.doneCount,
        0);
    expect(find.text('Chưa lưu được. Bác thử lại nhé.'), findsOneWidget);
    expect(find.text('Hoàn tác'), findsNothing);
  });
  for (final scale in [1.0, 1.3, 2.0]) {
    for (final contrast in [false, true]) {
      testWidgets('360px scale $scale contrast $contrast no overflow',
          (tester) async {
        await open(tester,
            scale: scale,
            contrast: contrast,
            repository: FakeTaskRepository([
              task.copyWith(
                  title:
                      'Đi bộ nhẹ nhàng cùng người thân quanh khu vườn buổi sáng'),
              task.copyWith(id: 'done', status: TaskStatus.done),
              task.copyWith(id: 'postponed', status: TaskStatus.postponed),
              task.copyWith(id: 'skip', status: TaskStatus.skipped),
            ]));
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.text('Đã hoàn thành (1)'), 250,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('Đã hoàn thành (1)'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
