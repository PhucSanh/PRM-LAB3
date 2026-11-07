import 'package:an_nhien/widgets/time_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'wheel preserves minute precision and confirms only on save at $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      TimeOfDay? saved;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () async {
                        saved = await showTimeWheel(context,
                            initial: const TimeOfDay(hour: 0, minute: 37));
                      },
                      child: const Text('Mở'))))));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      final picker =
          tester.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
      expect(picker.initialDateTime.hour, 0);
      expect(picker.initialDateTime.minute, 37);
      expect(picker.use24hFormat, true);
      picker.onDateTimeChanged(DateTime(2030, 1, 1, 23, 59));
      await tester.pump();
      expect(saved, isNull);
      await tester.ensureVisible(find.text('Lưu giờ'));
      await tester.tap(find.text('Lưu giờ'));
      await tester.pumpAndSettle();
      expect(saved, const TimeOfDay(hour: 23, minute: 59));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('cancelling the wheel keeps the previous value', (tester) async {
    TimeOfDay? saved;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      saved = await showTimeWheel(context,
                          initial: const TimeOfDay(hour: 12, minute: 5));
                    },
                    child: const Text('Mở'))))));
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker).first, const Offset(0, -60));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hủy'));
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(tester.takeException(), isNull);
  });
  test('time labels distinguish midnight and noon', () {
    expect(formatTimeOfDay(const TimeOfDay(hour: 0, minute: 0)), '12:00 sáng');
    expect(
        formatTimeOfDay(const TimeOfDay(hour: 12, minute: 0)), '12:00 chiều');
  });
}
