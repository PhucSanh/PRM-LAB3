import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/demo_container.dart';

void main() {
  const task = TaskItem(
      id: 'walk',
      title: 'Đi bộ quanh công viên',
      habitKey: 'move',
      hour: 9,
      minute: 30);

  testWidgets('S03 chính hiển thị việc tiếp theo đúng bố cục mới',
      (tester) async {
    final container = demoContainer(tasks: const [task]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    // AppShell giữ animation của thanh điều hướng; chờ một frame dữ liệu của
    // FakeTaskService thay vì pumpAndSettle vô hạn trên animation đó.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Chào Bác Lan'), findsOneWidget);
    expect(find.text('Việc tiếp theo'), findsOneWidget);
    expect(find.text('Đang chờ'), findsWidgets);
    expect(find.byKey(const Key('s03-next-task')), findsOneWidget);

    await tester.tap(find.byKey(const Key('s03-next-task')));
    await tester.pump();
    expect(find.byKey(const Key('s03-flashcard')), findsOneWidget);
    expect(find.text('Việc 1/1'), findsOneWidget);
    expect(find.text('Bấm nút để xem việc khác'), findsOneWidget);
    await tester.tap(find.byKey(const Key('s03-flash-back')));
    await tester.pump();
    expect(find.byKey(const Key('s03-main')), findsOneWidget);
  });

  testWidgets('S03 flashcard chuyển sang việc kế tiếp và cập nhật chỉ số',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(412, 900));
    const secondTask = TaskItem(
        id: 'tea',
        title: 'Uống trà với cô Tám',
        habitKey: 'tea',
        hour: 15,
        minute: 0);
    final container = demoContainer(tasks: const [task, secondTask]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('s03-next-task')));
    await tester.pump();
    expect(find.text('Việc 1/2'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -360));
    await tester.pump();
    await tester.ensureVisible(find.text('Việc sau'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Việc sau'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Việc 2/2'), findsOneWidget);
    expect(find.text('Uống trà với cô Tám'), findsOneWidget);

    // Flashcard có thể vuốt phải để quay về việc trước, ngoài hai nút điều
    // hướng dành cho người không muốn dùng thao tác vuốt.
    await tester.fling(
        find.byKey(const Key('s03-flashcard')), const Offset(320, 0), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Việc 1/2'), findsOneWidget);
    expect(find.text('Đi bộ quanh công viên'), findsOneWidget);
  });

  testWidgets('S03 flashcard wraps progress dots on a narrow screen',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 800));
    final tasks = List.generate(
      20,
      (index) => TaskItem(
        id: 'task-$index',
        title: 'Việc số ${index + 1}',
        habitKey: task.habitKey,
        hour: 9,
        minute: index,
      ),
    );
    final container = demoContainer(tasks: tasks);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final nextTask = find.byKey(const Key('s03-next-task'));
    await tester.ensureVisible(nextTask);
    await tester.tap(nextTask);
    await tester.pumpAndSettle();

    final firstDot = find.byKey(const Key('s03-flash-dot-0'));
    final lastDot = find.byKey(const Key('s03-flash-dot-19'));
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(lastDot).dy,
        greaterThan(tester.getTopLeft(firstDot).dy));
  });

  testWidgets('S04 hoàn thành việc xong quay về S03', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(412, 900));
    final container = demoContainer(tasks: const [task]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('s03-next-task')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('s03-flashcard')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final completeButton = find.bySemanticsLabel('Đã xong');
    await tester.scrollUntilVisible(completeButton, 300,
        scrollable: find.byType(Scrollable).first);
    // scrollUntilVisible dừng khi nút vừa ló ở đáy; cuộn thêm để xác nhận
    // vùng chạm không bị thanh điều hướng của AppShell che.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pump();
    await tester.tap(completeButton);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Đúng, đã xong'));
    await tester.pump();
    // Hoàn thành gọi lại nguồn task một lần để đồng bộ S04 trước khi điều
    // hướng; FakeTaskRepository có độ trễ 300ms cho mỗi lần đọc.
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('s03-main')), findsOneWidget);
    expect(find.text('Bác đã xong tất cả việc hôm nay!'), findsOneWidget);
  });

  testWidgets('S03 rỗng hiện lời dẫn thêm việc đầu tiên', (tester) async {
    final container = demoContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pumpAndSettle();

    expect(find.text('Hôm nay chưa có việc'), findsOneWidget);
    expect(find.text('Thêm việc đầu tiên'), findsOneWidget);
  });

  testWidgets('S03 không tràn ở 360dp và 412dp', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [360.0, 412.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      final container = demoContainer(tasks: const [task]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container, child: const AnNhienApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull,
          reason: 'màn S03 ở ${width.toInt()}dp không được overflow');
      expect(find.text('Đi bộ quanh công viên'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
