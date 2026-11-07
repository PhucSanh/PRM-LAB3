import 'package:an_nhien/widgets/read_aloud_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'device_access_flow_test.dart' show TestDevice;
import 'support/demo_container.dart';

void main() {
  testWidgets('speaker reads only its own block with the latest input',
      (tester) async {
    final device = TestDevice();
    final container = demoContainer(device: device);
    final text = TextEditingController(text: 'Tên đang nhập');
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: Scaffold(
                body: Column(children: [
          ReadAloudRegion(
              child: Column(children: [
            const Text('Tên người thân'),
            TextField(controller: text)
          ])),
          const ReadAloudRegion(child: Text('Khung khác không được đọc')),
        ])))));
    await tester.pumpAndSettle();
    text.text = 'Tên mới';
    await tester.tap(find.byTooltip('Đọc khung này').first);
    await tester.pumpAndSettle();
    expect(device.spoken, contains('Tên người thân'));
    expect(device.spoken, contains('Tên mới'));
    expect(device.spoken, isNot(contains('Khung khác')));
    await tester.tap(find.byTooltip('Đọc khung này').last);
    await tester.pumpAndSettle();
    expect(device.spoken, 'Khung khác không được đọc');
    await tester.pumpWidget(const SizedBox.shrink());
    text.dispose();
    container.dispose();
  });
}
