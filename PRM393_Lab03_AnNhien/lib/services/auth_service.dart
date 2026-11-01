import 'dart:async';

import '../models/app_user.dart';

/// Đăng nhập. Bản thật (Firebase Auth + Google Sign-In): B – Hiếu, F1.
abstract interface class AuthService {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  /// Ném [AppException.cancelled] khi Bác bấm huỷ, [AppException.network] khi mất mạng.
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
}

/// Bản giả để C, D code màn khi chưa có Firebase. KHÔNG dùng trong bản nộp.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? signedIn}) : _user = signedIn;

  AppUser? _user;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final user = const AppUser(uid: 'fake-uid', displayName: 'Bác Lan');
    _user = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
