import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_setup_service.dart';
import '../services/providers.dart';
import '../theme/display_settings.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

export '../services/profile_setup_service.dart' show Honorific;

/// F2 Onboarding của Bác – chủ: Hương.
/// Màn: S01 (`/welcome`), S02 + DLG-WakeTime (`/setup`), S13 / S13d (`/setup/notifications`).
/// Bước 01 dựng khung; bước 02 làm S01, bước 03 làm S02; bước 04 điền S13.

/// Bước đang hiện. S13d là state của S13 (cùng route), không phải route mới.
enum OnboardingStep { welcome, profile, notifications, notificationsDenied }

/// Ba state của S02 (cùng route `/setup`, không phải route mới):
/// [confirmName] = "Bác là Lan, đúng không?" (Figma `1:58`),
/// [enterName] = "Bác tên là gì?" (`1:176`, có lỗi tên trống),
/// [details] = "Giới thiệu về Bác" – cách gọi + giờ thức dậy (`1:103`).
enum ProfileStage { confirmName, enterName, details }

/// Tên gọi dài nhất (theo ô 72 dp ở 360 dp; style guide không quy định).
const maxNameLength = 40;

/// Kết quả hỏi quyền thông báo ở S13.
enum PermissionResult { granted, denied }

class OnboardingData {
  const OnboardingData({
    this.step = OnboardingStep.welcome,
    this.fontScale = AppFontScale.lon,
    this.profileStage = ProfileStage.enterName,
    this.name = '',
    // Figma `1:103`: "Ông" chọn sẵn, giờ thức dậy 6:00 sáng.
    this.honorific = Honorific.ong,
    this.wakeTime = const TimeOfDay(hour: 6, minute: 0),
    this.nameError,
    this.saving = false,
    this.saveError,
    this.notificationsOn = false,
  });

  final OnboardingStep step;
  final AppFontScale fontScale;

  /// Tên Bác gõ / xác nhận ở S02. KHÔNG gửi lên analytics.
  final String name;
  final ProfileStage profileStage;
  final Honorific honorific;
  final TimeOfDay wakeTime;

  /// Lỗi nhập tên (có "Ví dụ: …").
  final String? nameError;

  /// Đang lưu hồ sơ (S02) hoặc đang hỏi quyền nhắc việc (S13): nút hiện vòng xoay.
  final bool saving;

  /// Lỗi lưu hồ sơ (`AppException.userMessage`); dữ liệu đã nhập vẫn giữ.
  final String? saveError;

  /// Cờ cho `tutorial_complete.notifications_on` (bước 06).
  final bool notificationsOn;

  OnboardingData copyWith({
    OnboardingStep? step,
    AppFontScale? fontScale,
    String? name,
    ProfileStage? profileStage,
    Honorific? honorific,
    TimeOfDay? wakeTime,
    String? nameError,
    bool? saving,
    String? saveError,
    bool? notificationsOn,
    bool clearErrors = false,
  }) =>
      OnboardingData(
        step: step ?? this.step,
        fontScale: fontScale ?? this.fontScale,
        name: name ?? this.name,
        profileStage: profileStage ?? this.profileStage,
        honorific: honorific ?? this.honorific,
        wakeTime: wakeTime ?? this.wakeTime,
        nameError: clearErrors ? null : nameError ?? this.nameError,
        saving: saving ?? this.saving,
        saveError: clearErrors ? null : saveError ?? this.saveError,
        notificationsOn: notificationsOn ?? this.notificationsOn,
      );
}

class OnboardingViewModel extends Notifier<UiState<OnboardingData>> {
  /// Bác đã chạm chọn cỡ chữ ở S01 thì [load] không ghi đè bằng giá trị đã lưu.
  bool _fontScalePicked = false;

  /// S13 chỉ tự đi tiếp ở lần vào đầu: quay lại từ N01 thì Bác vẫn thấy S13.
  bool _permissionChecked = false;

  @override
  UiState<OnboardingData> build() {
    Future.microtask(load);
    return const UiLoading();
  }

  /// Nạp cỡ chữ đã lưu (áp cho toàn app) và tên gợi ý từ tài khoản Google.
  /// Có tên gợi ý → S02 hỏi "Bác là …, đúng không?"; không có → Bác tự gõ.
  Future<void> load() async {
    if (!ref.mounted) return;
    state = const UiLoading();
    try {
      final settings = await ref.read(settingsServiceProvider).watch().first;
      if (!ref.mounted) return;
      final fontScale =
          _fontScalePicked ? ref.read(fontScaleProvider) : settings.fontScale;
      ref.read(fontScaleProvider.notifier).set(fontScale);
      final suggested = _normalizeName(
          ref.read(authServiceProvider).currentUser?.displayName ?? '');
      state = UiData(OnboardingData(
        fontScale: fontScale,
        name: suggested,
        profileStage: suggested.isEmpty
            ? ProfileStage.enterName
            : ProfileStage.confirmName,
      ));
    } catch (e, st) {
      if (!ref.mounted) return;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'load_onboarding');
      if (!ref.mounted) return;
      state = UiError(
          e is AppException ? e.userMessage : AppException.unknown.userMessage);
    }
  }

  // ---- S01 ----

  /// Chữ toàn app đổi ngay (`fontScaleProvider`), rồi lưu qua `SettingsService`.
  /// Lưu lỗi thì giữ lựa chọn trên máy, không báo Bác (ghi Crashlytics non-fatal).
  Future<void> selectFontScale(AppFontScale scale) async {
    _fontScalePicked = true;
    ref.read(fontScaleProvider.notifier).set(scale);
    if (state case UiData(:final data)) {
      state = UiData(data.copyWith(fontScale: scale));
    }
    try {
      await ref.read(settingsServiceProvider).setFontScale(scale);
    } catch (e, st) {
      if (!ref.mounted) return;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'save_font_scale');
    }
  }

  // ---- S02 + DLG-WakeTime ----

  void _update(OnboardingData Function(OnboardingData) change) {
    if (state case UiData(:final data)) state = UiData(change(data));
  }

  static String _normalizeName(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// `null` = hợp lệ. Câu "Ví dụ: …" do ô nhập hiện ngay dưới lỗi.
  static String? _nameError(String name) {
    if (name.isEmpty) return 'Bác chưa nhập tên gọi.';
    if (name.length > maxNameLength) {
      return 'Tên gọi dài quá, Bác viết ngắn lại nhé.';
    }
    return null;
  }

  /// Bác gõ tên (S02 Nhập lại tên); gõ lại thì ẩn lỗi cũ.
  void setName(String name) =>
      _update((d) => d.copyWith(name: name, clearErrors: true));

  /// "Đúng rồi" ở S02 Xác nhận tên → sang phần cách gọi + giờ thức dậy.
  void confirmName() => _update(
      (d) => d.copyWith(profileStage: ProfileStage.details, clearErrors: true));

  /// "Nhập lại tên" → ô nhập tên.
  void editName() => _update((d) =>
      d.copyWith(profileStage: ProfileStage.enterName, clearErrors: true));

  /// "Tiếp tục" ở ô nhập tên: tên hợp lệ thì sang phần chi tiết, không thì báo lỗi.
  bool submitName() {
    final data = switch (state) { UiData(:final data) => data, _ => null };
    if (data == null) return false;
    final name = _normalizeName(data.name);
    final error = _nameError(name);
    state = UiData(error == null
        ? data.copyWith(
            name: name, profileStage: ProfileStage.details, clearErrors: true)
        : data.copyWith(nameError: error));
    return error == null;
  }

  void setHonorific(Honorific honorific) =>
      _update((d) => d.copyWith(honorific: honorific));

  /// Giờ từ DLG-WakeTime (`showTimeWheel`).
  void setWakeTime(TimeOfDay time) =>
      _update((d) => d.copyWith(wakeTime: time));

  /// "Tiếp tục" ở S02: kiểm tra tên rồi lưu hồ sơ. `true` → View
  /// `go('/setup/notifications')`. Lỗi lưu: giữ nguyên dữ liệu đã nhập.
  Future<bool> submitProfile() async {
    final data = switch (state) { UiData(:final data) => data, _ => null };
    if (data == null || data.saving) return false;
    final name = _normalizeName(data.name);
    final nameError = _nameError(name);
    if (nameError != null) {
      state = UiData(data.copyWith(
          profileStage: ProfileStage.enterName, nameError: nameError));
      return false;
    }
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) {
      state = UiData(
          data.copyWith(saveError: 'Bác cần đăng nhập lại rồi mới lưu được.'));
      return false;
    }
    state = UiData(data.copyWith(name: name, saving: true, clearErrors: true));
    try {
      await ref.read(profileSetupServiceProvider).saveSetup(
            uid,
            ProfileSetup(
              displayName: name,
              honorific: data.honorific,
              wakeHour: data.wakeTime.hour,
              wakeMinute: data.wakeTime.minute,
            ),
          );
      if (!ref.mounted) return false;
      _update(
          (d) => d.copyWith(saving: false, step: OnboardingStep.notifications));
      return true;
    } catch (e, st) {
      if (!ref.mounted) return false;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'save_profile_setup');
      if (!ref.mounted) return false;
      _update((d) => d.copyWith(
          saving: false,
          saveError: e is AppException
              ? e.userMessage
              : AppException.unknown.userMessage));
      return false;
    }
  }

  // ---- S13 / S13d ----

  /// Vào S13 lần đầu: máy đã cho phép nhắc việc từ trước thì trả `true` để View
  /// đi thẳng sang thử lời nhắc (không hỏi lại). Lỗi đọc quyền → coi như chưa có.
  Future<bool> checkPermission() async {
    if (_permissionChecked) return false;
    _permissionChecked = true;
    bool granted;
    try {
      granted = await ref.read(reminderServiceProvider).hasPermission();
    } catch (e, st) {
      if (!ref.mounted) return false;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'check_reminder_permission');
      granted = false;
    }
    if (!ref.mounted) return false;
    if (granted) {
      _update((d) => d.copyWith(
          step: OnboardingStep.notifications, notificationsOn: true));
    }
    return granted;
  }

  /// "Bật nhắc việc" (S13 và S13d): hỏi quyền hệ thống. Cho phép → View sang
  /// `/setup/try-reminder`; từ chối → S13d. Không có package mở cài đặt hệ
  /// thống (DT-25) nên S13d chỉ hỏi lại quyền.
  Future<PermissionResult> allowReminders() async {
    final data = switch (state) { UiData(:final data) => data, _ => null };
    if (data == null || data.saving) return PermissionResult.denied;
    state = UiData(data.copyWith(saving: true));
    bool granted;
    try {
      granted = await ref.read(reminderServiceProvider).requestPermission();
    } catch (e, st) {
      if (!ref.mounted) return PermissionResult.denied;
      await ref
          .read(crashServiceProvider)
          .recordError(e, st, reason: 'request_reminder_permission');
      granted = false;
    }
    if (!ref.mounted) return PermissionResult.denied;
    _update((d) => d.copyWith(
          saving: false,
          notificationsOn: granted,
          step: granted
              ? OnboardingStep.notifications
              : OnboardingStep.notificationsDenied,
        ));
    return granted ? PermissionResult.granted : PermissionResult.denied;
  }

  /// "Để sau" ở S13 → S13d (nói rõ hậu quả, cách bật lại).
  void skipReminders() => _update((d) => d.copyWith(
      step: OnboardingStep.notificationsDenied, notificationsOn: false));

  /// "Quay lại" ở S13d → về S13 (cùng route).
  void showReminderPrompt() =>
      _update((d) => d.copyWith(step: OnboardingStep.notifications));
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, UiState<OnboardingData>>(
        OnboardingViewModel.new);
