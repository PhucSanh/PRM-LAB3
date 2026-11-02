import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_error.dart';

abstract interface class SessionDataService {
  Future<void> clearLocalData();
}

class FakeSessionDataService implements SessionDataService {
  int clearCount = 0;
  @override
  Future<void> clearLocalData() async {
    clearCount++;
  }
}

/// Android FlutterFire recreates its native Firestore instance after terminate.
/// Call only while the session gate has detached user-bound listeners.
class FirebaseSessionDataService implements SessionDataService {
  FirebaseSessionDataService(this.db);
  final FirebaseFirestore db;
  @override
  Future<void> clearLocalData() async {
    try {
      await db.terminate();
      await db.clearPersistence();
    } catch (error) {
      throw AppException('Chưa xoá được dữ liệu trên máy. Bác thử lại nhé.',
          cause: error);
    }
  }
}
