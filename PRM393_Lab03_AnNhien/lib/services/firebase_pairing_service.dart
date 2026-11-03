import 'package:cloud_functions/cloud_functions.dart';
import '../utils/app_error.dart';
import 'pairing_service.dart';

/// Tự mang Firebase auth token; không chứa credential hoặc quyền Admin trong app.
class FirebaseCallableClient {
  FirebaseCallableClient(this.functions);
  final FirebaseFunctions functions;
  Future<Map<String, dynamic>> call(
      String name, Map<String, dynamic> data) async {
    try {
      final result =
          await functions.httpsCallable(name).call<Map<String, dynamic>>(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw AppException(
          switch (e.code) {
            'unauthenticated' => 'Cần đăng nhập trước khi thực hiện.',
            'not-found' when name == 'redeemPairing' =>
              'Mã chưa đúng hoặc đã hết hạn. Nhờ mẹ tạo mã mới rồi thử lại.',
            'resource-exhausted' =>
              'Đã thử nhiều lần. Chờ 10 phút rồi thử lại nhé.',
            'permission-denied' =>
              'Cần chọn đúng vai trò hoặc ghép nối lại với máy của mẹ.',
            'unavailable' ||
            'deadline-exceeded' =>
              'Chưa kết nối được. Kiểm tra mạng rồi thử lại.',
            'failed-precondition' =>
              'Lịch đã được xử lý hoặc đã thay đổi. Tải lại rồi thử lại.',
            _ => 'Chưa thực hiện được. Kiểm tra backend đã chạy rồi thử lại.',
          },
          cause: e);
    }
  }
}

class FirebasePairingService implements PairingService {
  FirebasePairingService(this.client);
  final FirebaseCallableClient client;
  @override
  Future<PairingCode> createCode() async {
    final d = await client.call('createPairing', {});
    return PairingCode(d['code'] as String,
        DateTime.fromMillisecondsSinceEpoch((d['expiresAt'] as num).toInt()));
  }

  @override
  Future<String> redeem(String code) async =>
      (await client.call('redeemPairing', {'code': code}))['momUid'] as String;
  @override
  Future<void> revoke(String momUid, String childUid) async {
    await client
        .call('revokePairing', {'momUid': momUid, 'childUid': childUid});
  }
}
