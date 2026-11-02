import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_notification.dart';
import '../utils/app_error.dart';
import 'messaging_service.dart';

/// Session-local inbox; no server credential or client-side push sender.
class FirebaseMessagingService implements MessagingService {
  FirebaseMessagingService(this.sdk);
  final FirebaseMessaging sdk;
  final _items = <AppNotification>[];
  final _inbox = StreamController<List<AppNotification>>.broadcast();
  final _opened = StreamController<AppNotification>.broadcast();
  final _subscriptions = <StreamSubscription<RemoteMessage>>[];
  AppNotification? _initial;
  bool _disposed = false;

  AppNotification _map(RemoteMessage m) => AppNotification(
        id: m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: m.notification?.title ?? '', body: m.notification?.body ?? '',
        receivedAt: m.sentTime ?? DateTime.now(),
        // Navigation is intentionally not inferred from untrusted FCM data.
      );
  void _receive(RemoteMessage message, {bool opened = false}) {
    if (_disposed) return;
    final item = _map(message);
    _items.removeWhere((n) => n.id == item.id);
    _items.insert(0, item);
    if (_items.length > 100) _items.removeLast();
    _inbox.add(List.unmodifiable(_items));
    if (opened) _opened.add(item);
  }

  Future<void> init() async {
    _subscriptions.add(FirebaseMessaging.onMessage.listen(_receive));
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp
        .listen((m) => _receive(m, opened: true)));
    final initial = await sdk.getInitialMessage();
    if (initial != null && !_disposed) {
      _initial = _map(initial);
      _receive(initial);
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final result = await sdk.requestPermission();
      return result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      throw AppException('Chưa thể xin quyền thông báo.', cause: e);
    }
  }

  @override
  Stream<List<AppNotification>> inbox() async* {
    yield List.unmodifiable(_items);
    yield* _inbox.stream;
  }

  @override
  Stream<AppNotification> get onOpened async* {
    final initial = _initial;
    _initial = null;
    if (initial != null) yield initial;
    yield* _opened.stream;
  }

  void clearSession() {
    _items.clear();
    _initial = null;
    if (!_disposed) _inbox.add(const []);
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _inbox.close();
    await _opened.close();
  }
}
