/// Người dùng đã đăng nhập. Không chứa e-mail/tên trong analytics.
class AppUser {
  const AppUser({required this.uid, this.displayName, this.photoUrl});

  final String uid;
  final String? displayName;
  final String? photoUrl;
}
