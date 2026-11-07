import 'package:flutter/foundation.dart';

/// Firebase Analytics. Bản thật: B – Hiếu, F10. Tên sự kiện theo docs/analytics-plan.md.
/// KHÔNG gửi tên, e-mail, số điện thoại trong tham số.
abstract interface class AnalyticsService {
  Future<void> logEvent(String name, [Map<String, Object>? params]);
  Future<void> setUserId(String? uid);
}

class FakeAnalyticsService implements AnalyticsService {
  final List<String> logged = [];

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    logged.add(name);
    debugPrint('[analytics] $name ${params ?? {}}');
  }

  @override
  Future<void> setUserId(String? uid) async =>
      debugPrint('[analytics] userId=$uid');
}
