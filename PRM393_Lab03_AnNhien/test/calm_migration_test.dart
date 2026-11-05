import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/user_profile.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/viewmodels/calm_feature_providers.dart';
import 'package:an_nhien/viewmodels/caregiver_schedule_view_model.dart';
import 'package:an_nhien/widgets/botanical_scene.dart';
import 'package:an_nhien/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/demo_container.dart';

const task = TaskItem(
    id: 'real-task',
    title: 'Đi bộ cùng gia đình',
    habitKey: 'move',
    hour: 8,
    minute: 30);

Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  String route, {
  double width = 390,
  double height = 844,
  double scale = 1,
  UserRole role = UserRole.elder,
  TaskRepository? repository,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final container = demoContainer(
      initialRoute: route,
      role: role,
      taskRepository: repository,
      tasks: const [task]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container, child: const AnNhienApp()));
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapText(WidgetTester tester, String label) async {
  final base = find.text(label);
  if (base.evaluate().isEmpty) {
    await tester.scrollUntilVisible(base, 300,
        scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
  }
  final finder = base.last;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> closeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader(AppTheme.fontFamily);
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await fonts.load();
    final welcomeSerif = FontLoader('NotoSerif')
      ..addFont(rootBundle.load('assets/fonts/NotoSerif-Regular.ttf'));
    await welcomeSerif.load();
    final serif = FontLoader('NotoSerifDisplay')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifDisplay-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSerifDisplay-Bold.ttf'));
    await serif.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  test('production default is the reference introduction', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(initialRouteProvider), '/intro');
  });
  testWidgets('reference intro paging opens main and five real destinations',
      (tester) async {
    final container = await pumpApp(tester, '/intro');
    final router = container.read(routerProvider);
    expect(find.text('An Nhiên'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-390, 0));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Dành thời gian cho những điều mình yêu thích, theo nhịp riêng của Bác.'),
        findsOneWidget);
    await tapText(tester, 'Bắt đầu');
    expect(router.routeInformationProvider.value.uri.path, '/calendar');
    for (final (label, path, section) in [
      ('Khám phá', '/activities', 'explore'),
      ('Thói quen', '/activities', 'habits'),
      ('Gia đình', '/family', ''),
      ('Cá nhân', '/account', ''),
    ]) {
      await tester.tap(find.bySemanticsLabel(label).last);
      await tester.pumpAndSettle();
      if (path == '/account') {
        expect(find.text('Tài khoản'), findsWidgets);
        expect(router.canPop(), isTrue);
      } else {
        expect(router.routeInformationProvider.value.uri.path, path);
      }
      if (section.isNotEmpty) {
        expect(
            router
                .routeInformationProvider.value.uri.queryParameters['section'],
            section);
      }
    }
    router.pop();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/family');
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });
  testWidgets(
      'caregiver default Calendar and Family resolve to the correct shell',
      (tester) async {
    final container =
        await pumpApp(tester, '/calendar', role: UserRole.caregiver);
    final router = container.read(routerProvider);
    expect(
        router.routeInformationProvider.value.uri.path, '/caregiver/schedule');
    router.go('/family');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/caregiver/family');
    expect(find.text('Hoạt động'), findsNothing);
    await closeApp(tester);
  });
  testWidgets('calendar date, activity segment and Back survive branch changes',
      (tester) async {
    final container = await pumpApp(tester, '/calendar?date=2026-11-06');
    final router = container.read(routerProvider);
    expect(dateKey(container.read(calendarDateProvider)), '2026-11-06');
    router.go('/activities?section=habits');
    await tester.pumpAndSettle();
    await tapText(tester, 'Vận động tự nhiên');
    expect(find.text('Bắt đầu từ một việc nhỏ'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.queryParameters['section'],
        'habits');
    await tester.tap(find.bySemanticsLabel('Trang chủ').last);
    await tester.pumpAndSettle();
    expect(dateKey(container.read(calendarDateProvider)), '2026-11-06');
    expect(find.text('Hôm nay'), findsNothing);
    expect(find.byType(ConfirmDialog<bool>), findsNothing);
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });
  testWidgets('caregiver shell keeps date/view and has no elder activity tab',
      (tester) async {
    final container = await pumpApp(
        tester, '/caregiver/schedule?date=2026-11-06&view=week',
        role: UserRole.caregiver);
    await tester.tap(find.bySemanticsLabel('Gia đình').last);
    await tester.pumpAndSettle();
    expect(find.text('Hoạt động'), findsNothing);
    expect(find.text('Đã kết nối với người thân'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Lịch').last);
    await tester.pumpAndSettle();
    final uri =
        container.read(routerProvider).routeInformationProvider.value.uri;
    expect(uri.queryParameters['date'], '2026-11-06');
    expect(uri.queryParameters['view'], 'week');
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });
  testWidgets(
      'legacy week/habit aliases and task details read actual repositories',
      (tester) async {
    final container = await pumpApp(tester, '/week/2026-11-06');
    final router = container.read(routerProvider);
    expect(router.routeInformationProvider.value.uri.path, '/calendar');
    expect(find.text(task.title), findsOneWidget);
    router.go('/week/2026-11-06/task/${task.id}');
    await tester.pumpAndSettle();
    expect(find.text(task.title), findsOneWidget);
    expect(find.text('Hoàn thành'),
        findsNothing); // not today; TODAY-only mutation contract
    router.go('/habits/move');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path,
        '/activities/habits/move');
    expect(find.text('Vận động tự nhiên'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });
  testWidgets('complete and Undo write real repository status on today only',
      (tester) async {
    final repository = FakeTaskRepository(const [task]);
    final day = dateKey(vietnamToday());
    final container = await pumpApp(
        tester, '/calendar/task/${task.id}?date=$day',
        repository: repository);
    await tapText(tester, 'Hoàn thành');
    final saved = repository.tasksForDay(vietnamToday());
    await tester.pump(const Duration(milliseconds: 310));
    expect((await saved).single.status, TaskStatus.done);
    container.read(routerProvider).go('/calendar');
    await tester.pumpAndSettle();
    await tapText(tester, 'Hoàn tác');
    final restored = repository.tasksForDay(vietnamToday());
    await tester.pump(const Duration(milliseconds: 310));
    expect((await restored).single.status, TaskStatus.pending);
    await expectLater(
        container
            .read(calendarActionsProvider.notifier)
            .setDone(task, vietnamToday().add(const Duration(days: 1))),
        throwsException);
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });
  testWidgets(
      'family form persists real contact and warns before discarding draft',
      (tester) async {
    final container = await pumpApp(tester, '/family');
    await tapText(tester, 'Thêm người thân');
    await tester.enterText(find.byType(TextField).at(0), 'Cô An');
    await tester.enterText(find.byType(TextField).at(1), 'Bạn');
    await tester.enterText(find.byType(TextField).at(2), '12');
    await tapText(tester, 'Lưu người thân');
    expect(find.text('Vui lòng kiểm tra lại số điện thoại.'), findsOneWidget);
    expect(find.text('Cô An'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(2), '0901234567');
    await tapText(tester, 'Lưu người thân');
    expect(
        (await container.read(familyListProvider.future))
            .where((person) => person.name == 'Cô An')
            .single
            .phone,
        '0901234567');
    await tapText(tester, 'Hoàn tác');
    expect(
        (await container.read(familyListProvider.future))
            .where((person) => person.name == 'Cô An'),
        isEmpty);
    await tapText(tester, 'Thêm người thân');
    await tester.enterText(find.byType(TextField).at(0), 'Chưa lưu');
    await tapText(tester, 'Quay lại');
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
    await tapText(tester, 'Tiếp tục chỉnh sửa');
    expect(find.text('Chưa lưu'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });

  for (final (route, role) in [
    ('/calendar', UserRole.elder),
    ('/activities', UserRole.elder),
    ('/activities?section=saved', UserRole.elder),
    ('/activities?section=habits', UserRole.elder),
    ('/family', UserRole.elder),
    ('/caregiver/schedule', UserRole.caregiver),
    ('/caregiver/suggest', UserRole.caregiver),
    ('/caregiver/family', UserRole.caregiver),
  ]) {
    for (final width in [320.0, 390.0, 800.0]) {
      testWidgets('$route $width at 200% stays readable', (tester) async {
        await pumpApp(tester, route, width: width, scale: 2, role: role);
        expect(tester.takeException(), isNull);
        expect(find.byType(FittedBox), findsNothing);
        final scrolls = find.byType(Scrollable);
        for (final element in scrolls.evaluate().toList()) {
          final state = (element as StatefulElement).state as ScrollableState;
          if (state.position.axis == Axis.vertical &&
              state.position.hasContentDimensions) {
            state.position.jumpTo(state.position.maxScrollExtent);
          }
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await closeApp(tester);
      });
    }
  }
  for (final (route, name, role) in [
    ('/intro', 'welcome', UserRole.elder),
    ('/sign-in', 'signin', UserRole.elder),
    ('/calendar?date=2026-11-05', 'calendar', UserRole.elder),
    ('/activities?section=habits', 'habits', UserRole.elder),
    ('/family', 'family', UserRole.elder),
    ('/caregiver/schedule', 'caregiver_calendar', UserRole.caregiver),
    ('/caregiver/suggest', 'suggestion', UserRole.caregiver),
    ('/settings', 'settings', UserRole.elder),
  ]) {
    testWidgets('Calm screen golden $name', (tester) async {
      await pumpApp(tester, route, role: role);
      if (!['settings', 'suggestion', 'habits'].contains(name)) {
        expect(find.byType(BotanicalScene), findsWidgets);
      }
      await expectLater(
          find.byType(AnNhienApp), matchesGoldenFile('goldens/calm_$name.png'));
      await closeApp(tester);
    });
  }
  for (final (route, name, role) in [
    ('/intro', 'welcome', UserRole.elder),
    ('/calendar?date=2026-11-05', 'home', UserRole.elder),
    ('/activities', 'activities', UserRole.elder),
    ('/activities/habits/downshift', 'detail', UserRole.elder),
    ('/calendar/task/real-task', 'task_detail', UserRole.elder),
    ('/caregiver/suggest', 'suggestion', UserRole.caregiver),
  ]) {
    for (final width in [360.0, 390.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('VELORA v2 $name ${width.toInt()} x$scale', (tester) async {
          await pumpApp(tester, route,
              role: role,
              width: width,
              height: width == 360 ? 800 : 844,
              scale: scale);
          expect(tester.takeException(), isNull);
          await expectLater(
              find.byType(AnNhienApp),
              matchesGoldenFile(
                  'goldens/velora_${name}_${width.toInt()}_${scale.toString().replaceAll('.', '_')}.png'));
          await closeApp(tester);
        });
      }
    }
  }
}
