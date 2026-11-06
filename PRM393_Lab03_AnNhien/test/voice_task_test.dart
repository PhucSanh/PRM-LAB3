import 'dart:async';
import 'package:an_nhien/models/voice_task_draft.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/voice_task_service.dart';
import 'package:an_nhien/services/firebase_voice_task_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/device_access_view_model.dart';
import 'package:an_nhien/viewmodels/session_view_model.dart';
import 'package:an_nhien/viewmodels/task_form_view_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/demo_container.dart';
import 'device_access_flow_test.dart' show TestDevice;

final future = DateTime(2030, 2, 3);
VoiceTaskInterpretation ready() => VoiceTaskInterpretation(
    draft: VoiceTaskDraft(
        title: 'Tưới cây',
        date: future,
        hour: 8,
        minute: 30,
        repeat: RepeatRule.someDays,
        weekdays: const [1, 3, 5],
        habitKey: 'move'),
    question: null);
VoiceTaskInterpretation ambiguous() => VoiceTaskInterpretation(
    draft: VoiceTaskDraft(
        title: 'Tưới cây',
        date: future,
        hour: null,
        minute: 0,
        repeat: RepeatRule.once,
        weekdays: const [],
        habitKey: 'move'),
    question: 'Bác muốn làm lúc mấy giờ, buổi sáng hay buổi chiều?');

class ScriptedVoiceService implements VoiceTaskService {
  ScriptedVoiceService(this.next);
  Future<VoiceTaskInterpretation> Function() next;
  final requests = <List<String>>[];
  final contexts = <VoiceUserContext?>[];
  @override
  Future<VoiceTaskInterpretation> interpret(List<String> utterances,
      {DateTime? contextDate, VoiceUserContext? userContext}) {
    requests.add(List.of(utterances));
    contexts.add(userContext);
    return next();
  }
}

Future<ProviderContainer> setup(VoiceTaskService service,
    {TestDevice? device}) async {
  final c = demoContainer(voiceTasks: service, device: device ?? TestDevice());
  addTearDown(c.dispose);
  final session = c.listen(sessionProvider, (_, __) {});
  addTearDown(session.close);
  await c.read(sessionProvider.future);
  final voice = c.listen(voiceInputViewModelProvider, (_, __) {});
  addTearDown(voice.close);
  return c;
}

void main() {
  test(
      'clarification preserves transcript; confirmation fills all form fields without writing',
      () async {
    final service = ScriptedVoiceService(() async => ambiguous()),
        device = TestDevice();
    final c = await setup(service, device: device);
    final vm = c.read(voiceInputViewModelProvider.notifier);
    vm.edit('Ngày 3 tháng 2 năm 2030 lúc 8 giờ tưới cây');
    await vm.analyze();
    expect(c.read(voiceInputViewModelProvider).interpretation!.ready, false);
    expect(vm.confirmInterpretation(), false);
    expect(device.spoken, contains('buổi sáng'));
    vm.editFollowUp('8 giờ rưỡi sáng, thứ hai tư sáu');
    service.next = () async => ready();
    await vm.analyze();
    expect(service.requests.last, hasLength(2));
    expect(service.requests.last.last, '8 giờ rưỡi sáng, thứ hai tư sáu');
    expect(device.spoken, contains('08:30'));
    expect(c.read(taskFormViewModelProvider).title, isEmpty);
    expect(vm.confirmInterpretation(), true);
    final form = c.read(taskFormViewModelProvider);
    expect(form.title, 'Tưới cây');
    expect(dateKey(form.date!), '2030-02-03');
    expect(form.hour, 8);
    expect(form.minute, 30);
    expect(form.repeat, RepeatRule.someDays);
    expect(form.weekdays, {1, 3, 5});
    expect(await c.read(taskRepositoryProvider).tasksForDay(future), isEmpty);
  });
  test('editing original sentence invalidates previous AI result', () async {
    final c = await setup(FakeVoiceTaskService(result: ready()));
    final vm = c.read(voiceInputViewModelProvider.notifier)
      ..edit('Tưới cây ngày mai');
    await vm.analyze();
    vm.edit('Gọi con');
    expect(c.read(voiceInputViewModelProvider).interpretation, isNull);
    expect(vm.confirmInterpretation(), false);
  });
  test('service failure retains transcript and permits honest manual fallback',
      () async {
    final c = await setup(ScriptedVoiceService(
        () async => throw const AppException('Chưa bật Groq')));
    final vm = c.read(voiceInputViewModelProvider.notifier)..edit('Gọi con');
    await vm.analyze();
    expect(c.read(voiceInputViewModelProvider).error, 'Chưa bật Groq');
    expect(c.read(voiceInputViewModelProvider).text, 'Gọi con');
    expect(vm.confirm(), true);
    expect(c.read(taskFormViewModelProvider).title, 'Gọi con');
    expect(await c.read(taskRepositoryProvider).tasksForDay(DateTime.now()),
        isEmpty);
  });
  test('busy prevents duplicate calls; logout discards pending result',
      () async {
    final pending = Completer<VoiceTaskInterpretation>();
    final service = ScriptedVoiceService(() => pending.future),
        c = await setup(service);
    final vm = c.read(voiceInputViewModelProvider.notifier)
      ..edit('Mai tưới cây');
    final request = vm.analyze();
    // Chờ ViewModel đọc xong ngữ cảnh (hồ sơ + lịch) và gửi request đầu.
    while (service.requests.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await vm.analyze();
    expect(service.requests, hasLength(1));
    await c.read(authServiceProvider).signOut();
    await Future<void>.delayed(Duration.zero);
    pending.complete(ready());
    await request;
    expect(c.read(voiceInputViewModelProvider).interpretation, isNull);
    expect(c.read(taskFormViewModelProvider).title, isEmpty);
  });
  test('confirmation refuses a proposal whose time has already passed',
      () async {
    final c = await setup(FakeVoiceTaskService(
        result: VoiceTaskInterpretation(
            draft: VoiceTaskDraft(
                title: 'Tưới cây',
                date: DateTime(2020),
                hour: 8,
                minute: 0,
                repeat: RepeatRule.once,
                weekdays: const [],
                habitKey: 'move'),
            question: null)));
    final vm = c.read(voiceInputViewModelProvider.notifier)..edit('Tưới cây');
    await vm.analyze();
    expect(vm.confirmInterpretation(), false);
    expect(c.read(voiceInputViewModelProvider).error, contains('đã qua'));
  });
  test(
      'callable sends text/context only, validates malformed responses and translates errors',
      () async {
    final response = {
      'ready': true,
      'question': null,
      'draft': {
        'title': 'Tưới cây',
        'date': '2030-02-03',
        'hour': 8,
        'minute': 30,
        'repeat': 'once',
        'weekdays': <int>[],
        'habitKey': 'move'
      }
    };
    final service = FirebaseVoiceTaskService.withCaller((data) async {
      expect(data, {
        'utterances': ['Mai tưới cây'],
        'contextDate': '2030-02-03'
      });
      return response;
    });
    expect(
        (await service.interpret(['Mai tưới cây'], contextDate: future)).ready,
        true);
    for (final code in [
      'failed-precondition',
      'not-found',
      'unavailable',
      'resource-exhausted',
      'unauthenticated'
    ]) {
      final broken = FirebaseVoiceTaskService.withCaller((_) async =>
          throw FirebaseFunctionsException(
              code: code, message: 'private provider body', details: null));
      await expectLater(
          broken.interpret(['secret transcript']),
          throwsA(isA<AppException>().having((e) => e.toString(), 'redacted',
              isNot(contains('private provider body')))));
    }
    response['ready'] = false;
    await expectLater(service.interpret(['Mai tưới cây'], contextDate: future),
        throwsA(isA<AppException>()));
  });
  test('voice JSON rejects invalid calendar, times and unknown categories', () {
    final map = <String, dynamic>{
      'title': 'Tưới cây',
      'date': '2030-02-03',
      'hour': 8,
      'minute': 0,
      'repeat': 'once',
      'weekdays': <int>[],
      'habitKey': 'move'
    };
    for (final patch in [
      {'date': '2030-02-31'},
      {'hour': 24},
      {'minute': 60},
      {'habitKey': 'admin'},
      {
        'weekdays': [8]
      },
      {'repeat': 'forever'},
      {'title': 'x' * 81}
    ]) {
      expect(() => VoiceTaskDraft.fromMap({...map, ...patch}),
          throwsFormatException);
    }
  });
}
