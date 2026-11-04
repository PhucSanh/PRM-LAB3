import '../utils/app_error.dart';

class PairingCode {
  const PairingCode(this.code, this.expiresAt);
  final String code;
  final DateTime expiresAt;
}

class PairingLink {
  const PairingLink(this.uid, this.name);
  final String uid, name;
}

abstract interface class PairingService {
  Stream<List<PairingLink>> watchCaregivers();
  Future<PairingCode> createCode();
  Future<String> redeem(String code);
  Future<void> revoke(String momUid, String childUid);
}

class FakePairingService implements PairingService {
  FakePairingService({this.now = DateTime.now});
  final DateTime Function() now;
  PairingCode? current;
  bool consumed = false;
  @override
  Stream<List<PairingLink>> watchCaregivers() => Stream.value(const []);
  @override
  Future<PairingCode> createCode() async {
    consumed = false;
    return current =
        PairingCode('123456', now().add(const Duration(minutes: 10)));
  }

  @override
  Future<String> redeem(String code) async {
    current ??= PairingCode('123456', now().add(const Duration(minutes: 10)));
    if (consumed ||
        code != current!.code ||
        !current!.expiresAt.isAfter(now())) {
      throw const AppException(
          'Mã chưa đúng hoặc đã hết hạn. Nhờ mẹ tạo mã mới rồi thử lại.');
    }
    consumed = true;
    return 'demo-mom';
  }

  @override
  Future<void> revoke(String momUid, String childUid) async {
    consumed = false;
    current = null;
  }
}
