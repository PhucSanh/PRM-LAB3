import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/widgets/time_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Ô "Giờ làm" giữ giá trị trong state, như màn S06 dùng.
class _Host extends StatefulWidget {
  const _Host({this.initial});
  final TimeOfDay? initial;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late TimeOfDay? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: AppSpacing.screenPadding, children: [
      TimeField(
          label: 'Giờ làm',
          value: _value,
          onChanged: (t) => setState(() => _value = t)),
    ]);
  }
}

/// Cuộn tới ô trong hộp chọn giờ rồi chạm (phần lưới cuộn được khi chữ lớn).
Future<void> _tapCell(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pump();
}

void main() {
  group('formatTimeOfDay', () {
    test('viết giờ kiểu nói hằng ngày (SG-10)', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 6, minute: 0)), '6:00 sáng');
      expect(
          formatTimeOfDay(const TimeOfDay(hour: 9, minute: 30)), '9:30 sáng');
      expect(
          formatTimeOfDay(const TimeOfDay(hour: 0, minute: 5)), '12:05 sáng');
      expect(
          formatTimeOfDay(const TimeOfDay(hour: 12, minute: 0)), '12:00 chiều');
      expect(
          formatTimeOfDay(const TimeOfDay(hour: 15, minute: 0)), '3:00 chiều');
      expect(
          formatTimeOfDay(const TimeOfDay(hour: 20, minute: 15)), '8:15 tối');
    });

    test(
        'wholeHourInWords: giờ chẵn viết "3 giờ chiều", giờ lẻ giữ "9:30 sáng"',
        () {
      expect(
          formatTimeOfDay(const TimeOfDay(hour: 15, minute: 0),
              wholeHourInWords: true),
          '3 giờ chiều');
      expect(
          formatTimeOfDay(const TimeOfDay(hour: 9, minute: 30),
              wholeHourInWords: true),
          '9:30 sáng');
    });

    test('speakTimeOfDay: câu đọc không có dấu ":"', () {
      expect(speakTimeOfDay(const TimeOfDay(hour: 6, minute: 0)), '6 giờ sáng');
      expect(speakTimeOfDay(const TimeOfDay(hour: 9, minute: 30)),
          '9 giờ 30 sáng');
      expect(
          speakTimeOfDay(const TimeOfDay(hour: 18, minute: 5)), '6 giờ 05 tối');
    });
  });

  group('TimeField', () {
    testWidgets('hiện "6:00 sáng" + "Đổi giờ", cao ≥ 72', (tester) async {
      await pumpHarness(
          tester, const _Host(initial: TimeOfDay(hour: 6, minute: 0)));
      expect(find.text('6:00 sáng'), findsOneWidget);
      expect(find.text('Đổi giờ'), findsOneWidget);
      expect(tester.getSize(find.byType(InkWell)).height,
          greaterThanOrEqualTo(AppSizes.minTarget));
    });

    testWidgets('chưa có giờ thì hiện "Chọn giờ"; có lỗi thì hiện câu lỗi',
        (tester) async {
      await pumpHarness(
        tester,
        TimeField(
            label: 'Giờ làm',
            value: null,
            errorText: 'Chọn giờ để nhắc mẹ đúng lúc',
            onChanged: (_) {}),
      );
      expect(find.text('Chọn giờ'), findsOneWidget);
      expect(find.text('Chọn giờ để nhắc mẹ đúng lúc'), findsOneWidget);
    });

    testWidgets('bấm ô → chọn 3, 30, Chiều → Lưu giờ → "3:30 chiều"',
        (tester) async {
      await pumpHarness(
          tester, const _Host(initial: TimeOfDay(hour: 8, minute: 0)));
      await tester.tap(find.text('8:00 sáng'));
      await tester.pumpAndSettle();

      expect(find.text('Giờ làm'), findsNWidgets(2)); // nhãn ô + tiêu đề hộp
      expect(find.text('Bác chọn: 8:00 sáng'), findsOneWidget);
      await _tapCell(tester, '3');
      await _tapCell(tester, 'Chiều');
      await _tapCell(tester, '30');
      expect(find.text('Bác chọn: 3:30 chiều'), findsOneWidget);

      await tester.tap(find.text('Lưu giờ'));
      await tester.pumpAndSettle();
      expect(find.byType(TimeGridDialog), findsNothing);
      expect(find.text('3:30 chiều'), findsOneWidget);
    });

    testWidgets('Hủy → không đổi giờ', (tester) async {
      await pumpHarness(
          tester, const _Host(initial: TimeOfDay(hour: 8, minute: 0)));
      await tester.tap(find.text('8:00 sáng'));
      await tester.pumpAndSettle();
      await _tapCell(tester, '5');
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('8:00 sáng'), findsOneWidget);
    });
  });

  group('showTimeWheel', () {
    Future<void> open(WidgetTester tester, TimeOfDay initial,
        {double width = 360, double scale = 1.3}) async {
      await pumpHarness(
        tester,
        launcher(
            'Mở',
            (context) => showTimeWheel(context,
                initial: initial, title: 'Giờ thức dậy')),
        width: width,
        scale: scale,
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      expect(find.text('Giờ thức dậy'), findsOneWidget);
    }

    testWidgets('trả đúng TimeOfDay: 12 giờ Sáng = 0:00, 12 giờ Chiều = 12:00',
        (tester) async {
      TimeOfDay? result;
      await pumpHarness(
        tester,
        launcher(
            'Mở', (context) async => result = await showTimeWheel(context)),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      expect(find.text('Bác chọn: 8:00 sáng'),
          findsOneWidget); // mặc định 8:00 sáng

      await _tapCell(tester, '12');
      await _tapCell(tester, '45');
      await tester.tap(find.text('Lưu giờ'));
      await tester.pumpAndSettle();
      expect(result, const TimeOfDay(hour: 0, minute: 45));

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await _tapCell(tester, '12');
      await _tapCell(tester, 'Chiều');
      await tester.tap(find.text('Lưu giờ'));
      await tester.pumpAndSettle();
      expect(result, const TimeOfDay(hour: 12, minute: 0));
    });

    testWidgets('giờ đã lưu có phút lẻ (19:40) vẫn hiện và giữ được',
        (tester) async {
      await open(tester, const TimeOfDay(hour: 19, minute: 40));
      expect(find.text('40'), findsOneWidget);
      final chieu = find
          .ancestor(of: find.text('Chiều'), matching: find.byType(Semantics))
          .first;
      expect(tester.getSemantics(chieu), isSemantics(isSelected: true));
      expect(find.text('Bác chọn: 7:40 tối'), findsOneWidget);
    });

    testWidgets('chạm ra ngoài → null', (tester) async {
      TimeOfDay? result = const TimeOfDay(hour: 1, minute: 0);
      await pumpHarness(
        tester,
        launcher(
            'Mở', (context) async => result = await showTimeWheel(context)),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('ô chọn và nút cao ≥ 72; ô có Semantics "Giờ, 5" đang chọn',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester, const TimeOfDay(hour: 5, minute: 0));
      expect(
          tester
              .getSize(find.ancestor(
                  of: find.text('5'), matching: find.byType(InkWell)))
              .height,
          greaterThanOrEqualTo(AppSizes.minTarget));
      expect(
        tester.getSemantics(find
            .ancestor(of: find.text('5'), matching: find.byType(Semantics))
            .first),
        isSemantics(label: 'Giờ, 5', isSelected: true, isButton: true),
      );
      semantics.dispose();
    });

    for (final (width, scale) in [(360.0, 1.3), (360.0, 2.0), (412.0, 2.0)]) {
      testWidgets(
          '$width dp × $scale: hộp không tràn, "Bác chọn" + 2 nút luôn thấy',
          (tester) async {
        await open(tester, const TimeOfDay(hour: 10, minute: 45),
            width: width, scale: scale);
        expect(tester.takeException(), isNull);
        for (final text in ['Bác chọn: 10:45 sáng', 'Lưu giờ', 'Hủy']) {
          expect(tester.getRect(find.text(text)).bottom, lessThanOrEqualTo(800),
              reason: text);
        }
      });
    }
  });
}
