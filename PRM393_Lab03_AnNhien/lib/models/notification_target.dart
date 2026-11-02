/// Only local, known destinations are accepted from push payloads.
String notificationTarget(String? value) {
  if (value == '/inbox') return '/inbox';
  if (value != null &&
      RegExp(r'^/(reminder/[A-Za-z0-9_-]+|today/suggestions/[A-Za-z0-9_-]+)$')
          .hasMatch(value)) {
    return value;
  }
  return '/inbox';
}
