import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/providers.dart';
import '../services/settings_service.dart';
import '../theme/display_settings.dart';
import '../utils/app_error.dart';
import 'ui_state.dart';

/// F8 – Sanh. Màn S10 Cài đặt hiển thị (`/settings`, Figma `1:2325`, `1:2474`).
///
/// State: `UiState<AppSettings>`.
/// - `UiLoading`: `SettingsService.watch()` chưa phát giá trị đầu.
/// - `UiError` + [retry]: đọc cài đặt lỗi.
/// - `UiData`: cài đặt hiện tại.
/// - Không có `UiEmpty`: cài đặt luôn có giá trị (thiếu trường thì
///   `AppSettings` dùng mặc định), nên không có trạng thái "chưa có gì".
///
/// Mỗi hàm đổi áp dụng ngay trên máy rồi mới lưu, trả về [SettingChange] để
/// View hiện `showUndoSnackbar` (Hoàn tác → [undo]). Lưu lỗi: giữ giá trị trên
/// máy, ghi Crashlytics non-fatal, câu báo nhẹ ở [SettingChange.saveError].
///
/// Đăng xuất: View dùng `signOutViewModelProvider` (F1 – Hiếu, đã log `logout`
/// và xoá dữ liệu trên máy); ViewModel này không đăng xuất lần nữa.
class SettingsViewModel extends Notifier<UiState<AppSettings>> {
  @override
  UiState<AppSettings> build() {
    final subscription = ref.watch(settingsServiceProvider).watch().listen(
      (settings) => state = UiData(settings),
      onError: (Object error, StackTrace stack) async {
        state = UiError(error is AppException
            ? error.userMessage
            : AppException.unknown.userMessage);
        await _record(error, stack, 'load_settings');
      },
    );
    ref.onDispose(subscription.cancel);
    return const UiLoading();
  }

  /// "Thử lại" ở trạng thái lỗi: đăng ký lại `watch()`.
  void retry() => ref.invalidateSelf();

  AppSettings? get _current => switch (state) {
        UiData(:final data) => data,
        _ => null,
      };

  /// Đổi cỡ chữ: `fontScaleProvider` đổi ngay (toàn app), rồi lưu.
  /// Log `change_font_size` (`from` / `to` = `vua` / `lon` / `rat_lon`).
  /// Chọn lại đúng cỡ đang dùng → `null` (không lưu, không log).
  Future<FontScaleChange?> setFontScale(AppFontScale scale) async {
    final current = _current;
    if (current == null || current.fontScale == scale) return null;
    final from = current.fontScale;
    final error = await _applyFontScale(from, scale);
    return FontScaleChange(from: from, to: scale, saveError: error);
  }

  /// "Chữ và nền rõ hơn": `highContrastProvider` đổi ngay, rồi lưu.
  Future<HighContrastChange?> setHighContrast(bool enabled) async {
    final current = _current;
    if (current == null || current.highContrast == enabled) return null;
    final error = await _applyHighContrast(enabled);
    return HighContrastChange(
        from: current.highContrast, to: enabled, saveError: error);
  }

  /// "Đọc to lời nhắc": lưu.
  Future<ReadAloudChange?> setReadAloud(bool enabled) async {
    final current = _current;
    if (current == null || current.readAloud == enabled) return null;
    final error = await _applyReadAloud(enabled);
    return ReadAloudChange(
        from: current.readAloud, to: enabled, saveError: error);
  }

  /// "Rung khi nhắc": lưu.
  Future<VibrateChange?> setVibrate(bool enabled) async {
    final current = _current;
    if (current == null || current.vibrate == enabled) return null;
    final error = await _applyVibrate(enabled);
    return VibrateChange(from: current.vibrate, to: enabled, saveError: error);
  }

  /// "Hoàn tác" trên Snackbar: trả lại giá trị cũ và lưu lại.
  /// Trả về câu báo nhẹ nếu lưu lỗi, `null` nếu đã lưu.
  /// Hoàn tác cỡ chữ cũng là một lần đổi cỡ nên vẫn log `change_font_size`.
  Future<String?> undo(SettingChange change) => switch (change) {
        FontScaleChange(:final from, :final to) => _applyFontScale(to, from),
        HighContrastChange(:final from) => _applyHighContrast(from),
        ReadAloudChange(:final from) => _applyReadAloud(from),
        VibrateChange(:final from) => _applyVibrate(from),
      };

  // ---- Nội bộ ----

  Future<String?> _applyFontScale(AppFontScale from, AppFontScale to) async {
    ref.read(fontScaleProvider.notifier).set(to);
    _patch((s) => s.copyWith(fontScale: to));
    if (from != to) {
      try {
        await ref.read(analyticsServiceProvider).logEvent('change_font_size', {
          'from': fontSizeKey(from),
          'to': fontSizeKey(to),
        });
      } catch (_) {/* Analytics không được chặn Bác. */}
    }
    // TODO(Hiếu): đặt user property `font_size` khi AnalyticsService có setUserProperty.
    return _save((s) => s.setFontScale(to), 'save_font_scale');
  }

  Future<String?> _applyHighContrast(bool enabled) {
    ref.read(highContrastProvider.notifier).set(enabled);
    _patch((s) => s.copyWith(highContrast: enabled));
    // TODO(Hiếu): đặt user property `high_contrast` khi AnalyticsService có setUserProperty.
    return _save((s) => s.setHighContrast(enabled), 'save_high_contrast');
  }

  Future<String?> _applyReadAloud(bool enabled) {
    _patch((s) => s.copyWith(readAloud: enabled));
    return _save((s) => s.setReadAloud(enabled), 'save_read_aloud');
  }

  Future<String?> _applyVibrate(bool enabled) {
    _patch((s) => s.copyWith(vibrate: enabled));
    return _save((s) => s.setVibrate(enabled), 'save_vibrate');
  }

  /// Cập nhật ngay trên màn (trước khi lưu xong).
  void _patch(AppSettings Function(AppSettings) change) {
    final current = _current;
    if (current != null) state = UiData(change(current));
  }

  /// Lưu qua service. Lỗi: không ném ra View, ghi Crashlytics, trả câu báo.
  Future<String?> _save(
      Future<void> Function(SettingsService) write, String reason) async {
    try {
      await write(ref.read(settingsServiceProvider));
      return null;
    } catch (error, stack) {
      await _record(error, stack, reason);
      return error is AppException
          ? error.userMessage
          : AppException.unknown.userMessage;
    }
  }

  Future<void> _record(Object error, StackTrace stack, String reason) async {
    if (!ref.mounted) return;
    try {
      await ref
          .read(crashServiceProvider)
          .recordError(error, stack, reason: reason);
    } catch (_) {/* Crashlytics lỗi cũng không chặn Bác. */}
  }
}

final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, UiState<AppSettings>>(
        SettingsViewModel.new);

/// Giá trị `font_size` / `from` / `to` theo docs/analytics-plan.md
/// (giống F2 `FirstTaskViewModel`).
String fontSizeKey(AppFontScale scale) => switch (scale) {
      AppFontScale.vua => 'vua',
      AppFontScale.lon => 'lon',
      AppFontScale.ratLon => 'rat_lon',
    };

/// Một lần đổi cài đặt ở S10; View truyền lại cho [SettingsViewModel.undo].
sealed class SettingChange {
  const SettingChange({this.saveError});

  /// `null` = đã lưu. Khác `null` = chưa lưu được (giá trị vẫn giữ trên máy),
  /// View báo nhẹ bằng câu này.
  final String? saveError;
}

final class FontScaleChange extends SettingChange {
  const FontScaleChange(
      {required this.from, required this.to, super.saveError});
  final AppFontScale from;
  final AppFontScale to;
}

final class HighContrastChange extends SettingChange {
  const HighContrastChange(
      {required this.from, required this.to, super.saveError});
  final bool from;
  final bool to;
}

final class ReadAloudChange extends SettingChange {
  const ReadAloudChange(
      {required this.from, required this.to, super.saveError});
  final bool from;
  final bool to;
}

final class VibrateChange extends SettingChange {
  const VibrateChange({required this.from, required this.to, super.saveError});
  final bool from;
  final bool to;
}
