import 'package:an_nhien/models/suggestion.dart';
import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/services/suggestion_service.dart';
import 'package:an_nhien/utils/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

/// F12 bước 01: SuggestionService (Fake dùng chung cho "2 máy") + model.
const mom = 'mom-uid';

Suggestion draft({String id = '', DateTime? at}) {
  final s = FakeSuggestionService.figmaSample(now: DateTime(2026, 11, 4));
  return s.copyWith(id: id, createdAt: at ?? DateTime(2026, 11, 4, 16, 20));
}

void main() {
  late FakeSuggestionService service;

  setUp(() => service = FakeSuggestionService(delay: Duration.zero));
  tearDown(() => service.dispose());

  group('dữ liệu mẫu đúng Figma', () {
    test('Mai · Con gái, 2 việc ngày mai, giờ để chọn 8:00 / 9:00 sáng', () {
      final s =
          FakeSuggestionService.figmaSample(now: DateTime(2026, 11, 4, 10));
      expect(s.fromName, 'Mai');
      expect(s.fromRelation, 'Con gái');
      expect(s.message, '“Mẹ ơi, mai mình đi bộ với cô Tám nhé?”');
      expect(s.createdAt, DateTime(2026, 11, 4, 16, 20));
      expect(s.status, SuggestionStatus.pending);
      expect(s.popupShown, isFalse);
      expect([for (final i in s.items) i.title],
          ['Đi bộ nhẹ nhàng', 'Thư giãn nhẹ nhàng']);
      expect([for (final i in s.items) i.habitKey], ['move', 'downshift']);
      expect([for (final i in s.items) i.time],
          const [SuggestionTime(8, 0), SuggestionTime(9, 0)]);
      expect([for (final i in s.items) i.durationMin], [20, 15]);
      for (final i in s.items) {
        expect(i.date, DateTime(2026, 11, 5));
        expect(
            i.timeOptions, const [SuggestionTime(8, 0), SuggestionTime(9, 0)]);
      }
    });

    test('withSample: máy Bác có sẵn gợi ý mẫu', () async {
      final s = FakeSuggestionService(delay: Duration.zero, withSample: true);
      final pending = await s.watchPending(mom).first;
      expect(pending.single.fromName, 'Mai');
      await s.dispose();
    });
  });

  group('gửi ↔ nhận giữa 2 máy', () {
    test('máy con cháu gửi → watchPending máy Bác phát gợi ý', () async {
      final emitted = <List<Suggestion>>[];
      final sub = service.watchPending(mom).listen(emitted.add);
      await pumpEventQueue();
      expect(emitted.single, isEmpty);

      await service.send(mom, draft());
      await pumpEventQueue();
      expect(emitted.last.single.fromName, 'Mai');
      expect(emitted.last.single.id, isNotEmpty);
      expect(emitted.last.single.status, SuggestionStatus.pending);
      expect(service.momNotified, 1);
      await sub.cancel();
    });

    test('mới nhất trước; gợi ý của Bác khác không lẫn vào', () async {
      await service.send(mom, draft(id: 'old', at: DateTime(2026, 11, 3)));
      await service.send(mom, draft(id: 'new', at: DateTime(2026, 11, 4)));
      await service.send('other-mom', draft(id: 'x'));
      final pending = await service.watchPending(mom).first;
      expect([for (final s in pending) s.id], ['new', 'old']);
    });

    test('markPopupShown → popup không hiện lại', () async {
      await service.send(mom, draft(id: 'g1'));
      await service.markPopupShown(mom, 'g1');
      expect((await service.byId(mom, 'g1'))!.popupShown, isTrue);
    });
  });

  group('nhận / bỏ qua', () {
    setUp(() => service.send(mom, draft(id: 'g1')));

    test('nhận một phần → partial, nhận tiếp việc còn lại → accepted',
        () async {
      final s = (await service.byId(mom, 'g1'))!;
      // Bác đổi giờ việc 1 trước khi nhận: vẫn khớp đúng việc.
      await service.accept(mom, 'g1', [s.items[0].copyWith(hour: 9)]);
      var now = (await service.byId(mom, 'g1'))!;
      expect(now.status, SuggestionStatus.partial);
      expect(now.acceptedCount, 1);
      expect(now.remaining.single.title, 'Thư giãn nhẹ nhàng');
      expect(await service.watchPending(mom).first, isEmpty);

      await service.accept(mom, 'g1', now.remaining);
      now = (await service.byId(mom, 'g1'))!;
      expect(now.status, SuggestionStatus.accepted);
    });

    test('nhận hết một lần → accepted', () async {
      final s = (await service.byId(mom, 'g1'))!;
      await service.accept(mom, 'g1', s.items);
      expect(
          (await service.byId(mom, 'g1'))!.status, SuggestionStatus.accepted);
    });

    test('dismiss → rời pending nhưng vẫn đọc lại được; undoDismiss → trở lại',
        () async {
      await service.dismiss(mom, 'g1');
      expect(await service.watchPending(mom).first, isEmpty);
      expect(
          (await service.byId(mom, 'g1'))!.status, SuggestionStatus.dismissed);

      await service.undoDismiss(mom, 'g1');
      expect((await service.watchPending(mom).first).single.id, 'g1');
    });

    test('undoDismiss gợi ý đã nhận một phần → về partial', () async {
      final s = (await service.byId(mom, 'g1'))!;
      await service.accept(mom, 'g1', [s.items.first]);
      await service.dismiss(mom, 'g1');
      await service.undoDismiss(mom, 'g1');
      expect((await service.byId(mom, 'g1'))!.status, SuggestionStatus.partial);
    });

    test('FR08: nhận / bỏ qua / hoàn tác không báo gì cho người gửi', () async {
      final s = (await service.byId(mom, 'g1'))!;
      await service.dismiss(mom, 'g1');
      await service.undoDismiss(mom, 'g1');
      await service.accept(mom, 'g1', [s.items.first]);
      await service.accept(mom, 'g1', [s.items.last]);
      expect(service.senderNotified, 0);
      expect(service.momNotified, 1); // chỉ lần gửi.
    });

    test('nhận danh sách rỗng → AppException', () async {
      expect(() => service.accept(mom, 'g1', const []),
          throwsA(isA<AppException>()));
    });

    test('id không có → byId null, hành động ném AppException', () async {
      expect(await service.byId(mom, 'nope'), isNull);
      expect(() => service.dismiss(mom, 'nope'), throwsA(isA<AppException>()));
    });
  });

  group('cờ lỗi', () {
    test('failOnSend', () async {
      service.failOnSend = true;
      expect(() => service.send(mom, draft()), throwsA(isA<AppException>()));
      expect(service.momNotified, 0);
    });

    test('failOnLoad: watchPending phát lỗi, byId ném', () async {
      service.failOnLoad = true;
      expect(service.watchPending(mom).first, throwsA(isA<AppException>()));
      expect(() => service.byId(mom, 'g1'), throwsA(isA<AppException>()));
    });

    test('failOnAccept: lỗi, trạng thái giữ pending', () async {
      await service.send(mom, draft(id: 'g1'));
      final s = (await service.byId(mom, 'g1'))!;
      service.failOnAccept = true;
      await expectLater(
          service.accept(mom, 'g1', s.items), throwsA(isA<AppException>()));
      expect((await service.byId(mom, 'g1'))!.status, SuggestionStatus.pending);
    });
  });

  group('model', () {
    test('Suggestion toMap / fromMap giữ nguyên dữ liệu', () {
      final s = draft(id: 'g1');
      final back = Suggestion.fromMap('g1', s.toMap());
      expect(back.fromName, s.fromName);
      expect(back.fromRelation, s.fromRelation);
      expect(back.message, s.message);
      expect(back.createdAt, s.createdAt);
      expect(back.items.first.date, DateTime(2026, 11, 5));
      expect(back.items.first.timeOptions, s.items.first.timeOptions);
      expect(back.items.last.durationMin, 15);
    });

    test('fromMap thiếu trường mới (fromRelation, timeOptions) không lỗi', () {
      final s = Suggestion.fromMap('g1', {
        'fromUid': 'u',
        'fromName': 'Mai',
        'items': [
          {
            'title': 'Đi bộ',
            'habitKey': 'move',
            'date': '2026-11-05',
            'hour': 8,
            'minute': 0
          }
        ],
        'status': 'partial',
        'createdAt': 0,
      });
      expect(s.fromRelation, isNull);
      expect(s.items.single.timeOptions, isEmpty);
      expect(s.status, SuggestionStatus.partial);
    });

    test('SuggestionItem.toTask → việc một lần đúng ngày, giờ, thời lượng', () {
      final task = draft().items.first.copyWith(hour: 9).toTask('t1');
      expect(task.repeat, RepeatRule.once);
      expect(task.startDate, DateTime(2026, 11, 5));
      expect(task.hour, 9);
      expect(task.durationMin, 20);
    });

    test('TaskItem: startDate / durationMin lưu được, dữ liệu cũ vẫn đọc được',
        () {
      final t = TaskItem(
          id: 't',
          title: 'Đi bộ',
          habitKey: 'move',
          hour: 8,
          minute: 0,
          startDate: DateTime(2026, 11, 5, 23, 59),
          durationMin: 20);
      final back = TaskItem.fromMap('t', t.toMap());
      expect(t.toMap()['startDate'], '2026-11-05');
      expect(back.startDate, DateTime(2026, 11, 5));
      expect(back.durationMin, 20);

      final legacy =
          TaskItem.fromMap('t', {'title': 'Cũ', 'hour': 7, 'minute': 0});
      expect(legacy.startDate, isNull);
      expect(legacy.durationMin, isNull);
      expect(
          const TaskItem(
                  id: 'x', title: 'a', habitKey: 'move', hour: 1, minute: 0)
              .toMap()
              .containsKey('startDate'),
          isFalse);
    });
  });
}
