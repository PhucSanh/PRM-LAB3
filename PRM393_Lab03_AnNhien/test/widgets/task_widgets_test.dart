import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/theme/app_icons.dart';
import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/widgets/task_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  group('TaskRow', () {
    const expected = {
      TaskStatus.pending: ('Chưa làm', AppIcons.radioOff),
      TaskStatus.done: ('Đã xong', AppIcons.checkCircle),
      TaskStatus.skipped: ('Bỏ qua', AppIcons.statusSkipped),
      TaskStatus.postponed: ('Đã dời', AppIcons.statusPostponed),
    };

    for (final status in TaskStatus.values) {
      testWidgets('$status: đúng chữ + icon, cao ≥ 72, TalkBack đọc giờ + tên + trạng thái', (tester) async {
        final semantics = tester.ensureSemantics();
        var taps = 0;
        await pumpHarness(
          tester,
          Padding(
            padding: AppSpacing.screenPadding,
            child: TaskRow(
              time: const TimeOfDay(hour: 6, minute: 0),
              title: 'Đi bộ',
              habitKey: 'move',
              status: status,
              onTap: () => taps++,
            ),
          ),
        );
        final (label, icon) = expected[status]!;
        expect(find.text(label), findsOneWidget);
        expect(find.byIcon(icon), findsOneWidget);
        expect(find.text('6 giờ sáng'), findsOneWidget);
        expect(find.text('Vận động tự nhiên'), findsOneWidget); // dòng phụ mặc định = tên thói quen
        expect(tester.getSize(find.byType(TaskRow)).height, greaterThanOrEqualTo(AppSizes.minTarget));
        expect(
          tester.getSemantics(find.byType(TaskRow)),
          isSemantics(label: '6 giờ sáng, Đi bộ, ${label.toLowerCase()}. Vận động tự nhiên', isButton: true),
        );
        await tester.tap(find.text('Đi bộ'));
        expect(taps, 1);
        semantics.dispose();
      });
    }

    testWidgets('note thay dòng phụ; giờ lẻ viết "9:30 sáng"; showChevron hiện ›', (tester) async {
      await pumpHarness(
        tester,
        TaskRow(
          time: const TimeOfDay(hour: 9, minute: 30),
          title: 'Đi bộ quanh công viên',
          habitKey: 'move',
          status: TaskStatus.skipped,
          note: 'Hôm nay trời mưa',
          showChevron: true,
          onTap: () {},
        ),
      );
      expect(find.text('9:30 sáng'), findsOneWidget);
      expect(find.text('Hôm nay trời mưa'), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);
    });
  });

  group('NextTaskCard', () {
    testWidgets('"Đã xong" là AppButton primary; mỗi nút gọi đúng callback', (tester) async {
      final calls = <String>[];
      await pumpHarness(
        tester,
        ListView(padding: AppSpacing.screenPadding, children: [
          NextTaskCard(
            time: const TimeOfDay(hour: 15, minute: 0),
            title: 'Uống trà với cô Tám',
            habitKey: 'tea',
            durationMinutes: 20,
            onDone: () => calls.add('done'),
            onLater: () => calls.add('later'),
            onSkip: () => calls.add('skip'),
            onTap: () => calls.add('open'),
          ),
        ]),
      );
      expect(find.text('Việc tiếp theo · 3 giờ chiều'), findsOneWidget);
      expect(find.text('20 phút · Trà chiều cùng bạn'), findsOneWidget);
      expect(find.ancestor(of: find.text('Đã xong'), matching: find.byType(FilledButton)), findsOneWidget);

      for (final label in ['Đã xong', 'Dời lại', 'Hôm nay bỏ qua', 'Uống trà với cô Tám']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
      }
      expect(calls, ['done', 'later', 'skip', 'open']);
    });

    testWidgets('không truyền onLater / onSkip thì ẩn nút', (tester) async {
      await pumpHarness(
        tester,
        NextTaskCard(time: const TimeOfDay(hour: 9, minute: 30), title: 'Đi bộ', habitKey: 'move', onDone: () {}),
      );
      expect(find.text('Dời lại'), findsNothing);
      expect(find.text('Hôm nay bỏ qua'), findsNothing);
    });
  });

  for (final (width, scale) in [(360.0, 1.3), (360.0, 2.0), (412.0, 1.3), (412.0, 2.0)]) {
    testWidgets('$width dp × $scale: TaskRow 4 trạng thái + NextTaskCard không tràn', (tester) async {
      await pumpHarness(
        tester,
        ListView(padding: AppSpacing.screenPadding, children: [
          NextTaskCard(
            time: const TimeOfDay(hour: 10, minute: 0),
            title: 'Đi bộ quanh công viên',
            habitKey: 'move',
            durationMinutes: 20,
            onDone: () {},
            onLater: () {},
            onSkip: () {},
            onTap: () {},
          ),
          for (final status in TaskStatus.values) ...[
            const SizedBox(height: AppSpacing.betweenTargets),
            TaskRow(
              time: const TimeOfDay(hour: 18, minute: 45),
              title: 'Gọi điện cho Mai và hỏi thăm các cháu',
              habitKey: 'family',
              status: status,
              note: 'Hôm nay thấy trong người mệt',
              showChevron: true,
              onTap: () {},
            ),
          ],
        ]),
        width: width,
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
