import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ThemeData duy nhất của app. Chủ file: A – Sanh.
abstract final class AppTheme {
  static const fontFamily = AppTypography.fontFamily;
  static bool _licensesRegistered = false;

  static void registerFontLicenses() {
    if (_licensesRegistered) {
      return;
    }
    _licensesRegistered = true;
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(
          ['Noto Serif Display', 'Noto Serif'],
          await rootBundle
              .loadString('assets/fonts/NotoSerifDisplay-LICENSE.txt'));
    });
  }

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
    tertiary: Color(0xFF785A49),
    onTertiary: AppColors.onPrimary,
    tertiaryContainer: Color(0xFFF1E6D2),
    onTertiaryContainer: Color(0xFF503E31),
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

  /// TYPE-01: shared/unknown role defaults to the elderly text scale.
  static const textTheme = AppTypography.elderly;

  static ThemeData light({bool caregiver = false}) => _build(colorScheme,
      background: AppColors.background, caregiver: caregiver);

  static ThemeData highContrast({bool caregiver = false}) =>
      _build(highContrastScheme,
          background: AppColorsHighContrast.background, caregiver: caregiver);

  static ThemeData _build(ColorScheme scheme,
      {required Color background, required bool caregiver}) {
    final typography = caregiver ? AppTypography.caregiver : textTheme;
    final sans = typography.apply(
      fontFamily: fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final text = sans.copyWith(
      displayLarge: sans.displayLarge?.copyWith(fontFamily: 'NotoSerifDisplay'),
      displayMedium:
          sans.displayMedium?.copyWith(fontFamily: 'NotoSerifDisplay'),
      displaySmall: sans.displaySmall?.copyWith(fontFamily: 'NotoSerifDisplay'),
      headlineLarge:
          sans.headlineLarge?.copyWith(fontFamily: 'NotoSerifDisplay'),
      headlineMedium:
          sans.headlineMedium?.copyWith(fontFamily: 'NotoSerifDisplay'),
      headlineSmall:
          sans.headlineSmall?.copyWith(fontFamily: 'NotoSerifDisplay'),
    );
    // A 56dp button is a pill. Keep the corner radius bounded when a large
    // multi-line label makes the button taller, so the endcaps cannot clip text.
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
    );
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
        scrolledUnderElevation: 0,
        toolbarHeight: AppSizes.appBar,
        titleTextStyle: text.headlineMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledFg,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
          backgroundColor: scheme.primaryContainer,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          textStyle: text.labelLarge,
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        labelStyle: text.labelMedium,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 18),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonAll),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primaryContainer,
        selectionHandleColor: scheme.primary,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: scheme == highContrastScheme
              ? BorderSide(color: scheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        // 22 trên + 22 dưới + 1 dòng body-lg (24 × 1.5) ≈ 80 ≥ minTarget.
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: 22),
        labelStyle: text.bodyMedium,
        floatingLabelStyle: text.bodyMedium,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        counterStyle: text.bodySmall,
        helperMaxLines: 10,
        errorMaxLines: 10,
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
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: text.labelMedium,
        unselectedLabelStyle: text.labelMedium,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: text.bodySmall?.copyWith(color: scheme.surface),
        decoration: BoxDecoration(
          color: scheme.onSurface,
          borderRadius: AppRadius.smAll,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
      ),
      datePickerTheme: DatePickerThemeData(
        headerHeadlineStyle: text.headlineSmall,
        headerHelpStyle: text.labelMedium,
        weekdayStyle: text.labelMedium,
        dayStyle: text.bodySmall,
        yearStyle: text.bodyMedium,
      ),
      timePickerTheme: TimePickerThemeData(
        helpTextStyle: text.labelMedium,
        hourMinuteTextStyle: text.headlineMedium,
        dayPeriodTextStyle: text.labelMedium,
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedLabelTextStyle: text.labelMedium,
        unselectedLabelTextStyle: text.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navBar,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        iconTheme:
            const WidgetStatePropertyAll(IconThemeData(size: AppSizes.icon)),
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
  static const bodyLgStrong = TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.5);

  /// `numeric-lg` 30 / 1.25 / 700 – số giờ, mã ghép nối.
  static const numericLg = TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.25);
}
