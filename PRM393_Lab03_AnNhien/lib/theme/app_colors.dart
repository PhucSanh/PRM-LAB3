import 'package:flutter/material.dart';

/// Semantic palette aligned with VELORA v2; accessibility states remain explicit.
/// Màn hình KHÔNG dùng trực tiếp lớp này: đọc qua `Theme.of(context).colorScheme`
/// hoặc `HabitPalette`.
abstract final class AppColors {
  static const background = Color(0xFFFAF9F5);
  // Decorative category surfaces; readable text always uses the semantic theme.
  static const categoryTints = [
    Color(0xFFDCE2D7),
    Color(0xFFEFE4DD),
    Color(0xFFEAE9EF)
  ];
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF27362F);
  static const onSurfaceVariant = Color(0xFF5E6861);
  static const primary = Color(0xFF243D32);
  static const primaryPressed = Color(0xFF1E332B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFDCE2D7);
  static const primaryContainerSoft = Color(0xFFF3EFE8);
  static const onPrimaryContainer = Color(0xFF243D32);
  static const success =
      Color(0xFF243D32); // DESIGN.md success (= primary), Bảng 1
  static const error = Color(0xFFB42318);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFDECE9);
  static const onErrorContainer = Color(0xFF912018);
  static const warningContainer = Color(0xFFFFF3DB);
  static const onWarningContainer = Color(0xFF8A5100);
  static const warningStrong = Color(
      0xFFB26A00); // DESIGN.md warning-strong: icon "○ Chưa làm", bell-off
  static const outline = Color(0xFF7B887F);
  static const borderSubtle = Color(0xFFE3E7DF);
  static const borderStrong = Color(0xFFA0ACA3);
  static const disabledBg = Color(0xFFE6EAE5);
  static const disabledFg = Color(0xFF5C6A61);
  static const scrim = Color(0xFF0F1411);

  /// Bóng (flutter-handoff.md › Bảng 1 › elevation/1, elevation/2).
  static const shadowLevel1 = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 6, color: Color(0x1A202B25))
  ];
  static const shadowLevel2 = [
    BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x3D202B25))
  ];
}

/// Biến thể tương phản cao (S10 "Chữ và nền rõ hơn"). Chỉ dùng lại màu đậm có sẵn trong DESIGN.md;
/// tỉ lệ ghi bên cạnh là WCAG trên nền trắng (chữ chính ≥ 7 : 1).
abstract final class AppColorsHighContrast {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = AppColors.scrim; // 18.61 : 1
  static const onSurfaceVariant = AppColors.onSurface; // 14.65 : 1
  static const primary =
      AppColors.onPrimaryContainer; // chữ trắng trên nó 9.88 : 1
  static const primaryContainer = AppColors.primaryContainer;
  static const onPrimaryContainer =
      Color(0xFF0F3D2A); // habit-move-fg, 9.70 : 1 trên primaryContainer
  static const error = AppColors.onErrorContainer; // chữ trắng trên nó 8.66 : 1
  static const errorContainer = AppColors.errorContainer;
  static const onErrorContainer = AppColors.onErrorContainer; // 7.57 : 1
  static const outline = AppColors.onSurface; // viền ô nhập 14.65 : 1
  static const outlineVariant = AppColors.onSurfaceVariant;
}

/// Màu của 9 thói quen Power 9: nền nhạt, chữ đậm, màu nhấn (ô icon + vạch trái).
class HabitColors {
  const HabitColors(this.bg, this.fg, this.accent);
  final Color bg;
  final Color fg;
  final Color accent;
}

abstract final class HabitPalette {
  /// Icon trên ô màu nhấn luôn trắng (DESIGN.md › habit-icon-*: "icon Lucide trắng").
  static const onAccent = Color(0xFFFFFFFF);

  static const Map<String, HabitColors> byKey = {
    'move':
        HabitColors(Color(0xFFDCE2D7), AppColors.primary, AppColors.primary),
    'purpose':
        HabitColors(Color(0xFFEAE9EF), AppColors.primary, AppColors.primary),
    'downshift':
        HabitColors(Color(0xFFEFE4DD), AppColors.primary, AppColors.primary),
    'eighty':
        HabitColors(Color(0xFFF3EFE8), AppColors.primary, AppColors.primary),
    'plant':
        HabitColors(Color(0xFFDCE2D7), AppColors.primary, AppColors.primary),
    'tea': HabitColors(Color(0xFFEFE4DD), AppColors.primary, AppColors.primary),
    'belong':
        HabitColors(Color(0xFFEAE9EF), AppColors.primary, AppColors.primary),
    'family':
        HabitColors(Color(0xFFEAE9EF), AppColors.primary, AppColors.primary),
    'tribe':
        HabitColors(Color(0xFFDCE2D7), AppColors.primary, AppColors.primary),
  };

  static HabitColors of(String key) => byKey[key] ?? byKey['move']!;
}
