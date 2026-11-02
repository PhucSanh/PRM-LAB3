import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_notification.dart';
import '../models/notification_target.dart';
import '../utils/app_error.dart';
import 'messaging_service.dart';

/// Inbox is written by a trusted sender before pushing, so unopened/background
/// messages survive process death without granting client write access.
class FirebaseMessagingService implements MessagingService {
  FirebaseMessagingService(this.sdk, this.db, this.auth);
  final FirebaseMessaging sdk;
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final _received = StreamController<AppNotification>.broadcast();
  final _opened = StreamController<AppNotification>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  AppNotification? _pending;
  bool _disposed = false;
  bool _initialized = false;
  bool _closing = false;
  String? _token;

  AppNotification _map(RemoteMessage m) => AppNotification(
        id: m.data['notification_id'] ?? m.messageId ?? '',
        title: m.notification?.title ?? m.data['title'] ?? 'Thông báo mới',
        body: m.notification?.body ?? m.data['body'] ?? '',
        receivedAt: m.sentTime ?? DateTime.now(),
        route: notificationTarget(m.data['route']),
      );

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _subscriptions.add(FirebaseMessaging.onMessage.listen((message) {
      if (!_disposed &&
          message.data['recipient_uid'] == auth.currentUser?.uid) {
        _received.add(_map(message));
      }
    }));
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((m) {
      if (!_disposed && m.data['recipient_uid'] == auth.currentUser?.uid) {
        final item = _map(m);
        if (_opened.hasListener) {
          _opened.add(item);
        } else {
          _pending = item;
        }
      }
    }));
    final initial = await sdk.getInitialMessage();
    if (initial != null &&
        !_disposed &&
        initial.data['recipient_uid'] == auth.currentUser?.uid) {
      _pending = _map(initial);
    }
    // Legacy token transport is retained for the HTTP v1 sender in this repo.
    // ignore: deprecated_member_use
    _subscriptions.add(sdk.onTokenRefresh.listen((token) {
      unawaited(_saveToken(token).catchError((Object _) {}));
    }));
    _subscriptions.add(auth.authStateChanges().listen((user) {
      if (user == null) _pending = null;
      _closing = false;
      if (user != null) unawaited(_syncToken().catchError((Object _) {}));
    }));
  }

  Future<void> _syncToken() async {
    final permission = await sdk.getNotificationSettings();
    if (permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional) {
      final uid = auth.currentUser?.uid;
      // ignore: deprecated_member_use
      final token = await sdk.getToken();
      if (token != null && uid == auth.currentUser?.uid) {
        await _saveToken(token);
      }
    }
  }

  Future<void> _saveToken(String token) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || _disposed || _closing) return;
    _token = token;
    await db.collection('users').doc(uid).collection('devices').doc(token).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': 'android',
    });
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final result = await sdk.requestPermission();
      final allowed =
          result.authorizationStatus == AuthorizationStatus.authorized ||
              result.authorizationStatus == AuthorizationStatus.provisional;
      if (allowed) await _syncToken();
      return allowed;
    } catch (e) {
      throw AppException('Chưa thể bật thông báo. Bác thử lại nhé.', cause: e);
    }
  }

  @override
  Stream<List<AppNotification>> inbox() {
    final uid = auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('receivedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      if (auth.currentUser?.uid != uid) return <AppNotification>[];
      return snapshot.docs.map((doc) {
        final d = doc.data();
        return AppNotification(
            id: doc.id,
            title: d['title'] as String? ?? '',
            body: d['body'] as String? ?? '',
            receivedAt: (d['receivedAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0),
            route: notificationTarget(d['route'] as String?));
      }).toList();
    });
  }

  @override
  Stream<AppNotification> get onReceived => _received.stream;

  @override
  Stream<AppNotification> get onOpened async* {
    final pending = _pending;
    _pending = null;
    if (pending != null) yield pending;
    yield* _opened.stream;
  }

  Future<void> prepareSignOut() async {
    _closing = true;
    _pending = null;
    final uid = auth.currentUser?.uid;
    final token = _token;
    _token = null;
    if (uid == null) return;
    // Invalidate transport even if removing the server registration fails.
    try {
      // ignore: deprecated_member_use
      await sdk.deleteToken().timeout(const Duration(seconds: 10));
    } finally {
      if (token != null) {
        await db
            .collection('users')
            .doc(uid)
            .collection('devices')
            .doc(token)
            .delete()
            .timeout(const Duration(seconds: 10));
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _received.close();
    await _opened.close();
  }
}
