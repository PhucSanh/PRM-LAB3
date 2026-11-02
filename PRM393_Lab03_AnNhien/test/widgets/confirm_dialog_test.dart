import 'package:an_nhien/theme/app_icons.dart';
import 'package:an_nhien/widgets/app_button.dart';
import 'package:an_nhien/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Các hộp thoại trong Figma, câu chữ theo AppStyleGuide.md.
final _dialogs = <String, Future<String?> Function(BuildContext)>{
  'DLG-Done': (c) => showConfirmDialog<String>(
        c,
        icon: AppIcons.checkCircle,
        title: 'Bác đã đi bộ xong rồi chứ?',
        details: const [
          ConfirmDetail(icon: AppIcons.walk, text: 'Đi bộ quanh công viên'),
          ConfirmDetail(icon: AppIcons.clock, text: '9:30 sáng'),
        ],
        options: const [
          ConfirmOption(label: 'Đúng, đã xong', icon: AppIcons.checkCircle, value: 'done', kind: AppButtonKind.primary),
          ConfirmOption(label: 'Chưa, để sau', icon: Icons.circle_outlined, value: 'cancel'),
        ],
      ),
  'DLG-Later': (c) => showConfirmDialog<String>(
        c,
        icon: Icons.alarm_add_outlined,
        title: 'Dời việc này đến lúc nào?',
        details: const [ConfirmDetail(icon: AppIcons.clock, text: 'Đi bộ, đang hẹn 9:30 sáng')],
        options: const [
          ConfirmOption(label: '30 phút nữa', icon: Icons.alarm_add_outlined, value: '30m'),
          ConfirmOption(label: 'Chiều nay, 4 giờ', icon: Icons.alarm_add_outlined, value: '16h'),
          ConfirmOption(label: 'Ngày mai, cùng giờ', icon: Icons.alarm_add_outlined, value: 'tomorrow'),
          ConfirmOption(label: 'Không dời nữa', icon: AppIcons.x, value: 'cancel', kind: AppButtonKind.text),
        ],
      ),
  'DLG-Skip': (c) => showConfirmDialog<String>(
        c,
        icon: Icons.skip_next_outlined,
        title: 'Bỏ qua đi bộ hôm nay?',
        message: 'Mai vẫn nhắc như thường.',
        details: const [ConfirmDetail(icon: Icons.help_outline, text: 'Vì sao vậy Bác?')],
        options: const [
          ConfirmOption(label: 'Trời mưa', icon: Icons.umbrella_outlined, value: 'rain'),
          ConfirmOption(label: 'Thấy mệt', icon: Icons.bed_outlined, value: 'tired'),
          ConfirmOption(label: 'Bận việc nhà', icon: Icons.local_laundry_service_outlined, value: 'busy'),
          ConfirmOption(label: 'Lý do khác', icon: Icons.help_outline, value: 'other'),
          ConfirmOption(label: 'Không bỏ qua nữa', icon: AppIcons.x, value: 'cancel', kind: AppButtonKind.text),
        ],
      ),
  'DLG-Delete': (c) => showConfirmDialog<String>(
        c,
        icon: Icons.delete_outline,
        danger: true,
        title: 'Xóa việc “Đi bộ”?',
        message: 'Chỉ xóa lần này. Ngày khác vẫn giữ.',
        options: const [
          ConfirmOption(label: 'Không xóa, giữ lại', icon: AppIcons.x, value: 'cancel', kind: AppButtonKind.primary),
          ConfirmOption(
              label: 'Xóa khỏi lịch', icon: Icons.delete_outline, value: 'delete', kind: AppButtonKind.dangerOutline),
        ],
      ),
  'N13': (c) => showConfirmDialog<String>(
        c,
        icon: AppIcons.repeat,
        title: 'Thay đổi lần nào?',
        message: 'Đi bộ quanh công viên, mỗi ngày',
        details: const [ConfirmDetail(icon: Icons.info_outline, text: 'Lịch sử được giữ lại')],
        options: const [
          ConfirmOption(label: 'Chỉ lần này', icon: Icons.event_outlined, value: 'once', kind: AppButtonKind.primary),
          ConfirmOption(label: 'Lần này và các lần sau', icon: Icons.date_range_outlined, value: 'series'),
          ConfirmOption(label: 'Giữ nguyên', icon: AppIcons.x, value: 'cancel'),
        ],
      ),
  'N14': (c) => showConfirmDialog<String>(
        c,
        icon: Icons.info_outline,
        title: 'Chưa lưu thay đổi',
        message: 'Nếu rời khỏi đây, phần vừa chỉnh sẽ không được lưu.',
        options: const [
          ConfirmOption(label: 'Tiếp tục chỉnh', icon: AppIcons.pencil, value: 'cancel', kind: AppButtonKind.primary),
          ConfirmOption(label: 'Bỏ thay đổi', icon: Icons.cancel_presentation_outlined, value: 'discard'),
        ],
      ),
};

/// Nút bấm thử và giá trị mong đợi của từng hộp thoại.
const _pick = {
  'DLG-Done': ('Đúng, đã xong', 'done'),
  'DLG-Later': ('Chiều nay, 4 giờ', '16h'),
  'DLG-Skip': ('Không bỏ qua nữa', 'cancel'),
  'DLG-Delete': ('Xóa khỏi lịch', 'delete'),
  'N13': ('Lần này và các lần sau', 'series'),
  'N14': ('Bỏ thay đổi', 'discard'),
};

void main() {
  for (final MapEntry(key: id, value: open) in _dialogs.entries) {
    for (final scale in [1.3, 2.0]) {
      testWidgets('$id · 360 dp ×$scale: vẽ không tràn, bấm trả đúng giá trị', (tester) async {
        String? result = 'chưa đóng';
        await pumpHarness(tester, launcher('Mở', (c) async => result = await open(c)), scale: scale);
        await tester.tap(find.text('Mở'));
        await tester.pumpAndSettle();

        expect(find.byType(ConfirmDialog<String>), findsOneWidget);
        expect(tester.takeException(), isNull);

        final (label, value) = _pick[id]!;
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(result, value);
        expect(find.byType(ConfirmDialog<String>), findsNothing);
      });
    }
  }

  testWidgets('tiêu đề là header cho TalkBack; chạm ra ngoài trả null', (tester) async {
    final semantics = tester.ensureSemantics();
    String? result = 'chưa đóng';
    await pumpHarness(tester, launcher('Mở', (c) async => result = await _dialogs['DLG-Done']!(c)));
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Bác đã đi bộ xong rồi chứ?')),
      matchesSemantics(label: 'Bác đã đi bộ xong rồi chứ?', isHeader: true),
    );

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(result, isNull);
    semantics.dispose();
  });
}
