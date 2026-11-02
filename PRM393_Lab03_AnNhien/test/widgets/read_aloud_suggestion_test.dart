import 'package:an_nhien/theme/app_icons.dart';
import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/widgets/read_aloud_button.dart';
import 'package:an_nhien/widgets/suggestion_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  group('ReadAloudButton', () {
    testWidgets('chưa đọc: "Đọc to" + loa, cao ≥ 72, bấm gọi onPressed', (tester) async {
      var taps = 0;
      await pumpHarness(tester, ReadAloudButton(onPressed: () => taps++));
      expect(find.text('Đọc to'), findsOneWidget);
      expect(find.byIcon(AppIcons.volume), findsOneWidget);
      expect(tester.getSize(find.byType(OutlinedButton)).height, greaterThanOrEqualTo(AppSizes.minTarget));
      await tester.tap(find.text('Đọc to'));
      expect(taps, 1);
    });

    testWidgets('đang đọc: "Đang đọc…" (liveRegion) + "Dừng đọc"', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await pumpHarness(tester, ReadAloudButton(onPressed: () => taps++, speaking: true));
      expect(find.text('Đang đọc…'), findsOneWidget);
      expect(tester.getSemantics(find.text('Đang đọc…')), isSemantics(isLiveRegion: true));
      await tester.tap(find.text('Dừng đọc'));
      expect(taps, 1);
      semantics.dispose();
    });
  });

  group('SuggestionCard', () {
    testWidgets('G12: tiêu đề, tên việc, câu trạng thái; Xem gợi ý / Bỏ qua gợi ý gọi đúng callback', (tester) async {
      final calls = <String>[];
      await pumpHarness(
        tester,
        ListView(padding: AppSpacing.screenPadding, children: [
          SuggestionCard(
            fromName: 'Mai',
            itemCount: 2,
            previewTitles: const ['Đi bộ với cô Tám', 'Gọi điện cho Mai'],
            onOpen: () => calls.add('open'),
            onDismiss: () => calls.add('dismiss'),
          ),
        ]),
      );
      expect(find.text('Mai gửi Bác 2 việc'), findsOneWidget);
      expect(find.text('• Đi bộ với cô Tám'), findsOneWidget);
      expect(find.text('Chưa thêm vào lịch. Bác tự chọn.'), findsOneWidget);
      await tester.tap(find.text('Xem gợi ý'));
      await tester.ensureVisible(find.text('Bỏ qua gợi ý'));
      await tester.tap(find.text('Bỏ qua gợi ý'));
      expect(calls, ['open', 'dismiss']);
    });

    testWidgets('quá 3 việc thì gom "và … việc khác"; không có onDismiss thì ẩn nút', (tester) async {
      await pumpHarness(
        tester,
        SuggestionCard(
          fromName: 'Hùng',
          itemCount: 5,
          previewTitles: const ['Một', 'Hai', 'Ba', 'Bốn', 'Năm'],
          onOpen: () {},
        ),
        scale: 1,
      );
      expect(find.text('• Bốn'), findsNothing);
      expect(find.text('và 2 việc khác'), findsOneWidget);
      expect(find.text('Bỏ qua gợi ý'), findsNothing);
    });
  });

  for (final (width, scale) in [(360.0, 1.3), (360.0, 2.0), (412.0, 2.0)]) {
    testWidgets('$width dp × $scale: đọc to (2 trạng thái) + thẻ gợi ý không tràn', (tester) async {
      await pumpHarness(
        tester,
        ListView(padding: AppSpacing.screenPadding, children: [
          ReadAloudButton(onPressed: () {}),
          const SizedBox(height: AppSpacing.betweenTargets),
          ReadAloudButton(onPressed: () {}, speaking: true),
          const SizedBox(height: AppSpacing.betweenTargets),
          SuggestionCard(
            fromName: 'Nguyễn Thị Mai',
            itemCount: 2,
            previewTitles: const ['Đi bộ quanh công viên với cô Tám', 'Gọi điện cho Mai'],
            onOpen: () {},
            onDismiss: () {},
          ),
        ]),
        width: width,
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
