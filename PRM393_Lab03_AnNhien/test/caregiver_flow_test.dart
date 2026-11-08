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
import 'package:an_nhien/services/caregiver_suggestion_service.dart';
import 'package:an_nhien/viewmodels/caregiver_form_view_model.dart';
import 'package:an_nhien/viewmodels/caregiver_schedule_view_model.dart';
import 'package:an_nhien/widgets/app_text_field.dart';
import 'package:an_nhien/widgets/app_button.dart';
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
  testWidgets('untouched form exits without discard dialog', (tester) async {
    final c = demoContainer();
    await mount(tester, c);
    final router = c.read(routerProvider);
    router.go('/caregiver/task/new');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Rời màn khi chưa lưu?'), findsNothing);
    expect(
        router.routeInformationProvider.value.uri.path, '/caregiver/schedule');
    await unmount(tester, c);
  });

  testWidgets('discarding changed form clears draft only after confirmation',
      (tester) async {
    final c = demoContainer();
    await mount(tester, c);
    final router = c.read(routerProvider);
    router.go('/caregiver/task/new');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uống trà'));
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(c.read(caregiverFormViewModelProvider).task.title, 'Uống trà');
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(
        router.routeInformationProvider.value.uri.path, '/caregiver/schedule');
    expect(c.read(caregiverFormViewModelProvider).task.title, isEmpty);
    expect(c.read(caregiverFormViewModelProvider).dirty, isFalse);
    await unmount(tester, c);
  });

  testWidgets('repeat is optional, edits survive review and return',
      (tester) async {
    final c = demoContainer();
    await mount(tester, c);
    final router = c.read(routerProvider);
    router.go('/caregiver/task/new');
    await tester.pumpAndSettle();
    final scroll = find
        .descendant(
            of: find.byType(ListView).first, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
        find.widgetWithText(AppButton, 'Đổi ngày hoặc lịch lặp'), 250,
        scrollable: scroll);
    await tester.tap(find.text('Đổi ngày hoặc lịch lặp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mỗi ngày'));
    await tester.tap(find.text('Dùng lịch này'));
    await tester.pumpAndSettle();
    expect(
        router.routeInformationProvider.value.uri.path, '/caregiver/task/new');
    await tester.ensureVisible(find.text('Uống trà'));
    await tester.tap(find.text('Uống trà'));
    await tester.tap(find.text('Xem lại'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        '/caregiver/task/new/review');
    final edit = find.text('Sửa thông tin lịch');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(c.read(caregiverFormViewModelProvider).task.title, 'Uống trà');
    expect(
        c.read(caregiverFormViewModelProvider).task.repeat, RepeatRule.daily);
    expect(
        router.routeInformationProvider.value.uri.path, '/caregiver/task/new');
    await unmount(tester, c);
  });

  testWidgets('calendar preserves date and view, Today returns in one tap',
      (tester) async {
    final c = demoContainer();
    await mount(tester, c);
    final router = c.read(routerProvider);
    router.go('/caregiver/schedule?view=week');
    await tester.pumpAndSettle();
    final vm = c.read(caregiverScheduleViewModelProvider.notifier);
    final tomorrow = vietnamToday().add(const Duration(days: 1));
    vm.selectDate(tomorrow);
    await tester.pumpAndSettle();
    router.go('/account');
    await tester.pumpAndSettle();
    router.go('/caregiver/schedule');
    await tester.pumpAndSettle();
    expect(c.read(caregiverScheduleViewModelProvider).view, CalendarView.week);
    expect(c.read(caregiverScheduleViewModelProvider).date, tomorrow);
    final today = find.text('Về hôm nay');
    await tester.scrollUntilVisible(today, 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    await tester.tap(today);
    await tester.pumpAndSettle();
    expect(c.read(caregiverScheduleViewModelProvider).date, vietnamToday());
    await unmount(tester, c);
  });

  testWidgets('pairing filters pasted code, enables action at six digits',
      (tester) async {
    final c = demoContainer();
    await mount(tester, c);
    c.read(routerProvider).go('/caregiver/pair');
    await tester.pumpAndSettle();
    AppButton action() => tester.widget<AppButton>(
        find.byWidgetPredicate((w) => w is AppButton && w.label == 'Ghép nối'));
    expect(action().onPressed, isNull);
    final field = find.byType(TextField);
    await tester.scrollUntilVisible(field, 200,
        scrollable: find.byType(Scrollable).last);
    await tester.enterText(field, '12a 3456');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '123456');
    expect(action().onPressed, isNotNull);
    await unmount(tester, c);
  });

  testWidgets('quick activity and time fill form without typing',
      (tester) async {
    final c = demoContainer();
    await mount(tester, c);
    c.read(routerProvider).go('/caregiver/task/new');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uống trà'));
    await tester.pumpAndSettle();
    var task = c.read(caregiverFormViewModelProvider).task;
    expect(task.title, 'Uống trà');
    expect(task.habitKey, 'tea');
    await tester.scrollUntilVisible(find.textContaining('15:00'), 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
    await tester.ensureVisible(find.textContaining('15:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('15:00'));
    await tester.pumpAndSettle();
    task = c.read(caregiverFormViewModelProvider).task;
    expect(task.hour, 15);
    expect(task.minute, 0);
    await tester.tap(find.text('Xem lại'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/caregiver/task/new/review');
    await unmount(tester, c);
  });
  testWidgets(
      '2-step consent flow sends once, mother receives once and schedule updates',
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
    await tester.tap(find.text('Xem lại'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ví dụ: Đi bộ buổi sáng.'), findsWidgets);
    final field = find.descendant(
        of: find.widgetWithText(AppTextField, 'Tên việc'),
        matching: find.byType(TextField));
    await tester.scrollUntilVisible(find.byType(AppTextField), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Uống trà chiều');
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
    final review = find.text('Xem lại lựa chọn');
    await tester.scrollUntilVisible(review, 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(suggestions.acceptedTasks, isEmpty);
    final accept = find.text('Thêm việc đã chọn vào lịch');
    await tester.scrollUntilVisible(accept, 150,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
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
    // Direct writes cannot override the shared schedule conflict rule.
    expect(await vm.submit(allowConflict: true), false);
    vm.updateTask(
        c.read(caregiverFormViewModelProvider).task.copyWith(hour: 10));
    schedules.fail = true;
    expect(await vm.submit(), false);
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
          if (route == '/caregiver/schedule?view=month') {
            expect(c.read(caregiverScheduleViewModelProvider).view,
                CalendarView.month);
          }
          if (const bool.fromEnvironment('CAPTURE_UI') &&
              width == 360 &&
              scale == 1 &&
              [
                '/caregiver/pair',
                '/caregiver/schedule',
                '/caregiver/schedule?view=week',
                '/caregiver/schedule?view=month',
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
