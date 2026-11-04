enum NotificationKind { family, system, reminder }

/// Thông báo đã nhận (FCM), hiện trong Hộp thông báo.
class AppNotification {
  const AppNotification(
      {required this.id,
      required this.title,
      required this.body,
      required this.receivedAt,
      this.route,
      this.kind = NotificationKind.system,
      this.readAt,
      this.parentUid});

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;

  /// Màn mở ra khi bấm thông báo, vd. `/reminder/abc`.
  final String? route;
  final NotificationKind kind;
  final DateTime? readAt;
  final String? parentUid;
  bool get isRead => readAt != null;
}
