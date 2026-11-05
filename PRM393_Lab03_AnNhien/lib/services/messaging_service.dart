import 'dart:async';
import '../models/app_notification.dart';

/// Firebase Cloud Messaging + danh sách thông báo đã nhận. Bản thật: B – Hiếu, F10.
abstract interface class MessagingService {
  /// Xin quyền POST_NOTIFICATIONS (Android 13+). Trả về false nếu Bác từ chối.
  Future<bool> requestPermission();
  Stream<List<AppNotification>> inbox();
  Future<void> markRead(String id);
  Stream<AppNotification> get onReceived;

  /// Thông báo Bác vừa bấm (app ở nền hoặc đã tắt) – router mở `route`.
  Stream<AppNotification> get onOpened;
}

class FakeMessagingService implements MessagingService {
  FakeMessagingService({List<AppNotification>? seed})
      : _items = seed ??
            [
              AppNotification(
                  id: 'n1',
                  title: 'Đến giờ đi bộ',
                  body: '9:30 sáng',
                  receivedAt: DateTime(2026, 11, 2, 9, 30),
                  route: '/reminder/t3',
                  kind: NotificationKind.reminder),
            ];
  List<AppNotification> _items;
  final _changes = StreamController<void>.broadcast(sync: true);
  @override
  Future<void> markRead(String id) async {
    _items = [
      for (final item in _items)
        item.id != id
            ? item
            : AppNotification(
                id: item.id,
                title: item.title,
                body: item.body,
                receivedAt: item.receivedAt,
                route: item.route,
                kind: item.kind,
                readAt: DateTime.now(),
                parentUid: item.parentUid)
    ];
    _changes.add(null);
  }

  @override
  Future<bool> requestPermission() async => true;
  @override
  Stream<List<AppNotification>> inbox() => Stream.multi((sink) {
        final sub =
            _changes.stream.listen((_) => sink.add(List.unmodifiable(_items)));
        sink.add(List.unmodifiable(_items));
        sink.onCancel = sub.cancel;
      });
  @override
  Stream<AppNotification> get onOpened => const Stream.empty();
  @override
  Stream<AppNotification> get onReceived => const Stream.empty();
  Future<void> dispose() => _changes.close();
}
