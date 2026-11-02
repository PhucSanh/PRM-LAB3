import '../utils/app_error.dart';

/// Lưu hồ sơ S02 (F2). TẠM: `ProfileService` của Hiếu chưa có hàm lưu tên /
/// cách gọi / giờ thức dậy. TODO(Hiếu): gộp `saveSetup` vào `ProfileService`
/// (+ bản Firebase, thêm `honorific`, `wakeTime` vào `UserProfile`) rồi xoá file này.

/// Cách gọi Bác chọn ở S02 (Figma `1:103` chỉ có Ông / Bà).
/// Firestore `users/{uid}.honorific` lưu khoá `ong` / `ba`.
enum Honorific {
  ong('Ông'),
  ba('Bà');

  const Honorific(this.label);
  final String label;
}

/// Dữ liệu S02 ghi vào `users/{uid}`.
class ProfileSetup {
  const ProfileSetup({
    required this.displayName,
    required this.honorific,
    required this.wakeHour,
    required this.wakeMinute,
  });

  final String displayName;
  final Honorific honorific;
  final int wakeHour;
  final int wakeMinute;

  /// `wakeTime` dạng "HH:mm" (24 giờ).
  Map<String, Object?> toMap() => {
        'displayName': displayName,
        'honorific': honorific.name,
        'wakeTime': '${wakeHour.toString().padLeft(2, '0')}:'
            '${wakeMinute.toString().padLeft(2, '0')}',
      };
}

abstract interface class ProfileSetupService {
  Future<void> saveSetup(String uid, ProfileSetup setup);
}

/// Giữ trong bộ nhớ. `failOnSave: true` để test nhánh lưu lỗi.
class FakeProfileSetupService implements ProfileSetupService {
  FakeProfileSetupService({
    this.failOnSave = false,
    this.delay = const Duration(milliseconds: 200),
  });

  bool failOnSave;
  final Duration delay;
  final saved = <String, ProfileSetup>{};

  @override
  Future<void> saveSetup(String uid, ProfileSetup setup) async {
    await Future<void>.delayed(delay);
    if (failOnSave) {
      throw const AppException(
          'Chưa lưu được. Bác kiểm tra mạng rồi thử lại nhé.');
    }
    saved[uid] = setup;
  }
}
