import 'package:flutter/services.dart';
import '../utils/app_error.dart';

abstract interface class ContactLauncherService {
  Future<void> openDialer(String phone);
}

class AndroidContactLauncherService implements ContactLauncherService {
  static const channel = MethodChannel('an_nhien/device_access');
  @override
  Future<void> openDialer(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[ ()-]'), '');
    if (!RegExp(r'^\+?[0-9]{6,20}$').hasMatch(normalized))
      throw const AppException(
          'Số điện thoại chưa hợp lệ. Bác sửa lại thông tin người thân nhé.');
    try {
      await channel.invokeMethod<void>('openDialer', normalized);
    } catch (_) {
      throw const AppException(
          'Chưa mở được màn hình gọi. Bác có thể sao chép số điện thoại.');
    }
  }
}

class FakeContactLauncherService implements ContactLauncherService {
  String? opened;
  @override
  Future<void> openDialer(String phone) async {
    opened = phone;
  }
}
