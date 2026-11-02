/// Vai trò trong giao diện; quyền truy cập lịch người khác vẫn do rules/grant.
enum UserRole { elder, caregiver }

class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName,
    this.photoUrl,
    this.role,
    this.onboarded = false,
    this.pairedMomUid,
  });

  final String uid;
  final String? displayName;
  final String? photoUrl;
  final UserRole? role;
  final bool onboarded;

  /// Chỉ dùng để chọn nhánh UI, không thay thế caregiver grant trong rules.
  final String? pairedMomUid;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    final roleName = data['role'];
    if (roleName != null &&
        !UserRole.values.asNameMap().containsKey(roleName)) {
      throw const FormatException('Unknown profile role');
    }
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: UserRole.values.asNameMap()[roleName],
      onboarded: data['onboarded'] as bool? ?? false,
      pairedMomUid: data['pairedMomUid'] as String?,
    );
  }

  UserProfile copyWith({UserRole? role, bool? onboarded}) => UserProfile(
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
        role: role ?? this.role,
        onboarded: onboarded ?? this.onboarded,
        pairedMomUid: pairedMomUid,
      );
}
