import 'package:an_nhien/widgets/undo_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  Future<void> open(WidgetTester tester, VoidCallback onUndo,
      {double scale = 1.3}) async {
    await pumpHarness(
      tester,
      launcher(
        'Xong',
        (c) => showUndoSnackbar(c,
            title: 'Đã ghi: Đi bộ xong lúc 9:42 sáng.',
            subtitle: 'Giỏi lắm Bác!',
            onUndo: onUndo),
      ),
      scale: scale,
    );
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
  }

  for (final scale in [1.3, 2.0]) {
    testWidgets('tự tắt sau 6 giây, không tràn ở 360 dp ×$scale',
        (tester) async {
      await open(tester, () {}, scale: scale);
      expect(find.text('Đã ghi: Đi bộ xong lúc 9:42 sáng.'), findsOneWidget);
      expect(find.text('Giỏi lắm Bác!'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Hoàn tác'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  testWidgets('nút Hoàn tác cao ≥ 48, bấm thì gọi onUndo và đóng',
      (tester) async {
    var undone = 0;
    await open(tester, () => undone++);
    final undo = find.widgetWithText(OutlinedButton, 'Hoàn tác');
    expect(tester.getSize(undo).height, greaterThanOrEqualTo(48));

    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('nút Đóng tắt snackbar, không hoàn tác', (tester) async {
    var undone = 0;
    await open(tester, () => undone++);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(undone, 0);
    expect(find.byType(SnackBar), findsNothing);
  });
}
