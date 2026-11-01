/// Thông báo đã nhận (FCM), hiện trong Hộp thông báo.
class AppNotification {
  const AppNotification({required this.id, required this.title, required this.body, required this.receivedAt, this.route});

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;

  /// Màn mở ra khi bấm thông báo, vd. `/reminder/abc`.
  final String? route;
}
