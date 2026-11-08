import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'analytics_service.dart';
import 'crash_service.dart';
import 'remote_config_service.dart';

class FirebaseAnalyticsService
    with WidgetsBindingObserver
    implements AnalyticsService {
  FirebaseAnalyticsService(this.sdk, {FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast1') {
    WidgetsBinding.instance.addObserver(this);
  }
  final FirebaseFunctions _functions;
  String? _uid;
  DateTime? _lastHeartbeat;
  bool _heartbeatPending = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recordActivity());
    }
  }

  Future<void> _recordActivity() async {
    if (_uid == null || _heartbeatPending) return;
    final now = DateTime.now();
    if (_lastHeartbeat != null &&
        now.difference(_lastHeartbeat!) < const Duration(minutes: 1)) {
      return;
    }
    final uid = _uid;
    _heartbeatPending = true;
    try {
      await _functions.httpsCallable('recordAppActivity').call<void>();
      if (_uid == uid) _lastHeartbeat = now;
    } catch (_) {/* Analytics failure must not block app use. */} finally {
      _heartbeatPending = false;
    }
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);
  final FirebaseAnalytics sdk;
  // Telemetry must not turn a successful user action into a UI failure.
  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    try {
      await sdk.logEvent(name: name, parameters: params);
    } catch (_) {/* best effort */}
  }

  @override
  Future<void> setUserId(String? uid) async {
    if (_uid != uid) _lastHeartbeat = null;
    _uid = uid;
    unawaited(_recordActivity());
    try {
      await sdk.setUserId(id: uid);
    } catch (_) {/* best effort */}
  }
}

class FirebaseCrashService implements CrashService {
  FirebaseCrashService(this.sdk);
  final FirebaseCrashlytics sdk;
  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {String? reason}) async {
    try {
      await sdk.recordError(error, stack, reason: reason);
    } catch (_) {/* best effort */}
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    try {
      await sdk.setCustomKey(key, value);
    } catch (_) {/* best effort */}
  }

  @override
  Future<void> setUserId(String uid) async {
    try {
      await sdk.setUserIdentifier(uid);
    } catch (_) {/* best effort */}
  }

  @override
  void testCrash() => sdk.crash();
}

class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService(this.sdk);
  final FirebaseRemoteConfig sdk;
  @override
  Future<void> init() async {
    await sdk.setDefaults({
      RemoteConfigKeys.snoozeMinutes: 10,
      RemoteConfigKeys.voiceInputEnabled: true,
      RemoteConfigKeys.homeMaxUpcoming: 6
    });
    try {
      await sdk.fetchAndActivate();
    } catch (_) {/* retain defaults/cache */}
  }

  @override
  int getInt(String key) => sdk.getInt(key);
  @override
  bool getBool(String key) => sdk.getBool(key);
  @override
  Stream<Set<String>> get onUpdated =>
      sdk.onConfigUpdated.asyncMap((event) async {
        await sdk.activate();
        return event.updatedKeys;
      });
}
