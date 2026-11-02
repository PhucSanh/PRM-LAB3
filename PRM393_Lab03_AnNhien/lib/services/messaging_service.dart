import '../models/app_notification.dart';

/// Firebase Cloud Messaging + danh sách thông báo đã nhận. Bản thật: B – Hiếu, F10.
abstract interface class MessagingService {
  /// Xin quyền POST_NOTIFICATIONS (Android 13+). Trả về false nếu Bác từ chối.
  Future<bool> requestPermission();
  Stream<List<AppNotification>> inbox();
  Stream<AppNotification> get onReceived;

  /// Thông báo Bác vừa bấm (app ở nền hoặc đã tắt) – router mở `route`.
  Stream<AppNotification> get onOpened;
}

class FakeMessagingService implements MessagingService {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Stream<List<AppNotification>> inbox() => Stream.value([
        AppNotification(
            id: 'n1',
            title: 'Đến giờ đi bộ',
            body: '9:30 sáng',
            receivedAt: DateTime(2026, 11, 2, 9, 30),
            route: '/reminder/t3'),
      ]);

  @override
  Stream<AppNotification> get onOpened => const Stream.empty();

  @override
  Stream<AppNotification> get onReceived => const Stream.empty();
}
