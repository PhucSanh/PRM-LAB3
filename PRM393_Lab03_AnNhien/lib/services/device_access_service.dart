import 'package:flutter/services.dart';
import '../utils/app_error.dart';

abstract interface class DeviceAccessService {
  Future<String?> recognize();
  Future<void> speak(String text);
  Future<void> stopSpeaking();
  Future<void> openNotificationSettings();
  Future<String?> savePdf(String name, Uint8List bytes);
}

class AndroidDeviceAccessService implements DeviceAccessService {
  static const channel = MethodChannel('an_nhien/device_access');
  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw AppException(e.message ?? 'Chưa thực hiện được. Bác thử lại nhé.',
          cause: e);
    } on MissingPluginException {
      throw const AppException(
          'Chức năng này cần chạy trên điện thoại Android.');
    }
  }

  @override
  Future<String?> recognize() => _call<String>('recognize');
  @override
  Future<void> speak(String text) => _call<void>('speak', text);
  @override
  Future<void> stopSpeaking() => _call<void>('stopSpeaking');
  @override
  Future<void> openNotificationSettings() =>
      _call<void>('notificationSettings');
  @override
  Future<String?> savePdf(String name, Uint8List bytes) =>
      _call<String>('savePdf', {'name': name, 'bytes': bytes});
}
