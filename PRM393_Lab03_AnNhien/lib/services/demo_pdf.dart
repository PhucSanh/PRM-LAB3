import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// A real, explicitly labelled test file. Does not invent an F7 weekly schedule.
Future<Uint8List> renderDemoPdf(DateTime _) async {
  final font =
      pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
  final document = pw.Document();
  document.addPage(pw.Page(
      build: (_) => pw.Column(children: [
            pw.Text('An Nhiên — Tệp thử', style: pw.TextStyle(font: font)),
            pw.Text(
                'Tệp này dùng để thử tải lên. Đây không phải lịch sinh hoạt.',
                style: pw.TextStyle(font: font)),
          ])));
  return document.save();
}
