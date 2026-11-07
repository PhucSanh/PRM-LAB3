import 'dart:convert';

import 'package:an_nhien/models/voice_task_draft.dart';
import 'package:an_nhien/services/gemini_voice_task_service.dart';
import 'package:an_nhien/services/voice_task_service.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:clock/clock.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

/// 11:30 giờ Việt Nam, thứ Sáu 06/11/2026.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 6, 4, 30));

Map<String, dynamic> _raw(Map<String, dynamic> patch) => {
      'intent': 'add',
      'queryDate': null,
      'queryDays': null,
      'reply': null,
      'title': 'Tưới cây',
      'date': '2026-11-07',
      'hour': 8,
      'minute': 0,
      'durationMinutes': 15,
      'repeat': 'daily',
      'weekdays': <int>[],
      'habitKey': 'plant',
      'issue': 'none',
      ...patch,
    };

GeminiVoiceTaskService _service(Object? Function() reply,
        {void Function(String system, String user)? onCall}) =>
    GeminiVoiceTaskService.withGenerator((system, user) async {
      onCall?.call(system, user);
      final r = reply();
      if (r is Exception) throw r;
      return r is String ? r : jsonEncode(r);
    });

void main() {
  test('thêm việc đủ thông tin thì sẵn sàng; gửi ngữ cảnh không có tên việc',
      () async {
    await withClock(_clock, () async {
      late String sentSystem, sentUser;
      final r = await _service(() => _raw({}), onCall: (s, u) {
        sentSystem = s;
        sentUser = u;
      }).interpret(['Mai 8 giờ sáng tưới cây 15 phút'],
          userContext: VoiceUserContext(week: [
            VoiceBusySlot(
                date: DateTime(2026, 11, 7),
                hour: 9,
                minute: 30,
                durationMinutes: 30,
                habitKey: 'move')
          ]));
      expect(r.intent, VoiceIntent.add);
      expect(r.ready, isTrue);
      expect(r.draft.title, 'Tưới cây');
      expect(sentSystem, contains('2026-11-06T11:30'));
      final user = jsonDecode(sentUser) as Map;
      expect(user['utterances'], ['Mai 8 giờ sáng tưới cây 15 phút']);
      expect((user['userContext'] as Map)['week'], [
        {
          'date': '2026-11-07',
          'time': '09:30',
          'durationMinutes': 30,
          'habitKey': 'move'
        }
      ]);
    });
  });

  test('thiếu giờ / giờ đã qua / thiếu thời lượng thì hỏi lại', () async {
    await withClock(_clock, () async {
      Future<String?> ask(Map<String, dynamic> p) async =>
          (await _service(() => _raw(p)).interpret(['x'])).question;
      expect(await ask({'hour': null}), contains('buổi sáng hay buổi chiều'));
      expect(await ask({'date': '2026-11-06', 'hour': 9}), contains('đã qua'));
      expect(await ask({'durationMinutes': null}), contains('bao lâu'));
      expect(await ask({'durationMinutes': 300}), contains('tối đa 4 tiếng'));
    });
  });

  test('ý định khác: hỏi lịch, trả lời ngắn, làm xong', () async {
    await withClock(_clock, () async {
      final none = {
        'title': null,
        'date': null,
        'hour': null,
        'minute': null,
        'durationMinutes': null,
        'repeat': 'once',
        'habitKey': 'purpose',
      };
      final agenda = await _service(() =>
              _raw({...none, 'intent': 'agenda', 'queryDate': '2026-11-07'}))
          .interpret(['công việc ngày mai']);
      expect(agenda.intent, VoiceIntent.agenda);
      expect(agenda.queryDate, DateTime(2026, 11, 7));
      expect(agenda.queryDays, 1);
      // Không nói ngày: hôm nay theo giờ Việt Nam.
      expect(
          (await _service(() => _raw({...none, 'intent': 'agenda'}))
                  .interpret(['lịch']))
              .queryDate,
          DateTime(2026, 11, 6));

      final answer = await _service(() => _raw({
            ...none,
            'intent': 'answer',
            'reply': '  Mai Bác rảnh\n từ 10 giờ sáng.  ${'à' * 400}',
          })).interpret(['mai tui rảnh lúc nào']);
      expect(answer.intent, VoiceIntent.answer);
      expect(answer.reply, startsWith('Mai Bác rảnh từ 10 giờ sáng.'));
      expect(answer.reply!.length,
          lessThanOrEqualTo(VoiceTaskInterpretation.maxReply));

      expect(
          (await _service(() => _raw({...none, 'intent': 'complete'}))
                  .interpret(['xong rồi']))
              .intent,
          VoiceIntent.complete);
    });
  });

  test('nhiều việc nhiều giờ thì hỏi từng việc, không gọi AI', () async {
    var called = false;
    final r = await _service(() {
      called = true;
      return _raw({});
    }).interpret(['Mai 8 giờ sáng tưới cây, 9 giờ sáng đi bộ.']);
    expect(called, isFalse);
    expect(r.question, contains('từng việc một'));
  });

  test('AI trả sai schema thì báo chưa hiểu, không dùng kết quả', () async {
    for (final bad in <Object?>[
      'not json',
      _raw({'intent': 'delete'}),
      _raw({'hour': 24}),
      _raw({'date': 'mai'}),
      _raw({'habitKey': 'admin'}),
      _raw({'queryDays': 9}),
    ]) {
      await expectLater(
          _service(() => bad).interpret(['x']),
          throwsA(isA<AppException>().having(
              (e) => e is VoiceUnavailableException, 'fallback', false)),
          reason: '$bad');
    }
  });

  test('Gemini lỗi / hết lượt / mất mạng thì chuyển sang bộ hiểu trên máy',
      () async {
    for (final error in <Exception>[
      QuotaExceeded('quota'),
      ServerException('down'),
      Exception('network'),
    ]) {
      await expectLater(_service(() => error).interpret(['x']),
          throwsA(isA<VoiceUnavailableException>()));
    }
  });
}
