import 'package:an_nhien/viewmodels/task_form_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'support/demo_container.dart';

class FailingLoadRepository extends FakeTaskRepository {
  FailingLoadRepository()
      : super(const [
          TaskItem(
              id: 'task', title: 'Đi bộ', habitKey: 'move', hour: 8, minute: 0)
        ]);
  bool fail = true;
  @override
  Future<List<TaskItem>> tasksForDay(DateTime day) async {
    if (fail) throw AppException.network;
    return super.tasksForDay(day);
  }
}

void main() {
  testWidgets(
      'deleted task has retry and route back, no endless spinner at 200%',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = demoContainer(initialRoute: '/today/task/missing/edit');
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Việc này không còn trong lịch'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final back = find.text('Về lịch');
    await tester.scrollUntilVisible(back, 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/calendar');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
  });
  testWidgets(
      'task load error can retry successfully with the same selected date',
      (tester) async {
    final repo = FailingLoadRepository();
    final c = demoContainer(
        initialRoute: '/today/task/task/edit?date=2099-11-07',
        taskRepository: repo);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsWidgets);
    repo.fail = false;
    await tester.tap(find.text('Thử lại').last);
    await tester.pumpAndSettle();
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    expect(c.read(taskFormViewModelProvider).date, DateTime(2099,11,7));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
  });
}
