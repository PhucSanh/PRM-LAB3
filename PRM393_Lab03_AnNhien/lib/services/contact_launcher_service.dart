import '../utils/app_error.dart';

/// Kênh nhắn tin ở S17 `1:2278` ("Gửi bằng": Zalo – mặc định / Tin nhắn SMS).
/// `name` dùng làm `method` của event `share` (zalo / sms).
enum ShareChannel { zalo, sms }

/// Mở ứng dụng gọi điện / Zalo / SMS – F11 (Hương). S09 "Gọi" mở ngay, không hộp
/// thoại phụ; S17 mở app nhắn tin với nội dung soạn sẵn. App **không** biết tin đã
/// gửi hay chưa (S17b / N10 chỉ nói "chưa xác nhận") → hàm chỉ trả "đã mở được".
///
/// Kết quả: `true` = đã mở app; `false` = máy không mở được (vd. không cài Zalo,
/// không có app gọi điện); lỗi khác → ném [AppException] có câu cho Bác.
///
/// Bản thật: TODO(Hiếu) khi package được duyệt (đề xuất trong PR F11:
/// `url_launcher` – `tel:`, `sms:?body=`, `https://zalo.me/<số>`).
abstract interface class ContactLauncherService {
  /// Mở màn gọi điện với [phone] (gọi ngay, `tel:`).
  Future<bool> call(String phone);

  /// Mở Zalo tới [phone], kèm [text] (Zalo không nhận nội dung qua link thì bản
  /// thật chép [text] vào bộ nhớ tạm).
  Future<bool> openZalo(String phone, String text);

  /// Mở app tin nhắn SMS tới [phone] với nội dung [text].
  Future<bool> openSms(String phone, String text);
}

/// Một lần mở app (Fake ghi lại để test).
class LaunchRecord {
  const LaunchRecord(this.kind, this.phone, [this.text]);

  /// `call` / `zalo` / `sms`.
  final String kind;
  final String phone;
  final String? text;

  @override
  String toString() => 'LaunchRecord($kind, $phone, $text)';
}

class FakeContactLauncherService implements ContactLauncherService {
  /// `failOn…` = ném [AppException] (lỗi mở app);
  /// [noZalo] / [noSms] / [noDialer] = máy không có app → trả `false`.
  FakeContactLauncherService({
    this.failOnCall = false,
    this.failOnZalo = false,
    this.failOnSms = false,
    this.noZalo = false,
    this.noSms = false,
    this.noDialer = false,
  });

  bool failOnCall;
  bool failOnZalo;
  bool failOnSms;
  bool noZalo;
  bool noSms;
  bool noDialer;

  /// Các lần mở **thành công** theo thứ tự.
  final List<LaunchRecord> launched = [];

  static const callFailed = AppException('Chưa gọi được. Bác thử lại sau nhé.');
  static const zaloFailed =
      AppException('Chưa mở được Zalo. Bác thử chọn "Tin nhắn SMS" nhé.');
  static const smsFailed =
      AppException('Chưa mở được tin nhắn. Bác thử lại sau nhé.');

  @override
  Future<bool> call(String phone) async {
    if (failOnCall) throw callFailed;
    if (noDialer) return false;
    launched.add(LaunchRecord('call', phone));
    return true;
  }

  @override
  Future<bool> openZalo(String phone, String text) async {
    if (failOnZalo) throw zaloFailed;
    if (noZalo) return false;
    launched.add(LaunchRecord('zalo', phone, text));
    return true;
  }

  @override
  Future<bool> openSms(String phone, String text) async {
    if (failOnSms) throw smsFailed;
    if (noSms) return false;
    launched.add(LaunchRecord('sms', phone, text));
    return true;
  }
}
