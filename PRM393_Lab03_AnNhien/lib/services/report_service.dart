/// Tạo PDF "Lịch tuần của Bác" và upload lên Storage `reports/{uid}/…`.
/// Bản thật: Hương (F7) tạo PDF, B – Hiếu viết phần upload.
/// Lưu ý Final: bỏ Storage → lưu trên máy + metadata Firestore (giữ interface này).
class UploadProgress {
  const UploadProgress(this.fraction, {this.downloadUrl});
  final double fraction; // 0..1
  final String? downloadUrl; // có khi xong
}

abstract interface class ReportService {
  Stream<UploadProgress> exportWeek(DateTime weekStart);
}

class FakeReportService implements ReportService {
  @override
  Stream<UploadProgress> exportWeek(DateTime weekStart) async* {
    for (final f in [0.25, 0.5, 0.75]) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      yield UploadProgress(f);
    }
    yield const UploadProgress(1,
        downloadUrl: 'https://example.com/fake-report.pdf');
  }
}
