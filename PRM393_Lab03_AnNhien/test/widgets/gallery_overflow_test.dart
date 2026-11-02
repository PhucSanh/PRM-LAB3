import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:an_nhien/widgets/dev/widget_gallery.dart';
import 'package:an_nhien/widgets/task_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dựng trang xem thử ở khung [size] với `textScaler` [scale], theme theo `highContrastProvider` như `app.dart`.
Future<ProviderContainer> _pumpGallery(WidgetTester tester, Size size, double scale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: Consumer(
      builder: (context, ref, _) => MaterialApp(
        theme: ref.watch(highContrastProvider) ? AppTheme.highContrast() : AppTheme.light(),
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: const WidgetGallery(animate: false),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

/// Cuộn từ đầu tới cuối trang (ListView dựng lười) và fail ngay khi có lỗi tràn ở bất kỳ đoạn nào.
/// Cuộn bằng `jumpTo` để vùng cuộn con (các khung trạng thái) không nuốt thao tác kéo.
Future<void> _scrollThrough(WidgetTester tester) async {
  final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
  for (var i = 0; i < 200; i++) {
    expect(tester.takeException(), isNull, reason: 'tràn ở lần cuộn thứ $i');
    if (position.pixels >= position.maxScrollExtent) break;
    position.jumpTo((position.pixels + 400).clamp(0, position.maxScrollExtent));
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

/// Cuộn trang tới khi mục [label] được dựng rồi đưa vào màn hình.
Future<void> _reveal(WidgetTester tester, String label) async {
  final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
  final finder = find.text(label, skipOffstage: false);
  while (finder.evaluate().isEmpty && position.pixels < position.maxScrollExtent) {
    position.jumpTo((position.pixels + 300).clamp(0, position.maxScrollExtent));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(360, 800), Size(412, 915)]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('${size.width.toInt()}×${size.height.toInt()} · textScaler $scale: cả trang không tràn',
          (tester) async {
        await _pumpGallery(tester, size, scale);
        await _scrollThrough(tester);
        // Đã dựng tới cuối trang.
        expect(find.byType(TaskRow, skipOffstage: false), findsWidgets);
      });
    }
  }

  testWidgets('chip ×2.0 và tương phản cao: trang vẫn không tràn', (tester) async {
    final container = await _pumpGallery(tester, const Size(360, 800), 1);
    await tester.tap(find.text('×$maxTextScale'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tương phản cao'));
    await tester.pumpAndSettle();
    expect(container.read(highContrastProvider), isTrue);
    await _scrollThrough(tester);
  });

  testWidgets('chip cỡ chữ đổi fontScaleProvider', (tester) async {
    final container = await _pumpGallery(tester, const Size(360, 800), 1);
    await tester.tap(find.text('Rất lớn ×1.3'));
    await tester.pumpAndSettle();
    expect(container.read(fontScaleProvider), AppFontScale.ratLon);
  });

  testWidgets('nút mở hộp thoại / snackbar ở 360 × 1.3 không tràn', (tester) async {
    await _pumpGallery(tester, const Size(360, 800), 1.3);
    for (final label in ['Mở hộp Đã xong', 'Mở hộp Xóa việc', 'Mở hộp chọn giờ']) {
      await _reveal(tester, label);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget, reason: label);
      expect(tester.takeException(), isNull, reason: label);
      await tester.tapAt(const Offset(5, 5)); // chạm ngoài để đóng
      await tester.pumpAndSettle();
    }
    await _reveal(tester, 'Hiện Hoàn tác');
    await tester.tap(find.text('Hiện Hoàn tác'));
    await tester.pumpAndSettle();
    expect(find.text('Đã ghi: Đi bộ xong lúc 9:42 sáng.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
