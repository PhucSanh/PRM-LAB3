import '../utils/app_error.dart';

/// Một liên hệ trong danh bạ điện thoại (S12 "Chọn từ danh bạ" `1:2146`).
/// Chỉ đọc – An Nhiên **không** ghi / xoá danh bạ (N21: "Danh bạ điện thoại vẫn giữ nguyên.").
///
/// Lớp nhỏ đặt cùng service (không nằm trong `lib/models/` của Hiếu): chỉ dùng
/// để chọn rồi điền sẵn vào form, không lưu Firestore.
class PhoneContact {
  const PhoneContact({
    required this.id,
    required this.name,
    required this.phone,
    this.label,
  });

  final String id;
  final String name;

  /// Số như máy trả về (có thể có khoảng trắng, "+84"…). ViewModel chuẩn hoá.
  final String phone;

  /// Nhãn / ghi chú của liên hệ, vd. "Con gái", "Hàng xóm" (Figma `1:2146`).
  final String? label;
}

/// Danh bạ điện thoại – F11 (Hương). Figma S12 `1:2146` là danh sách **trong app**
/// có ô "Tìm tên" (người dùng chọn theo Figma, 04/11/2026), cần quyền đọc danh bạ.
///
/// Bản thật: TODO(Hiếu) khi package được duyệt (đề xuất trong PR F11:
/// `flutter_contacts` – đọc danh bạ + xin quyền READ_CONTACTS).
abstract interface class ContactsService {
  /// Đã có quyền đọc danh bạ chưa (không hỏi Bác).
  Future<bool> hasPermission();

  /// Hỏi quyền. `false` = Bác từ chối → vẫn tự nhập được (luật F11).
  Future<bool> requestPermission();

  /// Liên hệ có số điện thoại, xếp theo tên. [query] lọc theo tên,
  /// không phân biệt hoa / thường và dấu ("mai" khớp "Mai", "hung" khớp "Hùng").
  /// Chưa có quyền / lỗi đọc → ném [AppException].
  Future<List<PhoneContact>> list({String query = ''});
}

/// Bỏ dấu tiếng Việt + chữ thường để so tên ("Hùng" → "hung").
String foldVietnamese(String input) {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final buffer = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    var out = ch;
    for (final entry in groups.entries) {
      if (entry.value.contains(ch)) {
        out = entry.key;
        break;
      }
    }
    buffer.write(out);
  }
  return buffer.toString().trim();
}

const _noPermission = AppException(
    'Bác chưa cho An Nhiên xem danh bạ. Bác có thể tự nhập tên và số.');
const _listFailed =
    AppException('Chưa mở được danh bạ. Bác có thể tự nhập tên và số.');

class FakeContactsService implements ContactsService {
  /// [granted] = Bác trả lời "Cho phép" khi được hỏi; `false` để test nhánh từ chối.
  /// [alreadyGranted] = đã cho phép từ trước (không cần hỏi).
  /// [failOnList] = đọc danh bạ lỗi (đã có quyền).
  FakeContactsService({
    this.granted = true,
    bool alreadyGranted = false,
    List<PhoneContact>? contacts,
    this.failOnList = false,
  })  : _hasPermission = alreadyGranted,
        _contacts = [...(contacts ?? figmaSample)];

  final bool granted;
  bool failOnList;
  bool _hasPermission;
  final List<PhoneContact> _contacts;

  /// Số lần hỏi quyền (test: không hỏi lại khi đã có quyền).
  int requestCount = 0;

  /// Danh bạ mẫu đúng Figma S12 `1:2146` (số hiển thị 4-3-3).
  static const figmaSample = [
    PhoneContact(
        id: 'c1', name: 'Mai', phone: '0912 345 678', label: 'Con gái'),
    PhoneContact(
        id: 'c2', name: 'Hùng', phone: '0903 222 111', label: 'Con trai'),
    PhoneContact(
        id: 'c3', name: 'Bin', phone: '0987 654 321', label: 'Cháu nội'),
    PhoneContact(
        id: 'c4', name: 'Cô Tám', phone: '0938 111 222', label: 'Hàng xóm'),
    PhoneContact(
        id: 'c5', name: 'Chị Hoa', phone: '0909 333 444', label: 'Bạn'),
  ];

  @override
  Future<bool> hasPermission() async => _hasPermission;

  @override
  Future<bool> requestPermission() async {
    if (_hasPermission) return true;
    requestCount++;
    _hasPermission = granted;
    return _hasPermission;
  }

  @override
  Future<List<PhoneContact>> list({String query = ''}) async {
    if (!_hasPermission) throw _noPermission;
    if (failOnList) throw _listFailed;
    final q = foldVietnamese(query);
    // Giữ thứ tự Figma (danh bạ mẫu đã sắp sẵn); bản thật xếp theo tên.
    return List.unmodifiable(_contacts
        .where((c) => q.isEmpty || foldVietnamese(c.name).contains(q)));
  }
}
