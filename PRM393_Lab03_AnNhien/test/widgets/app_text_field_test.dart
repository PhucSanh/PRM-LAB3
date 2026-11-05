import 'package:an_nhien/theme/app_spacing.dart';
import 'package:an_nhien/theme/app_icons.dart';
import 'package:an_nhien/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Màn thử: ô "Tên việc", bấm "Kiểm tra" khi ô trống thì hiện lỗi (giống S06e / ST-Validation).
class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: AppSpacing.screenPadding, children: [
      AppTextField(
        label: 'Tên việc',
        hint: 'Đi bộ buổi sáng',
        controller: _controller,
        errorText: _error,
        icon: Icons.edit_rounded,
        onChanged: (_) => setState(() => _error = null),
      ),
      TextButton(
        onPressed: () => setState(() => _error =
            _controller.text.trim().isEmpty ? 'Bác chưa nhập tên việc.' : null),
        child: const Text('Kiểm tra'),
      ),
    ]);
  }
}

void main() {
  group('AppTextField', () {
    testWidgets('nhãn trên ô, gợi ý tự thêm "Ví dụ: ", ô cao ≥ 72',
        (tester) async {
      await pumpHarness(tester, const _Form());
      expect(find.text('Tên việc'), findsOneWidget);
      expect(find.text('Ví dụ: Đi bộ buổi sáng'), findsOneWidget);
      expect(tester.getSize(find.byType(TextField)).height,
          greaterThanOrEqualTo(AppSizes.minTarget));
      expect(tester.getTopLeft(find.text('Tên việc')).dy,
          lessThan(tester.getTopLeft(find.byType(TextField)).dy));
    });

    testWidgets('không lặp "Ví dụ" khi gợi ý đã có sẵn', (tester) async {
      await pumpHarness(
          tester,
          const AppTextField(
              label: 'Số điện thoại', hint: 'Ví dụ: 0912 345 678'));
      expect(find.text('Ví dụ: 0912 345 678'), findsOneWidget);
    });

    testWidgets(
        'nhập lỗi → hiện errorText có icon, liveRegion; gõ lại thì hết lỗi',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHarness(tester, const _Form());
      await tester.tap(find.text('Kiểm tra'));
      await tester.pumpAndSettle();

      expect(find.text('Bác chưa nhập tên việc.'), findsOneWidget);
      expect(find.byIcon(AppIcons.alert), findsOneWidget);
      expect(find.text('Ví dụ: Đi bộ buổi sáng'), findsOneWidget);
      // TalkBack gộp nhãn + lỗi + gợi ý vào node của ô; node đó là liveRegion nên lỗi được đọc ngay.
      final node = tester.getSemantics(find.text('Bác chưa nhập tên việc.'));
      expect(node, isSemantics(isLiveRegion: true));
      expect(node.label, contains('Bác chưa nhập tên việc.'));

      await tester.enterText(find.byType(TextField), 'Tập thở');
      await tester.pumpAndSettle();
      expect(find.text('Bác chưa nhập tên việc.'), findsNothing);
      semantics.dispose();
    });

    for (final (width, scale) in [(360.0, 1.3), (360.0, 2.0), (412.0, 2.0)]) {
      testWidgets('$width dp × $scale: có lỗi + gợi ý không tràn',
          (tester) async {
        await pumpHarness(
          tester,
          ListView(padding: AppSpacing.screenPadding, children: const [
            AppTextField(
              label: 'Số điện thoại người thân (không bắt buộc)',
              hint: '0912 345 678',
              errorText:
                  'Bác chưa nhập số điện thoại. Bấm “Chọn từ danh bạ” ở trên cho nhanh.',
              keyboardType: TextInputType.phone,
            ),
          ]),
          width: width,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
