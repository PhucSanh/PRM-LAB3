import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:an_nhien/widgets/choice_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Nhóm chọn giữ giá trị trong state.
class _Host<T> extends StatefulWidget {
  const _Host(
      {required this.options,
      required this.initial,
      this.layout = ChoiceLayout.list});
  final List<ChoiceOption<T>> options;
  final T? initial;
  final ChoiceLayout layout;

  @override
  State<_Host<T>> createState() => _HostState<T>();
}

class _HostState<T> extends State<_Host<T>> {
  late T? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: AppSpacing.screenPadding, children: [
      ChoiceGroup<T>(
        options: widget.options,
        value: _value,
        layout: widget.layout,
        onChanged: (v) => setState(() => _value = v),
      ),
    ]);
  }
}

const _relations = [
  ChoiceOption(value: 'con', label: 'Con'),
  ChoiceOption(value: 'chau', label: 'Cháu'),
  ChoiceOption(value: 'ban', label: 'Bạn bè'),
  ChoiceOption(value: 'khac', label: 'Khác'),
];

final _fontScales = [
  for (final s in AppFontScale.values)
    ChoiceOption(value: s, label: s.label, previewScale: s.factor),
];

const _roles = [
  ChoiceOption(
    value: 'elder',
    label: 'Tôi là người lớn tuổi',
    description: 'Tự xem và làm theo lịch của mình',
    icon: Icons.person_outline_rounded,
  ),
  ChoiceOption(
    value: 'family',
    label: 'Tôi là con, cháu',
    description: 'Lập lịch giúp bố mẹ, ông bà và theo dõi từ xa',
    icon: Icons.volunteer_activism_rounded,
  ),
];

void main() {
  group('ChoiceGroup', () {
    testWidgets('list: chọn lựa chọn khác → dấu tích + "Đang chọn" chuyển theo',
        (tester) async {
      await pumpHarness(
          tester, const _Host<String>(options: _relations, initial: 'con'));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Đang chọn'), findsOneWidget);
      final conTile = find
          .ancestor(of: find.text('Con'), matching: find.byType(Material))
          .first;
      expect(find.descendant(of: conTile, matching: find.text('Đang chọn')),
          findsOneWidget);

      await tester.tap(find.text('Bạn bè'));
      await tester.pumpAndSettle();
      final banTile = find
          .ancestor(of: find.text('Bạn bè'), matching: find.byType(Material))
          .first;
      expect(
          find.descendant(
              of: banTile, matching: find.byIcon(Icons.check_circle_rounded)),
          findsOneWidget);
      expect(find.descendant(of: conTile, matching: find.text('Đang chọn')),
          findsNothing);
      expect(find.text('Đang chọn'), findsOneWidget);
    });

    testWidgets('mỗi ô cao ≥ 72, Semantics radio (checked + nhóm loại trừ)',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHarness(
          tester, const _Host<String>(options: _relations, initial: 'chau'));
      for (final label in ['Con', 'Cháu', 'Bạn bè', 'Khác']) {
        final tile = find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first;
        expect(tester.getSize(tile).height,
            greaterThanOrEqualTo(AppSizes.minTarget));
      }
      expect(
        tester.getSemantics(find
            .ancestor(of: find.text('Cháu'), matching: find.byType(Semantics))
            .first),
        isSemantics(
            label: 'Cháu',
            isInMutuallyExclusiveGroup: true,
            hasCheckedState: true,
            isChecked: true),
      );
      semantics.dispose();
    });

    testWidgets('S01: mỗi lựa chọn vẽ chữ mẫu đúng cỡ (1.0 / 1.15 / 1.3)',
        (tester) async {
      await pumpHarness(tester,
          _Host<AppFontScale>(options: _fontScales, initial: AppFontScale.lon),
          scale: 1);
      final heights = [
        for (final s in AppFontScale.values)
          tester.getSize(find.text(s.label)).height
      ];
      expect(heights[0], lessThan(heights[1]));
      expect(heights[1], lessThan(heights[2]));
      await tester.tap(find.text('Rất lớn'));
      await tester.pumpAndSettle();
      final tile = find
          .ancestor(of: find.text('Rất lớn'), matching: find.byType(Material))
          .first;
      expect(
          find.descendant(
              of: tile, matching: find.byIcon(Icons.check_circle_rounded)),
          findsOneWidget);
    });

    testWidgets('segmented: 2 ô ngang hàng, bằng nhau, đổi lựa chọn được',
        (tester) async {
      await pumpHarness(
        tester,
        const _Host<String>(
          options: [
            ChoiceOption(value: 'ong', label: 'Ông'),
            ChoiceOption(value: 'ba', label: 'Bà')
          ],
          initial: 'ong',
          layout: ChoiceLayout.segmented,
        ),
      );
      final ong = tester.getRect(find
          .ancestor(of: find.text('Ông'), matching: find.byType(InkWell))
          .first);
      final ba = tester.getRect(find
          .ancestor(of: find.text('Bà'), matching: find.byType(InkWell))
          .first);
      expect(ong.top, ba.top);
      expect(ong.width, closeTo(ba.width, 0.5));
      await tester.tap(find.text('Bà'));
      await tester.pumpAndSettle();
      final baTile = find
          .ancestor(of: find.text('Bà'), matching: find.byType(Material))
          .first;
      expect(
          find.descendant(
              of: baTile, matching: find.byIcon(Icons.check_circle_rounded)),
          findsOneWidget);
    });

    for (final (width, scale) in [
      (360.0, 1.3),
      (360.0, 2.0),
      (412.0, 1.3),
      (412.0, 2.0)
    ]) {
      testWidgets(
          '$width dp × $scale: list có mô tả + icon, segmented không tràn',
          (tester) async {
        await pumpHarness(
          tester,
          ListView(padding: AppSpacing.screenPadding, children: [
            ChoiceGroup<String>(
                options: _roles, value: 'family', onChanged: (_) {}),
            const SizedBox(height: AppSpacing.lg),
            ChoiceGroup<String>(
                options: _relations, value: 'con', onChanged: (_) {}),
            const SizedBox(height: AppSpacing.lg),
            ChoiceGroup<String>(
              options: const [
                ChoiceOption(value: 'daily', label: 'Mỗi ngày'),
                ChoiceOption(value: 'pick', label: 'Chọn ngày'),
              ],
              value: 'daily',
              layout: ChoiceLayout.segmented,
              onChanged: (_) {},
            ),
            const SizedBox(height: AppSpacing.lg),
            ChoiceGroup<AppFontScale>(
                options: _fontScales,
                value: AppFontScale.ratLon,
                onChanged: (_) {}),
          ]),
          width: width,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
