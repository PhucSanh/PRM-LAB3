import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dựng [child] trong `Scaffold` với theme thật, khung [width] × 800 dp và `textScaler` [scale].
/// Mặc định 360 dp + 1.3 (cỡ "Rất lớn") theo CLAUDE.md. [settle] = false khi có vòng xoay chạy mãi.
Future<void> pumpHarness(
  WidgetTester tester,
  Widget child, {
  double width = 360,
  double scale = 1.3,
  PreferredSizeWidget? appBar,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    builder: (context, c) =>
        MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: c!),
    home: Scaffold(appBar: appBar, body: child),
  ));
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

/// Dựng một nút mở được hộp thoại / snackbar: bấm [label] để gọi [onTap] với `BuildContext` nằm dưới Scaffold.
Widget launcher(String label, void Function(BuildContext context) onTap) =>
    Builder(builder: (context) => Center(child: TextButton(onPressed: () => onTap(context), child: Text(label))));
