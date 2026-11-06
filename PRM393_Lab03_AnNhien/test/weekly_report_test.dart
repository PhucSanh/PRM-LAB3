import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_nhien/services/weekly_report_service.dart';
import 'package:an_nhien/services/task_repository.dart';
import 'package:an_nhien/models/task_item.dart';
import 'device_access_flow_test.dart' show TestDevice;

class CapturingDevice extends TestDevice {
  String? name;
  Uint8List? bytes;
  bool cancel = false;
  @override
  Future<String?> savePdf(String name, Uint8List bytes) async {
    this.name = name;
    this.bytes = bytes;
    return cancel ? null : 'content://documents/$name';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('PDF export uses seven actual days, once-only date and selected Monday',
      () async {
    final repository = FakeTaskRepository(const [
      TaskItem(
          id: 'a',
          title: 'Tưới rau và đi bộ cùng gia đình',
          habitKey: 'move',
          hour: 8,
          minute: 15,
          repeat: RepeatRule.once,
          startDate: '2026-11-07',
          status: TaskStatus.done)
    ]);
    final device = CapturingDevice();
    final progress = await WeeklyReportService(repository, device, () => 'uid')
        .exportWeek(DateTime(2026, 11, 8))
        .toList();
    expect(device.name, 'AnNhien-lich-tuan-2026-11-02.pdf');
    expect(String.fromCharCodes(device.bytes!.take(5)), '%PDF-');
    expect(progress.last.downloadUrl, startsWith('content://'));
    device.cancel = true;
    final cancelled = await WeeklyReportService(repository, device, () => 'uid')
        .exportWeek(DateTime(2026, 11, 8))
        .toList();
    expect(cancelled.where((p) => p.downloadUrl != null), isEmpty);
  });
  test('changing account aborts export before opening document picker',
      () async {
    var uid = 'first';
    final device = CapturingDevice();
    final stream =
        WeeklyReportService(FakeTaskRepository([]), device, () => uid)
            .exportWeek(DateTime(2026, 11, 8));
    await expectLater(stream.map((p) {
      uid = 'second';
      return p;
    }),
        emitsInOrder([
          isA<Object>(),
          emitsError(isA<Exception>()),
          emitsDone,
        ]));
    expect(device.bytes, isNull);
  });
  test('render Vietnamese, long task titles and multiple pages for visual QA',
      () async {
    final days = [
      for (var i = 0; i < 7; i++)
        WeeklyReportDay(DateTime(2026, 11, 2 + i), [
          for (var j = 0; j < 12; j++)
            TaskItem(
                id: '$i-$j',
                title:
                    'Đi bộ nhẹ nhàng quanh công viên cùng gia đình và dành thời gian thư giãn mỗi ngày',
                habitKey: 'move',
                hour: 6 + j,
                minute: 15,
                status: j % 2 == 0 ? TaskStatus.done : TaskStatus.pending)
        ])
    ];
    final bytes = await renderWeeklyReport(days);
    final file = File('/tmp/annhien-weekly-report-qa.pdf');
    await file.writeAsBytes(bytes);
    expect(bytes.length, greaterThan(5000));
  });
}
