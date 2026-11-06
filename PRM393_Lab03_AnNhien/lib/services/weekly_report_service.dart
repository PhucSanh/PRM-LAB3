import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/task_item.dart';
import '../utils/app_error.dart';
import 'device_access_service.dart';
import 'report_service.dart';
import 'task_repository.dart';

class WeeklyReportDay {
  const WeeklyReportDay(this.date, this.tasks);
  final DateTime date;
  final List<TaskItem> tasks;
}

/// Pure PDF renderer: the caller supplies actual occurrence/status snapshots.
Future<Uint8List> renderWeeklyReport(List<WeeklyReportDay> days) async {
  final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'));
  final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/BeVietnamPro-SemiBold.ttf'));
  final document = pw.Document();
  final pine = PdfColor.fromHex('#234437');
  String date(DateTime d) => '${d.day}/${d.month}/${d.year}';
  final monday = days.first.date;
  pw.Widget taskRow(TaskItem task) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      child: pw.Text(
          '${task.hour.toString().padLeft(2, '0')}:${task.minute.toString().padLeft(2, '0')}  ${task.title}\n${task.durationMinutes} phút - ${switch (task.status) {
            TaskStatus.done => 'Đã xong',
            TaskStatus.skipped => 'Đã bỏ qua',
            TaskStatus.postponed => 'Đã dời',
            _ => 'Chưa làm'
          }}',
          style: const pw.TextStyle(fontSize: 14, lineSpacing: 4)));
  document.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 16),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('An Nhiên - Lịch tuần của Bác',
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: pine)),
              pw.SizedBox(height: 6),
              pw.Text('${date(monday)} - ${date(days.last.date)}',
                  style: const pw.TextStyle(fontSize: 14)),
            ])),
    footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Trang ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 11))),
    build: (_) => [
      pw.Text(
          'Lịch và trạng thái tại thời điểm xuất. Thay đổi sau đó không cập nhật vào tệp này.',
          style: const pw.TextStyle(fontSize: 12)),
      pw.SizedBox(height: 16),
      for (final day in days) ...[
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              color: PdfColor.fromHex('#E3E9DE'),
              child: pw.Text(
                  '${[
                    'Thứ Hai',
                    'Thứ Ba',
                    'Thứ Tư',
                    'Thứ Năm',
                    'Thứ Sáu',
                    'Thứ Bảy',
                    'Chủ Nhật'
                  ][day.date.weekday - 1]} - ${date(day.date)}',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: pine))),
          if (day.tasks.isEmpty)
            pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text('Chưa có việc.',
                    style: const pw.TextStyle(fontSize: 13))),
          if (day.tasks.isNotEmpty) taskRow(day.tasks.first),
        ]),
        for (final task in day.tasks.skip(1)) taskRow(task),
        pw.SizedBox(height: 12),
      ],
    ],
  ));
  return document.save();
}

/// Uses Android's document picker; no Storage plan or external-file permission.
class WeeklyReportService implements ReportService {
  WeeklyReportService(this.tasks, this.device, this.currentUid);
  final TaskRepository tasks;
  final DeviceAccessService device;
  final String? Function() currentUid;
  @override
  Stream<UploadProgress> exportWeek(DateTime weekStart) async* {
    final uid = currentUid();
    if (uid == null) throw const AppException('Bác cần đăng nhập trước.');
    final day = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    final days = <WeeklyReportDay>[];
    for (var i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final items = [...await tasks.tasksForDay(date)];
      items.sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      days.add(WeeklyReportDay(date, items));
      if (currentUid() != uid) {
        throw const AppException('Tài khoản đã thay đổi. Bác mở lại lịch nhé.');
      }
      yield UploadProgress((i + 1) / 10);
    }
    final bytes = await renderWeeklyReport(days);
    if (currentUid() != uid) throw const AppException('Tài khoản đã thay đổi.');
    yield const UploadProgress(0.9);
    final uri =
        await device.savePdf('AnNhien-lich-tuan-${dateKey(monday)}.pdf', bytes);
    if (currentUid() != uid) throw const AppException('Tài khoản đã thay đổi.');
    if (uri != null) yield UploadProgress(1, downloadUrl: uri);
  }
}
