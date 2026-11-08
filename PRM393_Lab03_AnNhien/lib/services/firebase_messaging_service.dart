import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_notification.dart';
import '../models/notification_target.dart';
import '../utils/app_error.dart';
import 'messaging_service.dart';

/// Inbox is written by a trusted sender before pushing, so unopened/background
/// messages survive process death without granting client write access.
class FirebaseMessagingService
    with WidgetsBindingObserver
    implements MessagingService {
  FirebaseMessagingService(this.sdk, this.db, this.auth, {this.showForeground});
  final Future<void> Function(AppNotification item, String uid)? showForeground;
  final FirebaseMessaging sdk;
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final _received = StreamController<AppNotification>.broadcast();
  final _opened = StreamController<AppNotification>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  AppNotification? _pending;
  String? _pendingUid;
  RemoteMessage? _deferredLaunch;
  bool _disposed = false;
  bool _initialized = false;
  bool _closing = false;
  String? _token;

  AppNotification _map(RemoteMessage m) => AppNotification(
        id: m.data['notification_id'] ?? m.messageId ?? '',
        title: m.notification?.title ?? m.data['title'] ?? 'Thông báo mới',
        body: m.notification?.body ?? m.data['body'] ?? '',
        receivedAt: m.sentTime ?? DateTime.now(),
        route: firebaseNotificationTarget(m.data['route']),
        parentUid: m.data['parent_uid'],
        kind: NotificationKind.values.asNameMap()[m.data['kind']] ??
            NotificationKind.system,
      );

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _subscriptions.add(FirebaseMessaging.onMessage.listen((message) {
      if (!_disposed &&
          message.data['recipient_uid'] == auth.currentUser?.uid) {
        final item = _map(message);
        _received.add(item);
        final uid = auth.currentUser?.uid;
        if (uid != null && showForeground != null) {
          unawaited(showForeground!(item, uid).catchError((Object _) {}));
        }
      }
    }));
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((m) {
      if (!_disposed && m.data['recipient_uid'] == auth.currentUser?.uid) {
        final item = _map(m);
        unawaited(markRead(item.id).catchError((Object _) {}));
        if (_opened.hasListener) {
          _opened.add(item);
        } else {
          _pending = item;
          _pendingUid = m.data['recipient_uid'];
        }
      }
    }));
    final initial = await sdk.getInitialMessage();
    if (initial != null && !_disposed) {
      if (auth.currentUser == null) {
        _deferredLaunch = initial;
      } else if (initial.data['recipient_uid'] == auth.currentUser?.uid) {
        _pending = _map(initial);
        _pendingUid = initial.data['recipient_uid'];
      }
    }
    // Legacy token transport is retained for the HTTP v1 sender in this repo.
    // ignore: deprecated_member_use
    _subscriptions.add(sdk.onTokenRefresh.listen((token) {
      unawaited(_saveToken(token).catchError((Object _) {}));
    }));
    _subscriptions.add(auth.authStateChanges().listen((user) {
      if (_pendingUid != user?.uid) _pending = null;
      if (user != null && _deferredLaunch != null) {
        final launch = _deferredLaunch!;
        _deferredLaunch = null;
        if (launch.data['recipient_uid'] == user.uid) {
          final item = _map(launch);
          if (_opened.hasListener) {
            _opened.add(item);
          } else {
            _pending = item;
            _pendingUid = user.uid;
          }
        }
      }
      _closing = false;
      if (user != null) unawaited(_syncToken().catchError((Object _) {}));
    }));
  }

  Future<void> syncRegistration() => _syncToken();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_disposed) {
      unawaited(_syncToken().catchError((Object _) {}));
    }
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
      if (allowed) {
        try {
          await _syncToken().timeout(const Duration(seconds: 3));
        } catch (_) {
          // Network registration retries on resume; OS permission is still granted.
        }
      }
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
            parentUid: d['parentUid'] as String?,
            kind: NotificationKind.values.asNameMap()[d['kind']] ??
                NotificationKind.system,
            readAt: (d['readAt'] as Timestamp?)?.toDate(),
            title: d['title'] as String? ?? '',
            body: d['body'] as String? ?? '',
            receivedAt: (d['receivedAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0),
            route: firebaseNotificationTarget(d['route'] as String?));
      }).toList();
    });
  }

  @override
  Future<void> markRead(String id) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || id.isEmpty || id.contains('/')) return;
    await db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .update({'readAt': FieldValue.serverTimestamp()});
  }

  @override
  Stream<AppNotification> get onReceived => _received.stream;

  @override
  Stream<AppNotification> get onOpened async* {
    final pending = _pending;
    _pending = null;
    if (pending != null && _pendingUid == auth.currentUser?.uid) {
      unawaited(markRead(pending.id).catchError((Object _) {}));
      yield pending;
    }
    yield* _opened.stream;
  }

  Future<void> prepareSignOut() async {
    _closing = true;
    _pending = null;
    _pendingUid = null;
    _deferredLaunch = null;
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
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _received.close();
    await _opened.close();
  }
}
