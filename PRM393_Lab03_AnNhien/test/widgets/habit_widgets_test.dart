import 'package:an_nhien/theme/app_colors.dart';
import 'package:an_nhien/theme/app_icons.dart';
import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/widgets/habit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _keys = [
  'move',
  'purpose',
  'downshift',
  'eighty',
  'plant',
  'tea',
  'belong',
  'family',
  'tribe'
];

void main() {
  group('HabitStyle', () {
    test('đủ 9 khoá: tên theo vocabulary.md, icon khác nhau, có câu mô tả', () {
      expect([
        for (final k in _keys) HabitStyle.nameOf(k)
      ], [
        'Vận động tự nhiên',
        'Sống có mục đích',
        'Thư giãn mỗi ngày',
        'Ăn vừa đủ',
        'Ăn nhiều rau, đậu',
        'Trà chiều cùng bạn',
        'Gắn kết cộng đồng',
        'Gia đình trên hết',
        'Bạn bè tích cực',
      ]);
      expect({for (final k in _keys) HabitStyle.iconOf(k)}.length, 9);
      for (final k in _keys) {
        expect(HabitStyle.descriptionOf(k), isNotEmpty, reason: k);
      }
    });

    test('khoá lạ rơi về move', () {
      expect(HabitStyle.nameOf('xyz'), 'Vận động tự nhiên');
      expect(HabitStyle.iconOf('xyz'), AppIcons.walk);
    });
  });

  group('HabitBadge', () {
    testWidgets('đủ 9 khoá không lỗi: nền dịu + icon đậm + TalkBack đọc tên',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHarness(
        tester,
        Wrap(
            spacing: AppSpacing.sm,
            children: [for (final k in _keys) HabitBadge(habitKey: k)]),
      );
      expect(tester.takeException(), isNull);
      for (final k in _keys) {
        final badge =
            find.byWidgetPredicate((w) => w is HabitBadge && w.habitKey == k);
        final box = tester.widget<Container>(
            find.descendant(of: badge, matching: find.byType(Container)));
        expect((box.decoration! as BoxDecoration).color, HabitPalette.of(k).bg,
            reason: k);
        final icon = tester.widget<Icon>(
            find.descendant(of: badge, matching: find.byType(Icon)));
        expect(icon.icon, HabitStyle.iconOf(k));
        expect(icon.color, HabitPalette.of(k).fg);
        expect(tester.getSize(badge), const Size.square(AppSizes.habitIcon));
        expect(tester.getSemantics(badge),
            isSemantics(label: HabitStyle.nameOf(k), isImage: true));
      }
      semantics.dispose();
    });

    testWidgets('large badge keeps icon proportional to the touch target',
        (tester) async {
      await pumpHarness(
          tester,
          const Center(
              child: HabitBadge(habitKey: 'tea', size: AppSizes.minTarget)));
      expect(
          tester.widget<Icon>(find.byType(Icon)).size, AppSizes.minTarget / 2);
    });
  });

  group('HabitTile', () {
    testWidgets('S08: tên mặc định + mũi tên ›, bấm gọi onTap', (tester) async {
      var taps = 0;
      await pumpHarness(
          tester, HabitTile(habitKey: 'plant', onTap: () => taps++));
      expect(find.text('Ăn nhiều rau, đậu'), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
      expect(tester.getSize(find.byType(HabitTile)).height,
          greaterThanOrEqualTo(AppSizes.minTarget));
      await tester.tap(find.text('Ăn nhiều rau, đậu'));
      expect(taps, 1);
    });

    testWidgets(
        'S05: selected có dấu + "Đã chọn", không chọn có "Chọn"; Semantics checked',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHarness(
        tester,
        ListView(children: [
          HabitTile(
            habitKey: 'move',
            name: 'Đi bộ nhẹ nhàng',
            description: 'Vận động theo sức của Bác',
            selected: true,
            onTap: () {},
          ),
          HabitTile(
              habitKey: 'family',
              name: 'Gọi người thân',
              icon: AppIcons.phone,
              selected: false,
              onTap: () {}),
        ]),
      );
      expect(find.text('Đã chọn'), findsOneWidget);
      expect(find.text('Chọn'), findsOneWidget);
      expect(find.byIcon(AppIcons.phone), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(HabitTile).first),
        isSemantics(
            label: 'Đi bộ nhẹ nhàng',
            hint: 'Vận động theo sức của Bác',
            isChecked: true,
            isButton: true),
      );
      semantics.dispose();
    });
  });

  for (final (width, scale) in [(360.0, 1.3), (360.0, 2.0), (412.0, 2.0)]) {
    testWidgets('$width dp × $scale: 9 HabitTile có mô tả không tràn',
        (tester) async {
      await pumpHarness(
        tester,
        ListView(padding: AppSpacing.screenPadding, children: [
          for (final k in _keys)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.betweenTargets),
              child: HabitTile(
                habitKey: k,
                description: HabitStyle.descriptionOf(k),
                selected: k == 'move' ? true : null,
                onTap: () {},
              ),
            ),
        ]),
        width: width,
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
