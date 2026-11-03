import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/caregiver_schedule_service.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/viewmodels/caregiver_form_view_model.dart';
import 'package:an_nhien/viewmodels/caregiver_schedule_view_model.dart';
import 'package:an_nhien/widgets/app_text_field.dart';
import 'support/demo_container.dart';

TaskItem seed() => TaskItem(
    id: 'walk',
    title: 'Đi bộ buổi sáng',
    habitKey: 'move',
    hour: 8,
    minute: 0,
    startDate: dateKey(vietnamToday()));
Future<void> mount(WidgetTester tester, ProviderContainer c,
    {GlobalKey? boundary}) async {
  await tester.pumpWidget(RepaintBoundary(
      key: boundary,
      child:
          UncontrolledProviderScope(container: c, child: const AnNhienApp())));
  await tester.pumpAndSettle();
}

Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  c.dispose();
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('BeVietnamPro')
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'));
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  testWidgets(
      '3-step consent flow sends once, mother receives once and schedule updates',
      (tester) async {
    final schedules = FakeCaregiverScheduleService();
    final suggestions = FakeSuggestionService(onAccept: schedules.acceptTasks);
    final c = demoContainer(schedules: schedules, suggestions: suggestions);
    await mount(tester, c);
    final router = c.read(routerProvider);
    router.go('/caregiver/schedule');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo lịch cho mẹ'));
    await tester.pumpAndSettle();
    // Blank form cannot advance and provides a concrete example.
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ví dụ: Đi bộ buổi sáng.'), findsWidgets);
    final field = find.descendant(
        of: find.widgetWithText(AppTextField, 'Tên việc'),
        matching: find.byType(TextField));
    await tester.scrollUntilVisible(find.byType(AppTextField), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Uống trà chiều');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        '/caregiver/task/new/repeat');
    await tester.tap(find.text('Xem lại'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        '/caregiver/task/new/review');
    await tester.tap(find.text('Gửi lịch cho mẹ'));
    await tester.pumpAndSettle();
    expect(find.text('Đã gửi gợi ý cho mẹ'), findsOneWidget);
    expect(suggestions.suggestions.length, 1);
    expect(schedules.tasks, isEmpty);
    router.go('/settings/firebase-demo/suggestions');
    await tester.pumpAndSettle();
    final accept = find.text('Thêm việc đã chọn vào lịch');
    await tester.ensureVisible(accept);
    await tester.tap(accept);
    await tester.pumpAndSettle();
    expect(schedules.tasks.length, 1);
    expect(schedules.tasks.values.single.title, 'Uống trà chiều');
    router.go('/caregiver/schedule');
    await tester.pumpAndSettle();
    expect(c.read(caregiverScheduleViewModelProvider).items, isNotNull);
    await unmount(tester, c);
    await schedules.dispose();
    await suggestions.dispose();
  });
  testWidgets(
      'conflict requires confirmation, failed save keeps draft, retry is idempotent',
      (tester) async {
    final schedules = FakeCaregiverScheduleService([seed()]);
    final c = demoContainer(schedules: schedules);
    await mount(tester, c);
    final vm = c.read(caregiverFormViewModelProvider.notifier);
    vm.start();
    vm.updateTask(c
        .read(caregiverFormViewModelProvider)
        .task
        .copyWith(title: 'Đi bộ cùng mẹ'));
    vm.consent(false);
    expect(await vm.submit(), false);
    expect(c.read(caregiverFormViewModelProvider).conflicts, isNotEmpty);
    schedules.fail = true;
    expect(await vm.submit(allowConflict: true), false);
    expect(c.read(caregiverFormViewModelProvider).task.title, 'Đi bộ cùng mẹ');
    schedules.fail = false;
    expect(await vm.submit(allowConflict: true), true);
    expect(await vm.submit(allowConflict: true), false);
    expect(schedules.tasks.length, 2);
    await unmount(tester, c);
    await schedules.dispose();
  });
  for (final width in [360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'F13/F14 layouts $width dp x$scale, data/empty/error and month selection',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final schedules = FakeCaregiverScheduleService([seed()]);
        final c = demoContainer(schedules: schedules);
        final boundary = GlobalKey();
        await mount(tester, c, boundary: boundary);
        final router = c.read(routerProvider);
        final form = c.read(caregiverFormViewModelProvider.notifier);
        form.start();
        form.updateTask(c
            .read(caregiverFormViewModelProvider)
            .task
            .copyWith(title: 'Đi bộ buổi sáng'));
        for (final route in [
          '/caregiver/pair',
          '/pairing/code',
          '/caregiver/schedule',
          '/caregiver/schedule?view=week',
          '/caregiver/schedule?view=month',
          '/caregiver/task/new',
          '/caregiver/task/new/repeat',
          '/caregiver/task/new/review',
          '/caregiver/task/walk?date=${dateKey(vietnamToday())}',
          '/settings/firebase-demo/suggestions'
        ]) {
          debugPrint("Checking $route");
          router.go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$route at $width x$scale');
          if (route == '/caregiver/schedule?view=month')
            expect(c.read(caregiverScheduleViewModelProvider).view,
                CalendarView.month);
          if (const bool.fromEnvironment('CAPTURE_UI') &&
              width == 360 &&
              scale == 1 &&
              [
                '/caregiver/pair',
                '/caregiver/schedule',
                '/caregiver/task/new',
                '/caregiver/task/new/review'
              ].contains(route)) {
            final name = route.replaceAll('/', '_');
            await tester.runAsync(() async {
              final image = await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              await Directory('/tmp/hieu-ui').create(recursive: true);
              await File('/tmp/hieu-ui/$name.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
        router.go('/caregiver/schedule');
        await tester.pumpAndSettle();
        schedules.fail = true;
        c.read(caregiverScheduleViewModelProvider.notifier).load();
        await tester.pumpAndSettle();
        for (var i = 0;
            i < 10 && find.text('Thử lại').hitTestable().evaluate().isEmpty;
            i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        expect(find.text('Thử lại').hitTestable(), findsOneWidget);
        schedules.fail = false;
        await tester.tap(find.text('Thử lại').hitTestable());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await unmount(tester, c);
        await schedules.dispose();
      });
    }
  }
}
