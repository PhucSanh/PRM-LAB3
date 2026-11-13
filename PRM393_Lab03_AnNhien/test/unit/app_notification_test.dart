import 'package:an_nhien/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification Model Unit Tests', () {
    test('1. initializes with unread state when readAt is null', () {
      final notif = AppNotification(
        id: 'notif_01',
        title: 'Lời nhắc uống thuốc',
        body: 'Đã đến giờ uống thuốc huyết áp',
        receivedAt: DateTime(2026, 11, 13, 8, 0),
      );
      expect(notif.isRead, isFalse);
      expect(notif.readAt, isNull);
    });

    test('2. isRead evaluates true when readAt timestamp is set', () {
      final notif = AppNotification(
        id: 'notif_02',
        title: 'Tin nhắn gia đình',
        body: 'Con gái đã gửi lời nhắn mới',
        receivedAt: DateTime(2026, 11, 13, 9, 0),
        readAt: DateTime(2026, 11, 13, 9, 5),
      );
      expect(notif.isRead, isTrue);
      expect(notif.readAt, isNotNull);
    });

    test('3. defaults notification kind to NotificationKind.system when omitted', () {
      final notif = AppNotification(
        id: 'notif_03',
        title: 'Cập nhật hệ thống',
        body: 'Hệ thống đã đồng bộ lịch tuần',
        receivedAt: DateTime(2026, 11, 13, 10, 0),
      );
      expect(notif.kind, NotificationKind.system);
    });
  });
}\n