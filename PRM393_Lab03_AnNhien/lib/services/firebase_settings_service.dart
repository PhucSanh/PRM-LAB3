import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_settings.dart';
import '../theme/display_settings.dart';
import '../utils/app_error.dart';
import 'firebase_repositories.dart';
import 'settings_service.dart';
import 'profile_setup_service.dart';

class FirebaseSettingsService implements SettingsService {
  FirebaseSettingsService(this.data);
  final FirebaseUserData data;
  DocumentReference<Map<String, dynamic>> get _doc =>
      data.collection('tasks').parent!;
  @override
  Stream<AppSettings> watch() async* {
    try {
      await for (final doc in _doc.snapshots()) {
        yield AppSettings.fromMap(doc.data() ?? {});
      }
    } catch (e) {
      throw AppException('Chưa tải được cài đặt. Bác thử lại nhé.', cause: e);
    }
  }

  Future<void> _save(String key, Object value) =>
      data.run(() => _doc.set({key: value}, SetOptions(merge: true)));
  @override
  Future<void> setFontScale(AppFontScale scale) =>
      _save('fontScale', scale.factor);
  @override
  Future<void> setHighContrast(bool enabled) => _save('highContrast', enabled);
  @override
  Future<void> setReadAloud(bool enabled) => _save('readAloud', enabled);
  @override
  Future<void> setVibrate(bool enabled) => _save('vibrate', enabled);
}

/// Giữ nguyên interface F2 để không buộc ViewModel của Hương đổi contract.
class FirebaseProfileSetupService implements ProfileSetupService {
  FirebaseProfileSetupService(this.data);
  final FirebaseUserData data;
  @override
  Future<void> saveSetup(String uid, ProfileSetup setup) => data.run(() async {
        if (data.auth.currentUser?.uid != uid) {
          throw const AppException('Phiên đăng nhập đã thay đổi.');
        }
        if (setup.displayName.trim().isEmpty ||
            setup.displayName.length > 80 ||
            setup.wakeHour < 0 ||
            setup.wakeHour > 23 ||
            setup.wakeMinute < 0 ||
            setup.wakeMinute > 59) {
          throw const AppException('Bác kiểm tra lại tên và giờ thức dậy nhé.');
        }
        await data.db
            .collection('users')
            .doc(uid)
            .set(setup.toMap(), SetOptions(merge: true));
      });
}
