import 'package:an_nhien/widgets/app_button.dart';
import 'package:an_nhien/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  for (final width in [360.0, 412.0]) {
    for (final scale in [1.3, 2.0]) {
      final tag = '$width dp ×$scale';

      testWidgets('LoadingView · $tag', (tester) async {
        await pumpHarness(
          tester,
          const LoadingView(
              message: 'Đang lưu việc…', hint: 'Không cần bấm gì thêm'),
          width: width,
          scale: scale,
          settle: false,
        );
        expect(find.text('Đang lưu việc…'), findsOneWidget);
        expect(find.text('Không cần bấm gì thêm'), findsOneWidget);
        expect(find.byType(AppButton), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('EmptyView · $tag: nút chính + nút phụ', (tester) async {
        var primary = 0, secondary = 0;
        await pumpHarness(
          tester,
          EmptyView(
            icon: Icons.wb_sunny_rounded,
            title: 'Hôm nay chưa có việc nào',
            message: 'Bắt đầu nhẹ nhàng với một việc nhỏ.',
            action: AppButton(
                label: 'Thêm việc đầu tiên',
                icon: Icons.add_rounded,
                onPressed: () => primary++),
            secondaryAction: AppButton(
              label: 'Dùng lịch mẫu',
              icon: Icons.view_list_rounded,
              kind: AppButtonKind.secondary,
              onPressed: () => secondary++,
            ),
          ),
          width: width,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Dùng lịch mẫu'));
        await tester.tap(find.text('Dùng lịch mẫu'));
        await tester.ensureVisible(find.text('Thêm việc đầu tiên'));
        await tester.tap(find.text('Thêm việc đầu tiên'));
        expect((primary, secondary), (1, 1));
      });

      testWidgets('ErrorView · $tag: luôn có Thử lại + nút phụ',
          (tester) async {
        var retries = 0, back = 0;
        await pumpHarness(
          tester,
          ErrorView(
            title: 'Chưa lưu được',
            message: 'Chưa thể lưu trên điện thoại.',
            detail: 'Nội dung đang nhập vẫn được giữ lại.',
            onRetry: () => retries++,
            extraActions: [
              AppButton(
                  label: 'Quay lại sửa',
                  icon: Icons.edit_rounded,
                  kind: AppButtonKind.secondary,
                  onPressed: () => back++),
            ],
          ),
          width: width,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Thử lại'));
        await tester.tap(find.text('Thử lại'));
        await tester.ensureVisible(find.text('Quay lại sửa'));
        await tester.tap(find.text('Quay lại sửa'));
        expect((retries, back), (1, 1));
      });
    }
  }

  testWidgets('ErrorView báo lỗi cho TalkBack bằng liveRegion', (tester) async {
    await pumpHarness(
        tester, ErrorView(message: 'Mất mạng rồi Bác ơi.', onRetry: () {}));
    final liveRegion = find.ancestor(
      of: find.text('Mất mạng rồi Bác ơi.'),
      matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true),
    );
    expect(liveRegion, findsOneWidget);
  });
}
