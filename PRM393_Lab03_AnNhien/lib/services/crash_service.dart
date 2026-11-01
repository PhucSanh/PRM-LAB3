import 'package:flutter/foundation.dart';

/// Firebase Crashlytics. Bản thật: B – Hiếu, F10.
abstract interface class CrashService {
  Future<void> recordError(Object error, StackTrace? stack, {String? reason});
  Future<void> setCustomKey(String key, Object value);
  Future<void> setUserId(String uid);
  void testCrash();
}

class FakeCrashService implements CrashService {
  @override
  Future<void> recordError(Object error, StackTrace? stack, {String? reason}) async =>
      debugPrint('[crash] non-fatal: $error ($reason)');

  @override
  Future<void> setCustomKey(String key, Object value) async => debugPrint('[crash] $key=$value');

  @override
  Future<void> setUserId(String uid) async {}

  @override
  void testCrash() => throw StateError('Test crash (bản giả)');
}
