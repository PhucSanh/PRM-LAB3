import '../theme/display_settings.dart';

/// Cài đặt hiển thị / nhắc việc của Bác (Firestore `users/{uid}`: `fontScale`,
/// `highContrast`, `readAloud`, `vibrate` – architecture.md mục 10).
/// F2 đề xuất file này; Hiếu chốt trong PR.
class AppSettings {
  const AppSettings({
    this.fontScale = AppFontScale.lon,
    this.highContrast = false,
    this.readAloud = false,
    this.vibrate = true,
  });

  /// Mặc định "Lớn" (Figma S01, S10).
  final AppFontScale fontScale;
  final bool highContrast;
  final bool readAloud;
  final bool vibrate;

  AppSettings copyWith({
    AppFontScale? fontScale,
    bool? highContrast,
    bool? readAloud,
    bool? vibrate,
  }) =>
      AppSettings(
        fontScale: fontScale ?? this.fontScale,
        highContrast: highContrast ?? this.highContrast,
        readAloud: readAloud ?? this.readAloud,
        vibrate: vibrate ?? this.vibrate,
      );

  /// Firestore lưu `fontScale` là số 1.0 / 1.15 / 1.3.
  Map<String, Object?> toMap() => {
        'fontScale': fontScale.factor,
        'highContrast': highContrast,
        'readAloud': readAloud,
        'vibrate': vibrate,
      };

  factory AppSettings.fromMap(Map<String, Object?> m) {
    final factor = (m['fontScale'] as num?)?.toDouble();
    return AppSettings(
      fontScale: AppFontScale.values
              .where((s) => factor != null && (s.factor - factor).abs() < 0.01)
              .firstOrNull ??
          AppFontScale.lon,
      highContrast: m['highContrast'] as bool? ?? false,
      readAloud: m['readAloud'] as bool? ?? false,
      vibrate: m['vibrate'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.fontScale == fontScale &&
      other.highContrast == highContrast &&
      other.readAloud == readAloud &&
      other.vibrate == vibrate;

  @override
  int get hashCode => Object.hash(fontScale, highContrast, readAloud, vibrate);
}
