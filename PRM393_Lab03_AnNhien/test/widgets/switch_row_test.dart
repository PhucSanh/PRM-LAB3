import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/widgets/switch_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: AppSpacing.screenPadding, children: [
      SwitchRow(
        title: 'Chữ và nền rõ hơn',
        subtitle: 'Tăng độ tương phản',
        icon: Icons.contrast_rounded,
        value: _on,
        onChanged: (v) => setState(() => _on = v),
      ),
    ]);
  }
}

void main() {
  group('SwitchRow', () {
    testWidgets(
        'bấm vào chữ (cả hàng) thì đổi giá trị + chữ "Đang bật / Đang tắt"',
        (tester) async {
      await pumpHarness(tester, const _Host());
      expect(find.text('Đang tắt'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

      await tester.tap(find.text('Chữ và nền rõ hơn'));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text('Đang bật'), findsOneWidget);

      await tester.tap(find.text('Tăng độ tương phản'));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('cao ≥ 72, Semantics toggled + nhãn đủ câu', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHarness(tester, const _Host());
      expect(tester.getSize(find.byType(InkWell).first).height,
          greaterThanOrEqualTo(AppSizes.minTarget));
      expect(
        tester.getSemantics(find.byType(SwitchRow)),
        isSemantics(
            label: 'Chữ và nền rõ hơn. Tăng độ tương phản',
            hasToggledState: true,
            isToggled: false),
      );
      semantics.dispose();
    });

    testWidgets('onChanged null → khoá, bấm không đổi', (tester) async {
      await pumpHarness(
          tester,
          const SwitchRow(
              title: 'Đọc to nội dung', value: true, onChanged: null));
      await tester.tap(find.text('Đọc to nội dung'));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    for (final (width, scale) in [
      (360.0, 1.3),
      (360.0, 2.0),
      (412.0, 1.3),
      (412.0, 2.0)
    ]) {
      testWidgets('$width dp × $scale: không tràn', (tester) async {
        await pumpHarness(tester, const _Host(), width: width, scale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
