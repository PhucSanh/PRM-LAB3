import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ba mức cỡ chữ Bác chọn ở S01 / S10 (DESIGN.md › typography, handoff S01: `textScaler` 1.0 / 1.15 / 1.3).
enum AppFontScale {
  vua(1.0, 'Vừa'),
  lon(1.15, 'Lớn'),
  ratLon(1.3, 'Rất lớn');

  const AppFontScale(this.factor, this.label);
  final double factor;
  final String label;
}

/// Hệ số chữ tối đa (cỡ Bác chọn × cỡ hệ thống): layout phải chịu được mức này.
const double maxTextScale = 2.0;

/// Cỡ chữ toàn app. Mặc định "Lớn" (Figma S01, S10). Giữ trong bộ nhớ; F8 nối `SettingsService` sau.
final fontScaleProvider =
    NotifierProvider<FontScaleNotifier, AppFontScale>(FontScaleNotifier.new);

class FontScaleNotifier extends Notifier<AppFontScale> {
  @override
  AppFontScale build() => AppFontScale.lon;

  void set(AppFontScale scale) => state = scale;
}

/// Tương phản cao (S10 "Chữ và nền rõ hơn"). Mặc định tắt. F8 nối `SettingsService` sau.
final highContrastProvider =
    NotifierProvider<HighContrastNotifier, bool>(HighContrastNotifier.new);

class HighContrastNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool enabled) => state = enabled;
}
