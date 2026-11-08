import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// One API origin for the APK, backed by real Firebase. No database emulator.
/// Release builds require HTTPS; debug builds may use a LAN HTTP server.
const backendUrl = String.fromEnvironment('BACKEND_URL');

HttpsCallable backendCallable(FirebaseFunctions functions, String name,
    {HttpsCallableOptions? options}) {
  if (backendUrl.isEmpty) {
    return functions.httpsCallable(name, options: options);
  }
  final uri = Uri.parse(backendUrl);
  if (!uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      !['http', 'https'].contains(uri.scheme) ||
      (!kDebugMode && uri.scheme != 'https')) {
    throw StateError('BACKEND_URL phải là HTTPS khi build release.');
  }
  final base = backendUrl.replaceFirst(RegExp(r'/+$'), '');
  return functions.httpsCallableFromUrl('$base/api/$name', options: options);
}
