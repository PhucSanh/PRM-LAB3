import 'package:an_nhien/screens/tasks/task_form_screens.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets('S05 hiển thị ở ${width.toInt()}dp', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
              theme: AppTheme.light(), home: const ActivitySelectionScreen())));
      await tester.pump();

      expect(find.text('Bác muốn làm gì?'), findsOneWidget);
      expect(find.text('Đi bộ nhẹ nhàng'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ST-Saved cuộn được ở màn hình 360dp thấp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            theme: AppTheme.light(), home: const TaskSavedScreen())));
    await tester.pumpAndSettle();

    expect(find.text('Đã lưu xong!'), findsOneWidget);
    expect(find.text('Về trang Hôm nay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
