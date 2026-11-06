import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/widgets/app_back_bar.dart';
import 'package:an_nhien/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  group('AppButton', () {
    const expectedType = {
      AppButtonKind.primary: FilledButton,
      AppButtonKind.secondary: OutlinedButton,
      AppButtonKind.tonal: FilledButton,
      AppButtonKind.text: TextButton,
      AppButtonKind.danger: FilledButton,
      AppButtonKind.dangerOutline: OutlinedButton,
    };

    for (final kind in AppButtonKind.values) {
      testWidgets('$kind: vẽ đúng loại nút, cao ≥ 72, bấm được',
          (tester) async {
        var taps = 0;
        await pumpHarness(
          tester,
          Padding(
            padding: AppSpacing.screenPadding,
            child: AppButton(
                label: 'Lưu việc này',
                icon: Icons.save_rounded,
                kind: kind,
                onPressed: () => taps++),
          ),
        );
        expect(find.byType(expectedType[kind]!), findsOneWidget);
        expect(tester.getSize(find.byType(expectedType[kind]!)).height,
            greaterThanOrEqualTo(AppSizes.minTarget));
        await tester.tap(find.text('Lưu việc này'));
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('TalkBack activates the shared button exactly once',
        (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpHarness(
          tester,
          AppButton(
              label: 'Lưu việc này',
              icon: Icons.save,
              onPressed: () => taps++));
      final node = tester.getSemantics(find.byType(AppButton));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.binding.pipelineOwner.semanticsOwner!
          .performAction(node.id, SemanticsAction.tap);
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('busy: hiện vòng xoay và không bấm được', (tester) async {
      var taps = 0;
      await pumpHarness(
        tester,
        AppButton(
            label: 'Lưu việc này',
            icon: Icons.save_rounded,
            busy: true,
            onPressed: () => taps++),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Lưu việc này'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('nhãn dài ở 360 dp + 1.3 không tràn', (tester) async {
      await pumpHarness(
        tester,
        Padding(
          padding: AppSpacing.screenPadding,
          child: AppButton(
              label: 'Lần này và các lần sau',
              icon: Icons.date_range_rounded,
              onPressed: () {}),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppBackBar', () {
    testWidgets('chỉ Quay lại: bấm thì pop', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(appBar: AppBackBar(), body: Text('Màn 2')))),
            child: const Text('Mở'),
          ),
        ),
      ));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      expect(find.text('Màn 2'), findsOneWidget);
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Màn 2'), findsNothing);
    });

    testWidgets('Quay lại + Bước x/y', (tester) async {
      await pumpHarness(tester, const SizedBox(),
          appBar: const AppBackBar(step: 'Bước 1/2'));
      expect(find.text('Quay lại'), findsOneWidget);
      expect(find.text('Bước 1/2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Quay lại + nút "Sửa" (S04)', (tester) async {
      var edits = 0;
      await pumpHarness(
        tester,
        const SizedBox(),
        appBar: AppBackBar(
            backLabel: 'Hôm nay',
            trailing: AppBarEditButton(onPressed: () => edits++)),
      );
      expect(find.text('Hôm nay'), findsOneWidget);
      await tester.tap(find.text('Sửa'));
      expect(edits, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
