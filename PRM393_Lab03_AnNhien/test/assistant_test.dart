import 'dart:async';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/services/assistant_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/viewmodels/assistant_view_model.dart';
import 'package:an_nhien/viewmodels/session_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'device_access_flow_test.dart' show TestDevice;
import 'support/demo_container.dart';

class TestAssistant implements AssistantService {
  AssistantReply result =
      const AssistantReply('Cháu đang ở đây.', AssistantAction.chat);
  Completer<AssistantReply>? pending;
  List<Map<String, String>> history = [];
  @override
  Future<AssistantReply> reply(List<Map<String, String>> messages) async {
    history = messages;
    return pending == null ? result : await pending!.future;
  }
}

void main() {
  test(
      'local commands work without a backend and reject ambiguous calendar dates',
      () async {
    final local = LocalAssistantService();
    Future<AssistantReply> ask(String text) => local.reply([
          {'role': 'user', 'content': text}
        ]);
    expect((await ask('Gọi người thân')).action, AssistantAction.callFamily);
    expect((await ask('Thêm người thân')).action, AssistantAction.createFamily);
    expect((await ask('Xoá lịch ngày 10 tháng 11')).action,
        AssistantAction.deleteTask);
    expect((await ask('Sửa lịch ngày 10 tháng 11')).day?.month, 11);
    expect((await ask('Đọc nội dung màn hình')).action,
        AssistantAction.readScreen);
    expect((await ask('Nhắc bác tưới cây mai lúc 8 giờ sáng')).action,
        AssistantAction.createTask);
    expect((await ask('Xem lịch tuần sau')).action, AssistantAction.chat);
    expect(
        (await ask('Xoá lịch ngày 31 tháng 2')).action, AssistantAction.chat);
    expect((await ask('Xin chào')).onDevice, true);
  });

  test('schedule reply uses repository data; actions never mutate tasks',
      () async {
    final assistant = TestAssistant()
      ..result = const AssistantReply('Lịch của Bác', AssistantAction.schedule);
    final device = TestDevice();
    final c = demoContainer(assistant: assistant, device: device, tasks: [
      const TaskItem(
          id: '1', title: 'Tưới cây', habitKey: 'plant', hour: 8, minute: 15),
    ]);
    addTearDown(c.dispose);
    final subscription = c.listen(sessionProvider, (_, __) {});
    addTearDown(subscription.close);
    await c.read(sessionProvider.future);
    await c.read(assistantViewModelProvider.notifier).send('Hôm nay làm gì?');
    expect(c.read(assistantViewModelProvider).messages.last.text,
        contains('8 giờ 15 phút, Tưới cây'));
    expect(device.spoken, contains('Tưới cây'));
    assistant.result =
        const AssistantReply('Bác chọn việc nhé', AssistantAction.deleteTask);
    await c.read(assistantViewModelProvider.notifier).send('Xoá tưới cây');
    expect(c.read(assistantViewModelProvider).tasks.single.id, '1');
    expect(await c.read(taskRepositoryProvider).tasksForDay(DateTime.now()),
        hasLength(1));
  });

  test(
      'cancel prevents a late model result from speaking or proposing an action',
      () async {
    final assistant = TestAssistant()..pending = Completer<AssistantReply>();
    final device = TestDevice();
    final c = demoContainer(assistant: assistant, device: device);
    addTearDown(c.dispose);
    final subscription = c.listen(sessionProvider, (_, __) {});
    addTearDown(subscription.close);
    await c.read(sessionProvider.future);
    final vm = c.read(assistantViewModelProvider.notifier);
    final future = vm.send('Gọi con');
    await Future<void>.delayed(Duration.zero);
    vm.cancel();
    assistant.pending!.complete(
        const AssistantReply('Chọn người', AssistantAction.callFamily));
    await future;
    expect(c.read(assistantViewModelProvider).action, isNull);
    expect(device.spoken, isNull);
  });

  test('voice recognition sends the transcript into conversation history',
      () async {
    final assistant = TestAssistant();
    final device = TestDevice()..recognized = 'Chào cháu';
    final c = demoContainer(assistant: assistant, device: device);
    addTearDown(c.dispose);
    final subscription = c.listen(sessionProvider, (_, __) {});
    addTearDown(subscription.close);
    await c.read(sessionProvider.future);
    await c.read(assistantViewModelProvider.notifier).listen();
    expect(assistant.history.last, {'role': 'user', 'content': 'Chào cháu'});
    expect(device.spoken, 'Cháu đang ở đây.');
  });

  for (final width in [360.0, 412.0]) {
    testWidgets(
        'support stays available across routes at $width with large text and keyboard',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final device = TestDevice();
      final c = demoContainer(
          device: device, assistant: TestAssistant(), initialRoute: '/intro');
      await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const AnNhienApp()));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Đọc nội dung màn hình'), findsNothing);
      final pet = find.byTooltip('Nói chuyện với trợ lý An Nhiên');
      final before = tester.getTopLeft(pet);
      await tester.drag(pet, const Offset(-100, -100));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(pet).dx, lessThan(before.dx));
      c.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      expect(pet, findsOneWidget);
      await tester.tap(find.byTooltip('Nói chuyện với trợ lý An Nhiên'));
      await tester.pumpAndSettle();
      expect(find.text('Trợ lý An Nhiên'), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Đóng trợ lý An Nhiên'));
      await tester.pumpAndSettle();
      expect(find.text('Trợ lý An Nhiên'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
    });
  }
}
