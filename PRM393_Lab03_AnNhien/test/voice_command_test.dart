import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/analytics_service.dart';
import 'package:an_nhien/services/providers.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:an_nhien/viewmodels/daily_actions_view_model.dart';
import 'package:an_nhien/viewmodels/device_access_view_model.dart';
import 'package:an_nhien/viewmodels/schedule_conflict.dart';
import 'package:an_nhien/viewmodels/session_view_model.dart';
import 'package:an_nhien/viewmodels/task_form_view_model.dart';
import 'package:an_nhien/viewmodels/voice_command.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'device_access_flow_test.dart' show TestDevice;
import 'support/demo_container.dart';

/// 10:00 sáng giờ Việt Nam, 05/02/2030.
final _clock = Clock.fixed(DateTime.utc(2030, 2, 5, 3));

const walk = TaskItem(
    id: 'walk',
    title: 'Đi bộ quanh công viên',
    habitKey: 'move',
    hour: 9,
    minute: 30,
    durationMinutes: 30);
const tea = TaskItem(
    id: 'tea',
    title: 'Uống trà với bạn',
    habitKey: 'tea',
    hour: 15,
    minute: 0,
    durationMinutes: 45);
const call = TaskItem(
    id: 'call',
    title: 'Gọi điện cho Mai',
    habitKey: 'family',
    hour: 18,
    minute: 0,
    durationMinutes: 15);

const userSentence =
    'nay tui đã làm xong việc này rùi giờ bạn đánh hoàn thành rùi nói tui việc tiếp theo';

Future<(ProviderContainer, TestDevice)> _setup(List<TaskItem> tasks) async {
  final device = TestDevice();
  final c = demoContainer(device: device, tasks: tasks);
  addTearDown(c.dispose);
  final session = c.listen(sessionProvider, (_, __) {});
  addTearDown(session.close);
  await c.read(sessionProvider.future);
  final voice = c.listen(voiceInputViewModelProvider, (_, __) {});
  addTearDown(voice.close);
  return (c, device);
}

void main() {
  group('nhận lệnh nói', () {
    test('câu của Bác "làm xong rồi … nói việc tiếp theo" là lệnh hoàn thành',
        () {
      expect(parseVoiceCommand(userSentence), VoiceCommandKind.complete);
      expect(
          parseVoiceCommand('Tôi đi bộ xong rồi'), VoiceCommandKind.complete);
      expect(parseVoiceCommand('Đánh dấu xong việc uống trà'),
          VoiceCommandKind.complete);
      expect(parseVoiceCommand('Việc tiếp theo là gì?'), VoiceCommandKind.next);
      expect(parseVoiceCommand('Còn việc gì nữa không cháu'),
          VoiceCommandKind.next);
    });

    test('hỏi lịch một ngày là lệnh đọc lịch, không phải thêm việc', () {
      for (final s in [
        'công việc ngày mai',
        'Ngày mai tui phải làm gì?',
        'việc sắp tới phải làm trong hôm nay',
        'Xem lịch thứ 5',
        'Ngày mai còn việc gì không cháu',
        'Chủ nhật có việc gì không',
      ]) {
        expect(parseVoiceCommand(s), VoiceCommandKind.agenda, reason: s);
      }
      // 05/02/2030 là thứ Ba.
      final tue = DateTime(2030, 2, 5);
      expect(agendaDayOffset('công việc ngày mai', tue), 1);
      expect(agendaDayOffset('việc sắp tới hôm nay', tue), 0);
      expect(agendaDayOffset('lịch ngày kia', tue), 2);
      expect(agendaDayOffset('lịch thứ năm', tue), 2);
      expect(agendaDayOffset('lịch thứ 2', tue), 6);
      expect(agendaDayOffset('có một việc gì không', tue), 0);
    });

    test('câu thêm việc mới không bị hiểu nhầm là lệnh', () {
      expect(parseVoiceCommand('Tưới cây ngày mai'), isNull);
      expect(parseVoiceCommand('Lên lịch đi bộ ngày mai'), isNull);
      expect(parseVoiceCommand('Mai 8 giờ có việc đi chợ'), isNull);
      expect(parseVoiceCommand('Mai 8 giờ sáng tưới cây 15 phút'), isNull);
      expect(
          parseVoiceCommand('Nhắc tôi hoàn thành báo cáo lúc 8 giờ'), isNull);
    });

    test('chọn việc đã tới giờ gần nhất, hoặc việc Bác nêu tên', () {
      final now = DateTime(2030, 2, 5, 10);
      expect(taskToComplete('xong rồi', [walk, tea, call], now)!.id, 'walk');
      expect(
          taskToComplete('uống trà với bạn xong rồi', [walk, tea, call], now)!
              .id,
          'tea');
      // Chưa tới giờ việc nào: việc sớm nhất.
      expect(
          taskToComplete('xong rồi', [tea, call], DateTime(2030, 2, 5, 7))!.id,
          'tea');
      expect(
          taskToComplete(
              'xong rồi', [walk.copyWith(status: TaskStatus.done)], now),
          isNull);
      expect(nextOpenTask([walk, tea, call], now, except: 'walk')!.id, 'tea');
    });
  });

  group('ViewModel', () {
    test('đánh dấu xong việc đang làm, đọc to việc tiếp theo, Hoàn tác được',
        () async {
      await withClock(_clock, () async {
        final (c, device) = await _setup([walk, tea, call]);
        final vm = c.read(voiceInputViewModelProvider.notifier)
          ..edit(userSentence);
        final change = await vm.analyze();
        expect(change, isNotNull);
        expect(change!.task.id, 'walk');
        final state = c.read(voiceInputViewModelProvider);
        expect(state.reply, contains('Đi bộ quanh công viên'));
        expect(state.reply, contains('Uống trà với bạn'));
        expect(state.reply, contains('15:00'));
        expect(state.reply, contains('45 phút'));
        expect(device.spoken, state.reply);
        final repo = c.read(taskRepositoryProvider);
        final today = DateTime(2030, 2, 5);
        expect(
            (await repo.tasksForDay(today))
                .firstWhere((t) => t.id == 'walk')
                .status,
            TaskStatus.done);
        final analytics =
            c.read(analyticsServiceProvider) as FakeAnalyticsService;
        expect(analytics.logged, contains('voice_command'));
        await c.read(dailyActionsProvider.notifier).undo(change);
        expect(
            (await repo.tasksForDay(today))
                .firstWhere((t) => t.id == 'walk')
                .status,
            TaskStatus.pending);
      });
    });

    test('hỏi việc tiếp theo thì chỉ trả lời, không đổi lịch', () async {
      await withClock(_clock, () async {
        final (c, _) = await _setup([walk, tea, call]);
        final vm = c.read(voiceInputViewModelProvider.notifier)
          ..edit('Việc tiếp theo là gì?');
        expect(await vm.analyze(), isNull);
        expect(c.read(voiceInputViewModelProvider).reply,
            contains('Uống trà với bạn'));
        final tasks = await c
            .read(taskRepositoryProvider)
            .tasksForDay(DateTime(2030, 2, 5));
        expect(tasks.every((t) => t.status == TaskStatus.pending), isTrue);
      });
    });

    test('hỏi công việc ngày mai thì đọc lịch ngày mai, không hỏi giờ',
        () async {
      await withClock(_clock, () async {
        final (c, device) = await _setup([walk, tea, call]);
        final vm = c.read(voiceInputViewModelProvider.notifier)
          ..edit('công việc ngày mai');
        expect(await vm.analyze(), isNull);
        final state = c.read(voiceInputViewModelProvider);
        expect(state.interpretation, isNull);
        expect(state.reply, startsWith('Ngày mai, thứ Tư, ngày 6/2,'));
        expect(state.addedDay, DateTime(2030, 2, 6));
        expect(device.spoken, state.reply);
      });
    });

    test('hỏi lịch hôm nay chỉ kể việc chưa làm', () async {
      await withClock(_clock, () async {
        final (c, _) =
            await _setup([walk.copyWith(status: TaskStatus.done), tea, call]);
        final vm = c.read(voiceInputViewModelProvider.notifier)
          ..edit('hôm nay tui phải làm gì');
        await vm.analyze();
        final reply = c.read(voiceInputViewModelProvider).reply!;
        expect(reply, contains('còn 2 việc'));
        expect(reply, contains('“Uống trà với bạn” lúc 15:00'));
        expect(reply, contains('“Gọi điện cho Mai” lúc 18:00'));
        expect(reply, isNot(contains('Đi bộ')));
      });
    });

    test('hết việc thì báo nghỉ ngơi', () async {
      await withClock(_clock, () async {
        final (c, _) = await _setup([walk.copyWith(status: TaskStatus.done)]);
        final vm = c.read(voiceInputViewModelProvider.notifier)
          ..edit('Tôi làm xong rồi');
        expect(await vm.analyze(), isNull);
        expect(
            c.read(voiceInputViewModelProvider).reply, contains('nghỉ ngơi'));
      });
    });
  });

  group('một khung giờ chỉ một việc', () {
    test('chồng giờ theo thời lượng; nối tiếp nhau thì được', () {
      expect(
          overlappingTask([walk], hour: 9, minute: 45, durationMinutes: 15)?.id,
          'walk');
      expect(
          overlappingTask([walk], hour: 9, minute: 0, durationMinutes: 45)?.id,
          'walk');
      expect(overlappingTask([walk], hour: 10, minute: 0, durationMinutes: 30),
          isNull);
      expect(overlappingTask([walk], hour: 9, minute: 0, durationMinutes: 30),
          isNull);
      expect(
          overlappingTask([walk.copyWith(status: TaskStatus.skipped)],
              hour: 9, minute: 45, durationMinutes: 15),
          isNull);
      expect(overlapMessage(walk), contains('09:30 đến 10:00'));
    });

    test('form không lưu việc trùng giờ, đổi giờ thì lưu được', () async {
      await withClock(_clock, () async {
        final (c, _) = await _setup([walk]);
        final vm = c.read(taskFormViewModelProvider.notifier)
          ..startCreate(day: DateTime(2030, 2, 6))
          ..setTitle('Tập dưỡng sinh')
          ..setRepeat(RepeatRule.once)
          ..setTime(hour: 9, minute: 45, isAm: true)
          ..setDuration(20);
        expect(await vm.save(), isFalse);
        expect(c.read(taskFormViewModelProvider).conflictMessage,
            contains('Đi bộ quanh công viên'));
        vm.setTime(hour: 10, minute: 0, isAm: true);
        expect(c.read(taskFormViewModelProvider).conflictMessage, isNull);
        expect(await vm.save(), isTrue);
      });
    });

    test('sửa chính việc đó không bị coi là trùng với nó', () async {
      await withClock(_clock, () async {
        final repo =
            FakeTaskRepository([walk.copyWith(startDate: '2030-02-05')]);
        final c = demoContainer(taskRepository: repo);
        addTearDown(c.dispose);
        final vm = c.read(taskFormViewModelProvider.notifier);
        expect(await vm.startEdit('walk', day: DateTime(2030, 2, 5)), isTrue);
        vm.setDuration(45);
        expect(await vm.save(), isTrue);
      });
    });

    test('dời giờ sang khung đã có việc thì báo lỗi', () async {
      await withClock(_clock, () async {
        final (c, _) = await _setup([walk, tea]);
        final today = DateTime(2030, 2, 5);
        await expectLater(
            c
                .read(dailyActionsProvider.notifier)
                .move(walk, today, DateTime(2030, 2, 5, 15, 15)),
            throwsA(isA<ScheduleConflictException>().having(
                (e) => (e as AppException).userMessage,
                'message',
                contains('Uống trà với bạn'))));
      });
    });
  });
}
