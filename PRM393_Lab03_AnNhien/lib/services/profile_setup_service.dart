import 'dart:async';

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

  /// F8 N06 thêm: hồ sơ đã lưu (giá trị hiện tại rồi mọi thay đổi); `null` khi
  /// Bác chưa lưu lần nào. TODO(Hiếu): bản Firebase đọc `users/{uid}`
  /// (`displayName`, `honorific`, `wakeTime` "HH:mm").
  Stream<ProfileSetup?> watchSetup(String uid);
}

/// Giữ trong bộ nhớ. `failOnSave: true` để test nhánh lưu lỗi.
class FakeProfileSetupService implements ProfileSetupService {
  FakeProfileSetupService({
    this.failOnSave = false,
    this.delay = const Duration(milliseconds: 200),
    Map<String, ProfileSetup> seed = const {},
  }) {
    saved.addAll(seed);
  }

  bool failOnSave;
  final Duration delay;
  final saved = <String, ProfileSetup>{};
  final _changes = StreamController<String>.broadcast(sync: true);

  @override
  Stream<ProfileSetup?> watchSetup(String uid) =>
      // Phát ngay khi có người nghe, rồi mọi lần lưu sau đó. `onCancel` không
      // trả Future: Future huỷ của broadcast stream nằm ở root zone, `.first`
      // chờ nó nên treo trong `testWidgets` (thời gian giả).
      Stream<ProfileSetup?>.multi((sink) {
        final subscription = _changes.stream
            .where((id) => id == uid)
            .listen((_) => sink.add(saved[uid]));
        sink.add(saved[uid]);
        sink.onCancel = () {
          subscription.cancel();
        };
      });

  @override
  Future<void> saveSetup(String uid, ProfileSetup setup) async {
    await Future<void>.delayed(delay);
    if (failOnSave) {
      throw const AppException(
          'Chưa lưu được. Bác kiểm tra mạng rồi thử lại nhé.');
    }
    saved[uid] = setup;
    _changes.add(uid);
  }

  Future<void> dispose() => _changes.close();
}
