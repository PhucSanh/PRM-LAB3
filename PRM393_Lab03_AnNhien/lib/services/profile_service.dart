import 'dart:async';
import '../models/app_user.dart';
import '../models/user_profile.dart';
import '../utils/app_error.dart';

/// F1 bootstrap/role; F2 gọi markOnboarded sau khi hoàn tất onboarding.
abstract interface class ProfileService {
  Future<void> ensureProfile(AppUser user);
  Stream<UserProfile> watch(String uid);
  Future<void> setRole(String uid, UserRole role);
  Future<void> markOnboarded(String uid);
}

class FakeProfileService implements ProfileService {
  FakeProfileService([Iterable<UserProfile> seed = const []]) {
    for (final profile in seed) {
      _profiles[profile.uid] = profile;
    }
  }
  final _profiles = <String, UserProfile>{};
  final _changes = StreamController<String>.broadcast(sync: true);
  @override
  Future<void> ensureProfile(AppUser user) async {
    _profiles.putIfAbsent(
        user.uid,
        () => UserProfile(
              uid: user.uid,
              displayName: user.displayName,
              photoUrl: user.photoUrl,
            ));
  }

  @override
  Stream<UserProfile> watch(String uid) => Stream<UserProfile>.multi((sink) {
        final subscription =
            _changes.stream.where((id) => id == uid).listen((_) {
          final profile = _profiles[uid];
          if (profile != null) sink.add(profile);
        });
        final profile = _profiles[uid];
        if (profile != null) sink.add(profile);
        sink.onCancel = subscription.cancel;
      });
  @override
  Future<void> setRole(String uid, UserRole role) async {
    final profile = _profiles[uid];
    if (profile == null) throw const AppException('Chưa tải được tài khoản.');
    if (profile.role != null && profile.role != role) {
      throw const AppException('Tài khoản đã chọn vai trò.');
    }
    _profiles[uid] = profile.copyWith(role: role);
    _changes.add(uid);
  }

  @override
  Future<void> markOnboarded(String uid) async {
    final profile = _profiles[uid];
    if (profile == null || profile.role != UserRole.elder) {
      throw const AppException('Bác cần chọn vai trò trước.');
    }
    _profiles[uid] = profile.copyWith(onboarded: true);
    _changes.add(uid);
  }

  Future<void> dispose() => _changes.close();
}
