import 'package:an_nhien/services/remote_config_service.dart';
import 'package:an_nhien/viewmodels/session_view_model.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/services/device_access_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/reminder_service.dart';
import 'package:an_nhien/viewmodels/device_access_view_model.dart';
import 'package:an_nhien/viewmodels/task_form_view_model.dart';
import 'package:an_nhien/router/app_router.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'support/demo_container.dart';

class TestDevice implements DeviceAccessService {
  String? recognized = 'Tưới rau ngoài vườn';
  String? spoken;
  int stops = 0, settings = 0;
  Completer<void>? speech;
  @override
  Future<String?> recognize() async => recognized;
  @override
  Future<void> speak(String text) async {
    spoken = text;
    await speech?.future;
  }

  @override
  Future<void> stopSpeaking() async {
    stops++;
    if (speech?.isCompleted == false) speech!.complete();
  }

  @override
  Future<void> openNotificationSettings() async {
    settings++;
  }

  @override
  Future<String?> savePdf(String name, Uint8List bytes) async =>
      'content://documents/$name';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'voice flag follows the configured service without a Firebase dependency',
      () {
    final c = ProviderContainer(overrides: [
      remoteConfigServiceProvider.overrideWithValue(
          FakeRemoteConfigService({RemoteConfigKeys.voiceInputEnabled: false}))
    ]);
    addTearDown(c.dispose);
    expect(c.read(voiceInputEnabledProvider), false);
  });
  test('voice recognition is a draft: confirm fills form without writing tasks',
      () async {
    final device = TestDevice();
    final c = demoContainer(device: device);
    addTearDown(c.dispose);
    final session = c.listen(sessionProvider, (_, __) {});
    addTearDown(session.close);
    await c.read(sessionProvider.future);
    final keep = c.listen(voiceInputViewModelProvider, (_, __) {});
    addTearDown(keep.close);
    final vm = c.read(voiceInputViewModelProvider.notifier);
    await vm.listen();
    expect(c.read(voiceInputViewModelProvider).text, 'Tưới rau ngoài vườn');
    expect(vm.confirm(), true);
    expect(c.read(taskFormViewModelProvider).title, 'Tưới rau ngoài vườn');
    expect(await c.read(taskRepositoryProvider).tasksForDay(DateTime.now()),
        isEmpty);
    device.recognized = null;
    await vm.listen();
    expect(c.read(voiceInputViewModelProvider).text, 'Tưới rau ngoài vườn');
  });
  test('read aloud can stop while awaiting native speech completion', () async {
    final device = TestDevice()..speech = Completer<void>();
    final c = demoContainer(device: device);
    addTearDown(c.dispose);
    final session = c.listen(sessionProvider, (_, __) {});
    addTearDown(session.close);
    await c.read(sessionProvider.future);
    final keep = c.listen(speechViewModelProvider, (_, __) {});
    addTearDown(keep.close);
    final vm = c.read(speechViewModelProvider.notifier);
    final reading = vm.toggle('Đi bộ lúc 8 giờ');
    await Future<void>.delayed(Duration.zero);
    expect(c.read(speechViewModelProvider).speaking, true);
    expect(device.spoken, 'Đi bộ lúc 8 giờ');
    await vm.toggle('');
    await reading;
    expect(c.read(speechViewModelProvider).speaking, false);
    expect(device.stops, greaterThan(0));
  });
  test('reminder settings request permission then send test through service',
      () async {
    final service = FakeReminderService(delay: Duration.zero);
    final c = demoContainer(reminders: service);
    addTearDown(c.dispose);
    final session = c.listen(sessionProvider, (_, __) {});
    addTearDown(session.close);
    await c.read(sessionProvider.future);
    final keep = c.listen(reminderSettingsViewModelProvider, (_, __) {});
    addTearDown(keep.close);
    final vm = c.read(reminderSettingsViewModelProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await vm.act('request');
    await vm.act('test');
    expect(c.read(reminderSettingsViewModelProvider).allowed, true);
    expect(service.testShownCount, 1);
  });
  for (final route in [
    '/today/voice',
    '/settings/reminders',
    '/calendar/export'
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$route is usable at 360dp scale $scale', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final c = demoContainer(initialRoute: route, device: TestDevice());
        addTearDown(c.dispose);
        await tester.pumpWidget(
            UncontrolledProviderScope(container: c, child: const AnNhienApp()));
        await tester.pumpAndSettle();
        expect(c.read(routerProvider).routeInformationProvider.value.uri.path,
            route);
        expect(find.textContaining('Chủ màn'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 400));
      });
    }
  }
  testWidgets(
      'new task detail offers skip and postpone; future detail offers edit',
      (tester) async {
    final c = demoContainer(initialRoute: '/calendar/task/task', tasks: const [
      TaskItem(
          id: 'task', title: 'Đi bộ', habitKey: 'move', hour: 8, minute: 0),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const AnNhienApp()));
    await tester.pumpAndSettle();
    expect(find.text('Dời lại'), findsOneWidget);
    expect(find.text('Bỏ qua hôm nay'), findsOneWidget);
    final day = DateTime.now().add(const Duration(days: 3));
    c.read(routerProvider).go('/calendar/task/task?date=${dateKey(day)}');
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa'), findsOneWidget);
    expect(find.text('Hoàn thành'), findsNothing);
    expect(find.text('Dời lại'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
