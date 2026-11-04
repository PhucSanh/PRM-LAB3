import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_setup_service.dart';
import '../services/providers.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

export '../services/profile_setup_service.dart' show Honorific;

/// F8 – Sanh (chủ; F10 thêm khu demo). Màn N06 Thông tin của Bác
/// (`/settings/profile`, Figma `38:187`). Màn: `ProfileScreen` (bước 03).
/// Kiểm tra tên chép **logic** S02 của F2 (`OnboardingViewModel`), không import.
/// Analytics: `docs/analytics-plan.md` không có event cho N06 nên không log.
///
/// Nguồn dữ liệu:
/// - `displayName`: `ProfileService.watch(uid)`.
/// - `honorific`, `wakeTime`: `ProfileSetupService.watchSetup(uid)` (tạm, tới
///   khi Hiếu gộp vào `ProfileService` / `UserProfile`).
///
/// State: `UiState<ProfileForm>` – Loading / Error + Thử lại ([load]) / Data.
/// Không có `UiEmpty`: hồ sơ luôn có (tạo lúc đăng nhập); thiếu cách gọi /
/// giờ thức dậy thì dùng mặc định như S02 (Ông, 6:00 sáng).
class ProfileForm {
  const ProfileForm({
    this.displayName = '',
    this.honorific = Honorific.ong,
    this.wakeTime = const TimeOfDay(hour: 6, minute: 0),
    this.dirty = false,
    this.nameError,
    this.saving = false,
    this.saveError,
  });

  /// Tên gọi. KHÔNG gửi lên analytics.
  final String displayName;
  final Honorific honorific;
  final TimeOfDay wakeTime;

  /// Có thay đổi chưa lưu ("Quay lại" phải hỏi lại trước khi bỏ).
  final bool dirty;

  /// Lỗi nhập tên (View hiện kèm "Ví dụ: …").
  final String? nameError;

  /// Đang lưu: nút "Lưu" hiện vòng xoay.
  final bool saving;

  /// Lỗi lưu (`AppException.userMessage`); dữ liệu đã nhập vẫn giữ.
  final String? saveError;

  ProfileForm copyWith({
    String? displayName,
    Honorific? honorific,
    TimeOfDay? wakeTime,
    bool? dirty,
    String? nameError,
    bool? saving,
    String? saveError,
    bool clearErrors = false,
  }) =>
      ProfileForm(
        displayName: displayName ?? this.displayName,
        honorific: honorific ?? this.honorific,
        wakeTime: wakeTime ?? this.wakeTime,
        dirty: dirty ?? this.dirty,
        nameError: clearErrors ? null : nameError ?? this.nameError,
        saving: saving ?? this.saving,
        saveError: clearErrors ? null : saveError ?? this.saveError,
      );
}

/// Tên gọi dài nhất (giống S02 `maxNameLength`).
const maxProfileNameLength = 40;

/// Một lần lưu thành công; View truyền lại cho [ProfileViewModel.undo].
class ProfileSaved {
  const ProfileSaved({required this.previous});

  /// Bản đã lưu trước lần này (Hoàn tác lưu lại bản này).
  final ProfileSetup previous;
}

class ProfileViewModel extends Notifier<UiState<ProfileForm>> {
  /// Bản đang lưu trên tài khoản: so với form để biết `dirty`, dùng cho
  /// [discard] và [ProfileSaved.previous].
  ProfileSetup? _saved;

  @override
  UiState<ProfileForm> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  /// Nạp tên + cách gọi + giờ thức dậy (giá trị hiện tại, một lần). Cũng là
  /// "Thử lại" ở trạng thái lỗi. Mở lại màn thì nạp lại (bỏ form cũ).
  Future<void> load() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) {
        throw const AppException('Bác cần đăng nhập lại rồi mới xem được.');
      }
      final profile = await ref.read(profileServiceProvider).watch(uid).first;
      final setup =
          await ref.read(profileSetupServiceProvider).watchSetup(uid).first;
      if (!ref.mounted) return;
      // Cả hai cùng là `users/{uid}.displayName` trên Firestore; bản Fake
      // tách riêng nên ưu tiên tên Bác đã lưu ở S02 / N06 nếu có.
      final saved = ProfileSetup(
        displayName: setup?.displayName ?? profile.displayName ?? '',
        honorific: setup?.honorific ?? Honorific.ong,
        wakeHour: setup?.wakeHour ?? 6,
        wakeMinute: setup?.wakeMinute ?? 0,
      );
      _saved = saved;
      state = UiData(_formOf(saved));
    } catch (error, stack) {
      if (!ref.mounted) return;
      await _record(error, stack, 'load_profile');
      if (!ref.mounted) return;
      state = UiError(_message(error));
    }
  }

  /// "Thử lại" ở `ErrorView`.
  Future<void> retry() => load();

  /// Bác gõ tên: cập nhật form, ẩn lỗi cũ.
  void changeName(String name) =>
      _edit((f) => f.copyWith(displayName: name, clearErrors: true));

  /// Ông / Bà.
  void changeHonorific(Honorific honorific) =>
      _edit((f) => f.copyWith(honorific: honorific));

  /// Giờ từ `showTimeWheel`.
  void changeWakeTime(TimeOfDay time) =>
      _edit((f) => f.copyWith(wakeTime: time));

  /// "Lưu thông tin": kiểm tra tên giống S02 rồi lưu qua
  /// `ProfileSetupService.saveSetup`. Thành công → [ProfileSaved] để View hiện
  /// Snackbar Hoàn tác. Không lưu được → `null`, lỗi nằm ở `nameError` /
  /// `saveError`, chữ Bác đã gõ vẫn giữ.
  Future<ProfileSaved?> save() async {
    final form = _form;
    final previous = _saved;
    if (form == null || previous == null || form.saving) return null;
    final name = _normalizeName(form.displayName);
    final nameError = _nameError(name);
    if (nameError != null) {
      state = UiData(form.copyWith(nameError: nameError));
      return null;
    }
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) {
      state = UiData(
          form.copyWith(saveError: 'Bác cần đăng nhập lại rồi mới lưu được.'));
      return null;
    }
    final next = ProfileSetup(
      displayName: name,
      honorific: form.honorific,
      wakeHour: form.wakeTime.hour,
      wakeMinute: form.wakeTime.minute,
    );
    state = UiData(
        form.copyWith(displayName: name, saving: true, clearErrors: true));
    try {
      await ref.read(profileSetupServiceProvider).saveSetup(uid, next);
      if (!ref.mounted) return null;
      _saved = next;
      state = UiData(_formOf(next));
      return ProfileSaved(previous: previous);
    } catch (error, stack) {
      if (!ref.mounted) return null;
      await _record(error, stack, 'save_profile');
      if (!ref.mounted) return null;
      _edit((f) => f.copyWith(saving: false, saveError: _message(error)));
      return null;
    }
  }

  /// "Hoàn tác" sau khi lưu: lưu lại bản cũ. Trả câu báo nếu lưu lỗi.
  Future<String?> undo(ProfileSaved change) async {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return 'Bác cần đăng nhập lại rồi mới lưu được.';
    try {
      await ref
          .read(profileSetupServiceProvider)
          .saveSetup(uid, change.previous);
      if (!ref.mounted) return null;
      _saved = change.previous;
      state = UiData(_formOf(change.previous));
      return null;
    } catch (error, stack) {
      await _record(error, stack, 'undo_save_profile');
      return _message(error);
    }
  }

  /// Bỏ thay đổi chưa lưu (View đã hỏi lại trước).
  void discard() {
    final saved = _saved;
    if (saved != null && _form != null) state = UiData(_formOf(saved));
  }

  // ---- Nội bộ ----

  ProfileForm? get _form => switch (state) {
        UiData(:final data) => data,
        _ => null,
      };

  /// Sửa form và tính lại `dirty` (so với bản đã lưu).
  void _edit(ProfileForm Function(ProfileForm) change) {
    final form = _form;
    if (form == null) return;
    final next = change(form);
    state = UiData(next.copyWith(dirty: _differs(next)));
  }

  bool _differs(ProfileForm form) {
    final saved = _saved;
    if (saved == null) return false;
    return _normalizeName(form.displayName) != saved.displayName ||
        form.honorific != saved.honorific ||
        form.wakeTime.hour != saved.wakeHour ||
        form.wakeTime.minute != saved.wakeMinute;
  }

  static ProfileForm _formOf(ProfileSetup s) => ProfileForm(
        displayName: s.displayName,
        honorific: s.honorific,
        wakeTime: TimeOfDay(hour: s.wakeHour, minute: s.wakeMinute),
      );

  static String _normalizeName(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Giống S02. Câu "Ví dụ: …" do ô nhập hiện ngay dưới lỗi (`hint`).
  static String? _nameError(String name) {
    if (name.isEmpty) return 'Bác chưa nhập tên gọi.';
    if (name.length > maxProfileNameLength) {
      return 'Tên gọi dài quá, Bác viết ngắn lại nhé.';
    }
    return null;
  }

  static String _message(Object error) => error is AppException
      ? error.userMessage
      : AppException.unknown.userMessage;

  Future<void> _record(Object error, StackTrace stack, String reason) async {
    if (!ref.mounted) return;
    try {
      await ref
          .read(crashServiceProvider)
          .recordError(error, stack, reason: reason);
    } catch (_) {/* Crashlytics lỗi cũng không chặn Bác. */}
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, UiState<ProfileForm>>(
        ProfileViewModel.new);
