/// Only local, known destinations are accepted from push payloads.
String notificationTarget(String? value) {
  if (const ['/inbox', '/today', '/caregiver/schedule'].contains(value)) {
    return value!;
  }
  if (value != null &&
      RegExp(r'^/(caregiver/schedule|reminder/[A-Za-z0-9_-]+)\?date=\d{4}-\d{2}-\d{2}$')
          .hasMatch(value)) {
    final date = value.split('=').last;
    final parsed = DateTime.tryParse(date);
    if (parsed != null && parsed.toIso8601String().substring(0, 10) == date) {
      return value;
    }
  }
  if (value != null &&
      RegExp(r'^/(reminder/[A-Za-z0-9_-]+|today/suggestions/[A-Za-z0-9_-]+|inbox/suggestions/[A-Za-z0-9_-]+)$')
          .hasMatch(value)) {
    return value;
  }
  return '/inbox';
}

/// Older server inbox entries used the F12 demo route. Firebase messages must
/// always open the real backend-backed suggestion screen, including history.
String firebaseNotificationTarget(String? value) {
  if (value != null &&
      RegExp(r'^/today/suggestions/[A-Za-z0-9_-]+$').hasMatch(value)) {
    return '/inbox/suggestions/${value.split('/').last}';
  }
  return notificationTarget(value);
}
