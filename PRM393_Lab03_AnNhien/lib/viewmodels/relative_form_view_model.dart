import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/relative.dart';
import '../services/contacts_service.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

/// F11 Thêm / sửa người thân – chủ: Hương.
/// Thêm (`/family/add`) – **một màn bố cục S12a** (người dùng chọn 04/11, DT-35): nút "Chọn từ danh bạ"
/// + "hoặc tự nhập" + form. S12a `14:120` (mới mở), S12 tự nhập `1:2215` (đã điền), S12e `14:196` (lỗi);
/// danh bạ `1:2146` là bước con ([RelativeFormStep.contacts]). Khung chọn cách `1:2110` không dùng.
/// Sửa (`/family/:personId/edit`): N09 `41:136`, N15 `43:263` (hỏi xoá) – bước 04.

/// 4 lựa chọn "Là gì của Bác?" (Figma S12a). Mặc định "Khác".
const relativeRelations = ['Con', 'Cháu', 'Bạn bè', 'Khác'];
const defaultRelation = 'Khác';

/// Câu chữ form (Figma S12a / S12e; câu Figma không vẽ đã được người dùng duyệt 04/11 – DT-35).
abstract final class RelativeFormText {
  static const nameMissing = 'Bác chưa nhập tên gọi.';
  static const phoneMissing = 'Bác chưa nhập số điện thoại.';
  static const phoneInvalid = 'Số điện thoại chưa đúng.';
  static const contactsDenied = 'Bác có thể tự nhập tên và số ở dưới.';
  static const saveFailed =
      'Chưa lưu được người thân. Bác bấm "Lưu người thân" lần nữa nhé.';
}

/// Bước của màn thêm.
enum RelativeFormStep {
  /// S12 `1:2146`: danh sách danh bạ + ô "Tìm tên".
  contacts,

  /// S12a / S12 tự nhập / S12e / N09: nút danh bạ + form tên – quan hệ – số.
  manual,
}

/// Quyền danh bạ. `denied` vẫn tự nhập được (luật F11).
enum ContactsAccess { unknown, granted, denied }

/// Chỉ giữ chữ số; "+84" / "84" đầu số → "0" ("+84 912 345 678" → "0912345678").
String phoneDigits(String raw) {
  var d = raw.replaceAll(RegExp(r'\D'), '');
  if (raw.trim().startsWith('+84') || (d.startsWith('84') && d.length == 11)) {
    d = '0${d.substring(2)}';
  }
  return d;
}

/// Số di động Việt Nam: 10 chữ số, bắt đầu bằng 0.
bool isValidPhone(String raw) => RegExp(r'^0\d{9}$').hasMatch(phoneDigits(raw));

/// Hiển thị 4-3-3 ("0912 345 678") như Figma; số không đủ 10 chữ số giữ nguyên.
String formatPhone(String raw) {
  final d = phoneDigits(raw);
  if (d.length != 10) return raw.trim();
  return '${d.substring(0, 4)} ${d.substring(4, 7)} ${d.substring(7)}';
}

/// Tự chèn khoảng trắng 4-3-3 **khi đang gõ** số bắt đầu bằng 0 ("091234" → "0912 34").
/// Có ký tự khác số (vd. "+84…") hoặc quá 10 số thì giữ nguyên chữ Bác gõ.
String formatPhoneInput(String raw) {
  final compact = raw.replaceAll(' ', '');
  if (!RegExp(r'^0\d{0,9}$').hasMatch(compact)) return raw;
  final parts = <String>[
    compact.substring(0, compact.length.clamp(0, 4)),
    if (compact.length > 4) compact.substring(4, compact.length.clamp(4, 7)),
    if (compact.length > 7) compact.substring(7),
  ];
  return parts.join(' ');
}

/// Nhãn liên hệ ("Con gái", "Cháu nội", "Bạn", "Hàng xóm") → 1 trong 4 nhóm (người dùng chọn 04/11).
String relationFromLabel(String? label) {
  final l = foldVietnamese(label ?? '');
  if (l.startsWith('con')) return 'Con';
  if (l.startsWith('chau')) return 'Cháu';
  if (l.startsWith('ban')) return 'Bạn bè';
  return defaultRelation;
}

/// Khoá `relation` gửi analytics (không dấu, không gửi tên / số).
String relationKey(String relation) => switch (relation) {
      'Con' => 'con',
      'Cháu' => 'chau',
      'Bạn bè' => 'ban_be',
      _ => 'khac',
    };

class RelativeForm {
  const RelativeForm({
    this.personId,
    this.step = RelativeFormStep.manual,
    this.name = '',
    this.relation = defaultRelation,
    this.phone = '',
    this.nameError,
    this.phoneError,
    this.dirty = false,
    this.saving = false,
    this.saveError,
    this.fromContacts = false,
    this.contactsAccess = ContactsAccess.unknown,
    this.contactsNotice,
    this.contacts = const [],
    this.contactsLoading = false,
    this.query = '',
    this.hadError = false,
    this.confirmingDelete = false,
  });

  /// `null` = thêm mới; có = sửa (N09).
  final String? personId;
  final RelativeFormStep step;
  final String name;
  final String relation;

  /// Số như Bác thấy trong ô (đã chèn khoảng trắng 4-3-3).
  final String phone;

  /// Lỗi từng ô; `null` = không lỗi. Dòng "Ví dụ: …" View luôn vẽ dưới ô.
  final String? nameError;
  final String? phoneError;

  /// Đã đổi gì so với lúc mở (hỏi "Bỏ người thân đang nhập?" khi rời màn).
  final bool dirty;
  final bool saving;
  final String? saveError;

  /// Tên + số được điền từ danh bạ (`add_relative.from_contacts`).
  final bool fromContacts;
  final ContactsAccess contactsAccess;

  /// Dòng ⓘ dưới nút "Chọn từ danh bạ" (từ chối quyền / không đọc được danh bạ).
  final String? contactsNotice;

  /// Kết quả danh bạ theo [query] (S12 `1:2146`).
  final List<PhoneContact> contacts;
  final bool contactsLoading;
  final String query;

  /// Đã từng gặp lỗi nhập trong lần này (`add_relative.had_error`).
  final bool hadError;

  /// Đang hiện hộp thoại N15.
  final bool confirmingDelete;

  bool get isEdit => personId != null;
  bool get hasInputError => nameError != null || phoneError != null;

  RelativeForm copyWith({
    RelativeFormStep? step,
    String? name,
    String? relation,
    String? phone,
    String? nameError,
    String? phoneError,
    bool clearNameError = false,
    bool clearPhoneError = false,
    bool? dirty,
    bool? saving,
    String? saveError,
    bool? fromContacts,
    ContactsAccess? contactsAccess,
    String? contactsNotice,
    bool clearContactsNotice = false,
    List<PhoneContact>? contacts,
    bool? contactsLoading,
    String? query,
    bool? hadError,
    bool? confirmingDelete,
  }) =>
      RelativeForm(
        personId: personId,
        step: step ?? this.step,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        phone: phone ?? this.phone,
        nameError: clearNameError ? null : (nameError ?? this.nameError),
        phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
        dirty: dirty ?? this.dirty,
        saving: saving ?? this.saving,
        saveError: saveError,
        fromContacts: fromContacts ?? this.fromContacts,
        contactsAccess: contactsAccess ?? this.contactsAccess,
        contactsNotice: clearContactsNotice
            ? null
            : (contactsNotice ?? this.contactsNotice),
        contacts: contacts ?? this.contacts,
        contactsLoading: contactsLoading ?? this.contactsLoading,
        query: query ?? this.query,
        hadError: hadError ?? this.hadError,
        confirmingDelete: confirmingDelete ?? this.confirmingDelete,
      );
}

const _loadFailed = 'Chưa tải được người thân. Bác bấm "Thử lại" nhé.';

/// Tham số family: `personId` (`null` = thêm mới).
class RelativeFormViewModel extends Notifier<UiState<RelativeForm>> {
  RelativeFormViewModel(this.personId);

  final String? personId;

  @override
  UiState<RelativeForm> build() {
    if (personId == null) return const UiData(RelativeForm());
    Future.microtask(load);
    return const UiLoading();
  }

  /// Sửa: lấy người thân từ `FamilyRepository.all()` (chưa có `byId`).
  /// Không tìm thấy → Empty; lỗi → Error (+ [retry]).
  Future<void> load() async {
    final id = personId;
    if (id == null || !ref.mounted) return;
    state = const UiLoading();
    try {
      final list = await ref.read(familyRepositoryProvider).all();
      if (!ref.mounted) return;
      final r = list.where((x) => x.id == id).firstOrNull;
      state = r == null
          ? const UiEmpty()
          : UiData(RelativeForm(
              personId: r.id,
              name: r.name,
              relation: r.relation,
              phone: formatPhone(r.phone),
            ));
    } catch (e) {
      if (!ref.mounted) return;
      state = UiError(e is AppException ? e.userMessage : _loadFailed);
    }
  }

  Future<void> retry() => load();

  RelativeForm? get _data => switch (state) {
        UiData(:final data) => data,
        _ => null,
      };

  void _update(RelativeForm Function(RelativeForm) change) {
    if (state case UiData(:final data)) state = UiData(change(data));
  }

  /// "Chọn từ danh bạ": hỏi quyền → được thì mở danh sách; từ chối → ở lại form với dòng
  /// "Bác có thể tự nhập tên và số ở dưới." – **không chặn** tự nhập.
  Future<void> pickFromContacts() async {
    final data = _data;
    if (data == null || data.saving) return;
    final contacts = ref.read(contactsServiceProvider);
    bool granted;
    try {
      granted = await contacts.requestPermission();
    } catch (_) {
      granted = false;
    }
    if (!ref.mounted) return;
    if (!granted) {
      _update((d) => d.copyWith(
            contactsAccess: ContactsAccess.denied,
            contactsNotice: RelativeFormText.contactsDenied,
          ));
      return;
    }
    _update((d) => d.copyWith(
          contactsAccess: ContactsAccess.granted,
          step: RelativeFormStep.contacts,
          query: '',
          clearContactsNotice: true,
        ));
    await search('');
  }

  /// Ô "Tìm tên" ở danh sách danh bạ. Đọc lỗi → về form, dòng ⓘ là câu của service.
  Future<void> search(String query) async {
    _update((d) => d.copyWith(query: query, contactsLoading: true));
    try {
      final list = await ref.read(contactsServiceProvider).list(query: query);
      if (!ref.mounted) return;
      // Bác đã gõ tiếp: bỏ kết quả cũ.
      if (_data?.query != query) return;
      _update((d) => d.copyWith(contacts: list, contactsLoading: false));
    } catch (e) {
      if (!ref.mounted) return;
      _update((d) => d.copyWith(
            step: RelativeFormStep.manual,
            contactsLoading: false,
            contacts: const [],
            contactsNotice: e is AppException
                ? e.userMessage
                : RelativeFormText.contactsDenied,
          ));
    }
  }

  /// Quay lại / "Tự nhập" ở danh bạ → form, giữ nguyên những gì đã nhập.
  void closeContacts() =>
      _update((d) => d.copyWith(step: RelativeFormStep.manual));

  /// Chạm một liên hệ: điền sẵn tên + số (4-3-3) + quan hệ theo nhãn, `fromContacts = true`, về form.
  void selectContact(PhoneContact contact) => _update((d) => d.copyWith(
        step: RelativeFormStep.manual,
        name: contact.name,
        phone: formatPhone(contact.phone),
        relation: relationFromLabel(contact.label),
        fromContacts: true,
        dirty: true,
        clearNameError: true,
        clearPhoneError: true,
        clearContactsNotice: true,
      ));

  void setName(String value) => _update(
      (d) => d.copyWith(name: value, dirty: true, clearNameError: true));

  void setRelation(String value) =>
      _update((d) => d.copyWith(relation: value, dirty: true));

  void setPhone(String value) => _update((d) => d.copyWith(
      phone: formatPhoneInput(value), dirty: true, clearPhoneError: true));

  /// Kiểm tra form. Lỗi → ghi vào state (giữ nguyên tên + quan hệ), `hadError = true`.
  bool _validate() {
    final d = _data;
    if (d == null) return false;
    final nameError =
        d.name.trim().isEmpty ? RelativeFormText.nameMissing : null;
    final phoneError = d.phone.trim().isEmpty
        ? RelativeFormText.phoneMissing
        : (isValidPhone(d.phone) ? null : RelativeFormText.phoneInvalid);
    final ok = nameError == null && phoneError == null;
    state = UiData(d.copyWith(
      nameError: nameError,
      phoneError: phoneError,
      clearNameError: nameError == null,
      clearPhoneError: phoneError == null,
      hadError: d.hadError || !ok,
    ));
    return ok;
  }

  /// "Lưu người thân": validate (lỗi có "Ví dụ: 0912 345 678", giữ tên + quan hệ),
  /// `FamilyRepository.save`, log `add_relative` (chỉ khi thêm mới). Trả người thân đã lưu để View
  /// gọi `FamilyViewModel.showAdded` rồi `pop` về S09; `null` = lỗi (state có lỗi).
  Future<Relative?> save() async {
    final before = _data;
    if (before == null || before.saving) return null;
    if (!_validate()) return null;
    final d = _data!;
    final relative = Relative(
      id: d.personId ?? 'rel-${DateTime.now().microsecondsSinceEpoch}',
      name: d.name.trim(),
      relation: d.relation,
      phone: phoneDigits(d.phone),
    );
    state = UiData(d.copyWith(saving: true));
    try {
      await ref.read(familyRepositoryProvider).save(relative);
    } catch (e, st) {
      if (!ref.mounted) return null;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'save_relative');
      if (!ref.mounted) return null;
      _update((x) => x.copyWith(
          saving: false,
          saveError:
              e is AppException ? e.userMessage : RelativeFormText.saveFailed));
      return null;
    }
    if (!ref.mounted) return relative;
    _update((x) => x.copyWith(saving: false, dirty: false));
    if (!d.isEdit) {
      try {
        await ref.read(analyticsServiceProvider).logEvent('add_relative', {
          'relation': relationKey(relative.relation),
          'from_contacts': d.fromContacts,
          'had_error': d.hadError,
        });
      } catch (_) {/* Analytics không được chặn Bác. */}
    }
    return relative;
  }

  /// "Xóa khỏi An Nhiên" ở N09 → hiện N15.
  void requestDelete() {
    // TODO bước 04
  }

  /// "Giữ lại" ở N15: chỉ đóng hộp thoại.
  void cancelDelete() {
    // TODO bước 04
  }

  /// Xác nhận ở N15: `FamilyRepository.delete` (không đụng danh bạ máy). Trả bản đã
  /// xoá cho `FamilyViewModel.showDeleted` (N21); `null` = lỗi.
  Future<Relative?> confirmDelete() async {
    // TODO bước 04
    return null;
  }
}

final relativeFormViewModelProvider = NotifierProvider.autoDispose
    .family<RelativeFormViewModel, UiState<RelativeForm>, String?>(
        RelativeFormViewModel.new);
