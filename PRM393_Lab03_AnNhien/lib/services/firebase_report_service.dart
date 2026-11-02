import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/app_error.dart';
import 'report_service.dart';

/// PDF generation stays with F7. Supply its approved renderer when available.
class FirebaseReportService implements ReportService {
  FirebaseReportService(this.auth, this.storage, {this.renderPdf});
  final FirebaseAuth auth;
  final FirebaseStorage storage;
  final Future<Uint8List> Function(DateTime)? renderPdf;
  @override
  Stream<UploadProgress> exportWeek(DateTime weekStart) async* {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw const AppException('Bác cần đăng nhập trước.');
    final render = renderPdf;
    if (render == null) {
      throw const AppException('Chức năng tạo PDF đang chờ tích hợp F7.');
    }
    try {
      final bytes = await render(weekStart);
      if (bytes.length >= 5 * 1024 * 1024) {
        throw const AppException('PDF phải nhỏ hơn 5 MB.');
      }
      if (auth.currentUser?.uid != uid) {
        throw const AppException('Phiên đăng nhập đã thay đổi.');
      }
      final reference = storage
          .ref('reports/$uid/${DateTime.now().microsecondsSinceEpoch}.pdf');
      final upload = reference.putData(
          bytes, SettableMetadata(contentType: 'application/pdf'));
      await for (final snapshot in upload.snapshotEvents) {
        if (snapshot.totalBytes > 0) {
          yield UploadProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      }
      await upload;
      // A real URL is returned only after a successful upload.
      yield UploadProgress(1, downloadUrl: await reference.getDownloadURL());
    } on FirebaseException catch (e) {
      throw AppException('Chưa thể tải PDF lên. Bác thử lại nhé.', cause: e);
    }
  }
}
