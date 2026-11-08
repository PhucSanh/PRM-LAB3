import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/models/voice_task_draft.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/firebase_voice_task_service.dart';
import 'package:an_nhien/services/local_voice_task_service.dart';
import 'package:an_nhien/services/profile_setup_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/voice_task_service.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/caregiver_schedule_view_model.dart'
    show vietnamToday;
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
      'Mai 8 giờ sáng tưới cây nửa tiếng',
    ], now: DateTime(2026, 11, 6, 11, 30));
    expect(r.ready, isTrue);
    expect(r.draft.durationMinutes, 30);
    expect(r.draft.title!.toLowerCase(), contains('tưới cây'));
    expect(r.draft.title!.toLowerCase(), isNot(contains('đi bộ')));
    expect(r.draft.hour, 8);
  });

  group('bộ hiểu lời nói trên máy', () {
    test('đủ tên việc, ngày, giờ và lặp thì sẵn sàng', () {
      final r =
          say(['Mai lúc 8 giờ sáng nhắc bác tưới cây trong 15 phút, mỗi ngày']);
      expect(r.question, isNull);
      expect(r.ready, true);
      expect(r.onDevice, true);
      expect(r.draft.title, 'Tưới cây');
      expect(dateKey(r.draft.date!), '2026-11-07');
      expect((r.draft.hour, r.draft.minute), (8, 0));
      expect(r.draft.repeat, RepeatRule.daily);
      expect(r.draft.habitKey, 'move');
      expect(r.draft.durationMinutes, 15);
    });

    test('"8 giờ" chưa rõ sáng/tối thì hỏi lại, câu bổ sung được ghép', () {
      final first = say(['Tưới cây lúc 8 giờ ngày mai']);
      expect(first.ready, false);
      expect(first.draft.hour, isNull);
      expect(first.question, contains('buổi sáng'));
      final second =
          say(['Tưới cây lúc 8 giờ ngày mai', 'buổi tối, trong 20 phút']);
      expect(second.ready, true);
      expect(second.draft.durationMinutes, 20);
      expect((second.draft.hour, second.draft.minute), (20, 0));
      expect(second.draft.title, 'Tưới cây');
    });

    test('"nhắc tôi … tối nay" không nhầm "tôi" với buổi tối', () {
      final r = say(['Nhắc tôi 9 giờ rưỡi tối nay uống thuốc 5 phút']);
      expect(r.ready, true);
      expect(r.draft.title, 'Uống thuốc');
      expect(dateKey(r.draft.date!), '2026-11-06');
      expect((r.draft.hour, r.draft.minute), (21, 30));
    });

    test('nhiều thứ trong tuần thành lặp một số ngày', () {
      final r = say(['Uống trà với bạn 3 giờ chiều thứ hai, tư, sáu 1 tiếng']);
      expect(r.ready, true);
      expect(r.draft.repeat, RepeatRule.someDays);
      expect(r.draft.weekdays, [1, 3, 5]);
      expect(r.draft.habitKey, 'tea');
      expect(r.draft.durationMinutes, 60);
      // Hôm nay thứ Sáu, 15:00 chưa qua → bắt đầu từ hôm nay.
      expect(dateKey(r.draft.date!), '2026-11-06');
    });

    test('ngày tháng đã qua trong năm thì hiểu là năm sau', () {
      final r = say(['Ngày 3/2 lúc 20 giờ gọi cho Mai 10 phút']);
      expect(r.ready, true);
      expect(dateKey(r.draft.date!), '2027-02-03');
      expect(r.draft.title, 'Gọi cho Mai');
      expect(r.draft.habitKey, 'family');
    });

    test('dùng giờ thức dậy trong hồ sơ của Bác', () {
      final r =
          say(['Sáng mai khi thức dậy tập thể dục 30 phút'], context: wake);
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
      final r = say(['Ngày mai sau khi đi bộ uống trà mất 15 phút'],
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

    test('thiếu thời lượng thì hỏi "trong bao lâu", trả lời được ghép', () {
      final first = say(['Mai 8 giờ sáng tưới cây']);
      expect(first.ready, false);
      expect(first.question, contains('bao lâu'));
      expect(say(['Mai 8 giờ sáng tưới cây', '45']).draft.durationMinutes, 45);
      expect(
          say(['Mai 8 giờ sáng tưới cây', '1 tiếng rưỡi'])
              .draft
              .durationMinutes,
          90);
      expect(say(['Mai 8 giờ 30 phút sáng tưới cây']).question,
          contains('bao lâu'),
          reason: '"30 phút" sau "8 giờ" là giờ, không phải thời lượng');
      expect(
          say(['Mai 8 giờ sáng đi dạo trong 2 giờ']).draft,
          isA<VoiceTaskDraft>()
              .having((d) => d.hour, 'hour', 8)
              .having((d) => d.durationMinutes, 'duration', 120));
      expect(say(['Mai 8 giờ sáng đi dạo 5 tiếng']).question,
          contains('tối đa 4 tiếng'));
    });

    test('"9 giờ kém 15 sáng" là 8:45', () {
      final r = say(['Ngày mai 9 giờ kém 15 sáng đi chợ']);
      expect((r.draft.hour, r.draft.minute), (8, 45));
    });
  });

  group('AI hiểu ý định câu nói', () {
    const empty = {
      'title': null,
      'date': null,
      'hour': null,
      'minute': null,
      'durationMinutes': null,
      'repeat': 'once',
      'weekdays': <int>[],
      'habitKey': 'purpose',
    };
    VoiceTaskInterpretation query(VoiceIntent intent,
            {DateTime? date, int days = 1, String? reply}) =>
        VoiceTaskInterpretation(
            draft: VoiceTaskDraft.fromMap(empty),
            question: null,
            intent: intent,
            queryDate: date,
            queryDays: days,
            reply: reply);

    test('đọc kết quả server: bản cũ là thêm việc, ý định lạ thì từ chối', () {
      Map<String, dynamic> map(Map<String, dynamic> extra) =>
          {'draft': empty, 'question': null, 'ready': false, ...extra};
      expect(VoiceTaskInterpretation.fromMap(map({})).intent, VoiceIntent.add);
      final agenda = VoiceTaskInterpretation.fromMap(
          map({'intent': 'agenda', 'queryDate': '2026-11-07', 'queryDays': 2}));
      expect(agenda.intent, VoiceIntent.agenda);
      expect(agenda.queryDate, DateTime(2026, 11, 7));
      expect(agenda.queryDays, 2);
      expect(
          VoiceTaskInterpretation.fromMap(
              map({'intent': 'answer', 'reply': ' Dạ. '})).reply,
          'Dạ.');
      for (final bad in [
        {'intent': 'delete'},
        {'intent': 'answer'},
        {'intent': 'answer', 'reply': 'x' * 301},
        {'intent': 'agenda', 'queryDays': 8},
        {'intent': 'agenda', 'queryDate': 'mai'},
      ]) {
        expect(() => VoiceTaskInterpretation.fromMap(map(bad)),
            throwsFormatException,
            reason: '$bad');
      }
    });

    test('câu hỏi tự do: hiện và đọc to câu AI trả lời, không tạo việc',
        () async {
      final service = ScriptedVoiceService(() async => query(VoiceIntent.answer,
          reply: 'Mai Bác rảnh từ 10 giờ sáng tới trưa.'));
      final c = await setup(service, tasks: [walk]);
      final vm = c.read(voiceInputViewModelProvider.notifier)
        ..edit('Mai tui rảnh lúc nào');
      expect(await vm.analyze(), isNull);
      final state = c.read(voiceInputViewModelProvider);
      expect(state.reply, 'Mai Bác rảnh từ 10 giờ sáng tới trưa.');
      expect(state.interpretation, isNull);
      expect(state.busy, isFalse);
      // Gửi khung giờ bận 7 ngày tới có ngày, không có tên việc.
      final week = service.contexts.single!.toMap()['week'] as List;
      expect(week, isNotEmpty);
      expect((week.first as Map).keys,
          containsAll(['date', 'time', 'durationMinutes', 'habitKey']));
      expect(week.toString(), isNot(contains('công viên')));
    });

    test('AI hiểu là hỏi lịch: app tự đọc lịch các ngày đó trên máy', () async {
      final today = vietnamToday();
      final service = ScriptedVoiceService(() async => query(VoiceIntent.agenda,
          date: DateTime(today.year, today.month, today.day + 1), days: 2));
      final c = await setup(service, tasks: [walk]);
      final vm = c.read(voiceInputViewModelProvider.notifier)
        ..edit('mấy bữa tới tui bận gì');
      await vm.analyze();
      final state = c.read(voiceInputViewModelProvider);
      expect(state.reply, startsWith('Ngày mai,'));
      expect(state.reply, contains('Ngày kia,'));
      expect(state.addedDay, DateTime(today.year, today.month, today.day + 1));
      expect(state.busy, isFalse);
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

    test('trùng giờ với việc đã có thì không cho thêm', () async {
      final c = await setup(
          FakeVoiceTaskService(
              result: VoiceTaskInterpretation(
                  draft: VoiceTaskDraft(
                      title: 'Uống trà',
                      date: DateTime(2030, 2, 4),
                      hour: 9,
                      minute: 45,
                      durationMinutes: 15,
                      repeat: RepeatRule.once,
                      weekdays: const [],
                      habitKey: 'tea'),
                  question: null)),
          tasks: [walk]);
      final vm = c.read(voiceInputViewModelProvider.notifier)..edit('Uống trà');
      await vm.analyze();
      expect(c.read(voiceInputViewModelProvider).conflict,
          contains('Đi bộ quanh công viên'));
      expect(await vm.addToSchedule(), isNull);
      expect(
          (await c
                  .read(taskRepositoryProvider)
                  .tasksForDay(DateTime(2030, 2, 4)))
              .map((t) => t.title),
          isNot(contains('Uống trà')));
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
                  durationMinutes: 15,
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
      final r = await off.interpret(['Mai 8 giờ sáng tưới cây 15 phút']);
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
