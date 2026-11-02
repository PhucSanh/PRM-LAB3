import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// ThemeData duy nhất của app. Chủ file: A – Sanh.
abstract final class AppTheme {
  static const fontFamily = 'BeVietnamPro';

  static const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.primary,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColors.primaryContainerSoft,
    onSecondaryContainer: AppColors.onPrimaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainerLowest: AppColors.surface,
    outline: AppColors.outline,
    outlineVariant: AppColors.borderSubtle,
    scrim: AppColors.scrim,
  );

  /// S10 "Chữ và nền rõ hơn": cùng bố cục, đổi màu (accessibility.md: chữ chính ≥ 7 : 1).
  static const highContrastScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColorsHighContrast.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColorsHighContrast.primaryContainer,
    onPrimaryContainer: AppColorsHighContrast.onPrimaryContainer,
    secondary: AppColorsHighContrast.primary,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColorsHighContrast.primaryContainer,
    onSecondaryContainer: AppColorsHighContrast.onPrimaryContainer,
    error: AppColorsHighContrast.error,
    onError: AppColors.onError,
    errorContainer: AppColorsHighContrast.errorContainer,
    onErrorContainer: AppColorsHighContrast.onErrorContainer,
    surface: AppColorsHighContrast.surface,
    onSurface: AppColorsHighContrast.onSurface,
    onSurfaceVariant: AppColorsHighContrast.onSurfaceVariant,
    surfaceContainerLowest: AppColorsHighContrast.surface,
    outline: AppColorsHighContrast.outline,
    outlineVariant: AppColorsHighContrast.outlineVariant,
    scrim: AppColors.scrim,
  );

  /// Thang chữ (DESIGN.md › typography): nhỏ nhất 20, nội dung 24, tiêu đề 30, nút 22.
  /// Điền đủ 15 kiểu để widget Material (chip, tooltip, picker…) không rơi về cỡ mặc định < 20.
  static const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.25), // display
    displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.25), // display
    displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.25), // display
    headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.35), // headline
    headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.35), // headline
    headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.4), // title-md
    titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.4), // title-md
    titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.4), // title-lg
    titleSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.4), // label-btn
    bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, height: 1.5), // body-lg
    bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1.5), // body-md
    bodySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1.5), // caption
    labelLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.4), // label-btn
    labelMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4), // label-nav
    labelSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4), // label-nav
  );

  static ThemeData light() => _build(colorScheme, background: AppColors.background);

  static ThemeData highContrast() => _build(highContrastScheme, background: AppColorsHighContrast.background);

  static ThemeData _build(ColorScheme scheme, {required Color background}) {
    final text = textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.buttonAll);
    const buttonSize = Size(AppSizes.minTarget, AppSizes.minTarget);
    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: scheme.outline, width: AppSizes.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        toolbarHeight: AppSizes.appBar,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledFg,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
          backgroundColor: scheme.surface,
          side: BorderSide(color: scheme.primary, width: AppSizes.border),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        // 22 trên + 22 dưới + 1 dòng body-lg (24 × 1.5) ≈ 80 ≥ minTarget.
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 22),
        border: inputBorder,
        enabledBorder: inputBorder,
        errorStyle: text.bodyMedium?.copyWith(color: scheme.error),
        helperStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navBar,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: AppSizes.icon)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.surface),
      ),
    );
  }
}

/// Kiểu chữ ngoài `TextTheme` (DESIGN.md › typography; Bảng 1 gọi là `AppText`).
/// Không có màu: lấy màu từ `DefaultTextStyle` / `copyWith(color: scheme.…)`.
abstract final class AppText {
  /// `body-lg-strong` 24 / 1.5 / 600 – câu nhấn trong nội dung.
  static const bodyLgStrong =
      TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 24, fontWeight: FontWeight.w600, height: 1.5);

  /// `numeric-lg` 30 / 1.25 / 700 – số giờ, mã ghép nối.
  static const numericLg =
      TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 30, fontWeight: FontWeight.w700, height: 1.25);
}
