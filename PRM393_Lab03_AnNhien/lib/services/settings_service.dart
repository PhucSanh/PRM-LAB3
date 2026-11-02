import 'dart:async';

import '../models/app_settings.dart';
import '../theme/display_settings.dart';
import '../utils/app_error.dart';

/// Cài đặt của Bác (F2 S01, F8 S10, F6 N07). Bản thật (Firestore `users/{uid}`
/// + cache máy): B – Hiếu.
abstract interface class SettingsService {
  Stream<AppSettings> watch();
  Future<void> setFontScale(AppFontScale scale);
  Future<void> setHighContrast(bool enabled);
  Future<void> setReadAloud(bool enabled);
  Future<void> setVibrate(bool enabled);
}

/// Giữ trong bộ nhớ. `failOnSave: true` để test nhánh lưu lỗi.
class FakeSettingsService implements SettingsService {
  FakeSettingsService({
    AppSettings initial = const AppSettings(),
    this.failOnSave = false,
    this.delay = const Duration(milliseconds: 200),
  }) : _settings = initial;

  final bool failOnSave;
  final Duration delay;
  AppSettings _settings;
  final _changes = StreamController<AppSettings>.broadcast(sync: true);

  AppSettings get current => _settings;

  /// Phát giá trị hiện tại rồi mọi thay đổi sau đó (cùng kiểu
  /// `FakeAuthService.authStateChanges`; chạy được cả trong `testWidgets`).
  @override
  Stream<AppSettings> watch() async* {
    yield _settings;
    yield* _changes.stream;
  }

  Future<void> _update(AppSettings next) async {
    await Future<void>.delayed(delay);
    if (failOnSave) {
      throw const AppException('Chưa lưu được cài đặt. Bác thử lại nhé.');
    }
    _settings = next;
    _changes.add(next);
  }

  @override
  Future<void> setFontScale(AppFontScale scale) =>
      _update(_settings.copyWith(fontScale: scale));

  @override
  Future<void> setHighContrast(bool enabled) =>
      _update(_settings.copyWith(highContrast: enabled));

  @override
  Future<void> setReadAloud(bool enabled) =>
      _update(_settings.copyWith(readAloud: enabled));

  @override
  Future<void> setVibrate(bool enabled) =>
      _update(_settings.copyWith(vibrate: enabled));

  Future<void> dispose() => _changes.close();
}
