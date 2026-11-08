import 'package:an_nhien/models/task_item.dart';
import 'package:an_nhien/widgets/velora_home_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/demo_container.dart';

void main() {
  testWidgets('speaker shares task row without a separate header',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = demoContainer();
    var opened = false;
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: Scaffold(
                body: VeloraScheduleCard(
                    task: const TaskItem(
                        id: 'test',
                        title: 'Chăm cây',
                        habitKey: 'plant',
                        hour: 16,
                        minute: 30,
                        startDate: '2026-11-08'),
                    onTap: () => opened = true)))));
    await tester.pumpAndSettle();
    final title = tester.getRect(find.text('Chăm cây'));
    final speaker = tester.getRect(find.byTooltip('Đọc khung này'));
    expect(speaker.top, lessThan(title.bottom));
    expect(
        tester.getSize(find.byType(VeloraScheduleCard)).height, lessThan(130));
    await tester.tap(find.text('Chăm cây'));
    expect(opened, true);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
