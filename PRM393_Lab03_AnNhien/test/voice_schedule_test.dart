import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/voice_task_draft.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/firebase_voice_task_service.dart';
import 'package:an_nhien/services/local_voice_task_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/voice_task_service.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/device_access_view_model.dart';
import 'package:an_nhien/viewmodels/session_view_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'device_access_flow_test.dart' show TestDevice;
import 'support/demo_container.dart';
import 'voice_task_test.dart' show ScriptedVoiceService, ready;

/// Thứ Sáu 06/11/2026, 10:00 giờ Việt Nam.
// Ghi rõ UTC+7 để mốc thời gian không phụ thuộc múi giờ của máy chạy test.
final now = DateTime.parse('2026-11-06T10:00:00+07:00');
const wake = VoiceUserContext(honorific: 'ba', wakeHour: 5, wakeMinute: 30);

VoiceTaskInterpretation say(List<String> turns,
        {VoiceUserContext context = const VoiceUserContext()}) =>
    interpretVietnamese(turns, now: now, context: context);

const walk = TaskItem(
    id: 'walk',
    title: 'Đi bộ quanh công viên',
    habitKey: 'move',
    hour: 9,
    minute: 30,
    durationMinutes: 30);

Future<ProviderContainer> setup(VoiceTaskService service,
    {List<TaskItem> tasks = const []}) async {
  final c = demoContainer(
      voiceTasks: service, device: TestDevice(), tasks: [...tasks]);
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
      'local voice asks for one task when separate clauses have separate times',
      () {
    for (final text in [
      'Mai 8 giờ sáng tưới cây, 9 giờ sáng đi bộ.',
      'Mai 8:00 tưới cây và 9:00 đi bộ',
      '8 giờ sáng uống trà; 10 giờ sáng gọi con',
    ]) {
      final r = interpretVietnamese([text], now: DateTime(2026, 11, 6, 11, 30));
      expect(r.ready, isFalse);
      expect(r.question, contains('từng việc một'));
      expect(r.draft.title, isNull);
    }
  });
  test('choosing one task discards the previous multi-task draft', () {
    final r = interpretVietnamese([
      'Mai 8 giờ sáng tưới cây, 9 giờ sáng đi bộ.',
      'Mai 8 giờ sáng tưới cây',
    ], now: DateTime(2026, 11, 6, 11, 30));
    expect(r.ready, isTrue);
    expect(r.draft.title!.toLowerCase(), contains('tưới cây'));
    expect(r.draft.title!.toLowerCase(), isNot(contains('đi bộ')));
    expect(r.draft.hour, 8);
  });

  group('bộ hiểu lời nói trên máy', () {
    test('đủ tên việc, ngày, giờ và lặp thì sẵn sàng', () {
      final r = say(['Mai lúc 8 giờ sáng nhắc bác tưới cây, mỗi ngày']);
      expect(r.question, isNull);
      expect(r.ready, true);
      expect(r.onDevice, true);
      expect(r.draft.title, 'Tưới cây');
      expect(dateKey(r.draft.date!), '2026-11-07');
      expect((r.draft.hour, r.draft.minute), (8, 0));
      expect(r.draft.repeat, RepeatRule.daily);
      expect(r.draft.habitKey, 'move');
    });

    test('"8 giờ" chưa rõ sáng/tối thì hỏi lại, câu bổ sung được ghép', () {
      final first = say(['Tưới cây lúc 8 giờ ngày mai']);
      expect(first.ready, false);
      expect(first.draft.hour, isNull);
      expect(first.question, contains('buổi sáng'));
      final second = say(['Tưới cây lúc 8 giờ ngày mai', 'buổi tối']);
      expect(second.ready, true);
      expect((second.draft.hour, second.draft.minute), (20, 0));
      expect(second.draft.title, 'Tưới cây');
    });

    test('"nhắc tôi … tối nay" không nhầm "tôi" với buổi tối', () {
      final r = say(['Nhắc tôi 9 giờ rưỡi tối nay uống thuốc']);
      expect(r.ready, true);
      expect(r.draft.title, 'Uống thuốc');
      expect(dateKey(r.draft.date!), '2026-11-06');
      expect((r.draft.hour, r.draft.minute), (21, 30));
    });

    test('nhiều thứ trong tuần thành lặp một số ngày', () {
      final r = say(['Uống trà với bạn 3 giờ chiều thứ hai, tư, sáu']);
      expect(r.ready, true);
      expect(r.draft.repeat, RepeatRule.someDays);
      expect(r.draft.weekdays, [1, 3, 5]);
      expect(r.draft.habitKey, 'tea');
      // Hôm nay thứ Sáu, 15:00 chưa qua → bắt đầu từ hôm nay.
      expect(dateKey(r.draft.date!), '2026-11-06');
    });

    test('ngày tháng đã qua trong năm thì hiểu là năm sau', () {
      final r = say(['Ngày 3/2 lúc 20 giờ gọi cho Mai']);
      expect(r.ready, true);
      expect(dateKey(r.draft.date!), '2027-02-03');
      expect(r.draft.title, 'Gọi cho Mai');
      expect(r.draft.habitKey, 'family');
    });

    test('dùng giờ thức dậy trong hồ sơ của Bác', () {
      final r = say(['Sáng mai khi thức dậy tập thể dục'], context: wake);
      expect(r.ready, true);
      expect((r.draft.hour, r.draft.minute), (5, 30));
      expect(r.draft.title, 'Tập thể dục');
      final meal = say(['Ngày mai sau bữa sáng uống thuốc'], context: wake);
      expect((meal.draft.hour, meal.draft.minute), (6, 30));
    });

    test('chưa biết giờ thức dậy thì hỏi giờ cụ thể, không tự bịa', () {
      final r = say(['Sáng mai khi thức dậy tập thể dục']);
      expect(r.ready, false);
      expect(r.draft.hour, isNull);
      expect(r.question, contains('thức dậy'));
    });

    test('"sau khi đi bộ" dùng khung giờ đã có trong ngày', () {
      final r = say(['Ngày mai sau khi đi bộ uống trà'],
          context: const VoiceUserContext(busy: [
            VoiceBusySlot(
                hour: 9, minute: 30, durationMinutes: 30, habitKey: 'move')
          ]));
      expect(r.ready, true);
      expect((r.draft.hour, r.draft.minute), (10, 0));
    });

    test('thời điểm đã qua, thiếu ngày, yêu cầu xoá đều phải hỏi lại', () {
      expect(say(['Hôm nay 7 giờ sáng đi bộ']).question, contains('đã qua'));
      expect(say(['8 giờ tối uống thuốc']).question, contains('ngày nào'));
      expect(say(['Xoá việc đi bộ ngày mai']).question, contains('chưa sửa'));
      expect(say(['ngày mai 8 giờ sáng']).question, contains('việc gì'));
    });

    test('"9 giờ kém 15 sáng" là 8:45', () {
      final r = say(['Ngày mai 9 giờ kém 15 sáng đi chợ']);
      expect((r.draft.hour, r.draft.minute), (8, 45));
    });
  });

  group('thêm vào lịch bằng giọng nói', () {
    test('gửi giờ thức dậy và khung giờ bận, không gửi tên việc', () async {
      final service = ScriptedVoiceService(() async => ready());
      final c = await setup(service, tasks: [walk]);
      await c.read(profileSetupServiceProvider).saveSetup(
          'demo-user',
          const ProfileSetup(
              displayName: 'Lan',
              honorific: Honorific.ba,
              wakeHour: 5,
              wakeMinute: 30));
      final vm = c.read(voiceInputViewModelProvider.notifier)
        ..edit('Mai tưới cây 8 giờ sáng');
      await vm.analyze();
      final sent = service.contexts.single!;
      expect(sent.toMap()['wakeTime'], '05:30');
      expect(sent.honorific, 'ba');
      expect(sent.busy.single.toMap(),
          {'time': '09:30', 'durationMinutes': 30, 'habitKey': 'move'});
      expect(sent.toMap().toString(), isNot(contains('công viên')));
    });

    test('báo trùng giờ với việc đã có nhưng vẫn cho thêm', () async {
      final c = await setup(
          FakeVoiceTaskService(
              result: VoiceTaskInterpretation(
                  draft: VoiceTaskDraft(
                      title: 'Uống trà',
                      date: DateTime(2030, 2, 4),
                      hour: 9,
                      minute: 45,
                      repeat: RepeatRule.once,
                      weekdays: const [],
                      habitKey: 'tea'),
                  question: null)),
          tasks: [walk]);
      final vm = c.read(voiceInputViewModelProvider.notifier)..edit('Uống trà');
      await vm.analyze();
      expect(c.read(voiceInputViewModelProvider).conflict,
          contains('Đi bộ quanh công viên'));
      expect(await vm.addToSchedule(), isNotNull);
    });

    test('Thêm vào lịch lưu đúng việc, ghi analytics; Hoàn tác xoá lại',
        () async {
      final c = await setup(FakeVoiceTaskService(result: ready()));
      final vm = c.read(voiceInputViewModelProvider.notifier)..edit('Tưới cây');
      await vm.analyze();
      final task = await vm.addToSchedule();
      expect(task, isNotNull);
      expect(task!.title, 'Tưới cây');
      expect(task.repeat, RepeatRule.someDays);
      expect(task.weekdays, [1, 3, 5]);
      expect(task.startDate, '2030-02-03');
      expect((task.hour, task.minute), (8, 30));
      // Lượt mới để Bác nói tiếp.
      expect(c.read(voiceInputViewModelProvider).interpretation, isNull);
      final monday = DateTime(2030, 2, 4);
      final repo = c.read(taskRepositoryProvider);
      expect(
          (await repo.tasksForDay(monday)).map((t) => t.id), contains(task.id));
      final analytics =
          c.read(analyticsServiceProvider) as FakeAnalyticsService;
      expect(analytics.logged, containsAll(['voice_add_task', 'add_task']));
      await c.read(voiceTaskWriterProvider).undo(task);
      expect((await repo.tasksForDay(monday)).map((t) => t.id),
          isNot(contains(task.id)));
      expect(analytics.logged, contains('undo_action'));
    });

    test('chưa đủ thông tin hoặc đã qua thì không lưu', () async {
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
      expect(await vm.addToSchedule(), isNull);
      await vm.analyze();
      expect(await vm.addToSchedule(), isNull);
      expect(c.read(voiceInputViewModelProvider).error, contains('đã qua'));
      expect(await c.read(taskRepositoryProvider).tasksForDay(DateTime(2020)),
          isEmpty);
    });
  });

  group('chọn nguồn hiểu lời nói', () {
    test('server chưa bật thì dùng bộ trên máy; lỗi khác vẫn báo', () async {
      final local = LocalVoiceTaskService(now: () => now);
      final off = FallbackVoiceTaskService(
          ScriptedVoiceService(
              () async => throw const VoiceUnavailableException()),
          local);
      final r = await off.interpret(['Mai 8 giờ sáng tưới cây']);
      expect(r.onDevice, true);
      expect(r.ready, true);
      final quota = FallbackVoiceTaskService(
          ScriptedVoiceService(
              () async => throw const AppException('Đã thử nhiều lần')),
          local);
      await expectLater(quota.interpret(['Mai tưới cây']),
          throwsA(isNot(isA<VoiceUnavailableException>())));
    });

    test('callable nhận userContext; chưa deploy báo VoiceUnavailable',
        () async {
      Map<String, dynamic>? sent;
      final service = FirebaseVoiceTaskService.withCaller((data) async {
        sent = data;
        return {
          'ready': false,
          'question': 'Bác muốn làm việc gì?',
          'draft': {
            'title': null,
            'date': null,
            'hour': null,
            'minute': null,
            'repeat': 'once',
            'weekdays': <int>[],
            'habitKey': 'purpose'
          }
        };
      });
      await service.interpret(['mai'], userContext: wake);
      expect(sent!['userContext'],
          {'honorific': 'ba', 'wakeTime': '05:30', 'busy': <Object>[]});
      await service.interpret(['mai'], userContext: const VoiceUserContext());
      expect(sent!.containsKey('userContext'), false);
      for (final code in ['failed-precondition', 'not-found']) {
        final broken = FirebaseVoiceTaskService.withCaller((_) async =>
            throw FirebaseFunctionsException(code: code, message: 'x'));
        await expectLater(broken.interpret(['mai']),
            throwsA(isA<VoiceUnavailableException>()));
      }
    });
  });
}
