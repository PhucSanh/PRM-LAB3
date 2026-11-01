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
    outline: AppColors.outline,
    outlineVariant: AppColors.borderSubtle,
    scrim: AppColors.scrim,
  );

  /// Thang chữ (DESIGN.md › typography): nhỏ nhất 20, nội dung 24, tiêu đề 30, nút 22.
  static const textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.25),
    headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.35), // headline
    titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.4), // title-md
    titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.4), // title-lg
    bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, height: 1.5), // body-lg
    bodyMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1.5), // body-md
    bodySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, height: 1.5), // caption
    labelLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.4), // label-btn
    labelMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4), // label-nav
  );

  static ThemeData light() {
    final text = textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    );
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.buttonAll);
    const buttonSize = Size(AppSizes.minTarget, AppSizes.minTarget);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: AppColors.background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        toolbarHeight: 88,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          textStyle: text.labelLarge,
          foregroundColor: AppColors.primary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.outline, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.outline, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 96,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: AppSizes.icon)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.surface),
      ),
    );
  }
}
