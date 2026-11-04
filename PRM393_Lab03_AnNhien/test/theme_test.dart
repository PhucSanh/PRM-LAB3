import 'support/demo_container.dart';
import 'package:an_nhien/app.dart';
import 'package:an_nhien/theme/app_colors.dart';
import 'package:an_nhien/theme/app_theme.dart';
import 'package:an_nhien/theme/display_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('mọi kiểu chữ ≥ 20 sp (rule.md)', () {
    final styles = [
      ...[
        AppTheme.textTheme.displayLarge,
        AppTheme.textTheme.displayMedium,
        AppTheme.textTheme.displaySmall,
        AppTheme.textTheme.headlineLarge,
        AppTheme.textTheme.headlineMedium,
        AppTheme.textTheme.headlineSmall,
        AppTheme.textTheme.titleLarge,
        AppTheme.textTheme.titleMedium,
        AppTheme.textTheme.titleSmall,
        AppTheme.textTheme.bodyLarge,
        AppTheme.textTheme.bodyMedium,
        AppTheme.textTheme.bodySmall,
        AppTheme.textTheme.labelLarge,
        AppTheme.textTheme.labelMedium,
        AppTheme.textTheme.labelSmall,
      ],
      AppText.bodyLgStrong,
      AppText.numericLg,
    ];
    for (final s in styles) {
      expect(s?.fontSize, greaterThanOrEqualTo(20));
    }
  });

  test('tương phản cao: chữ chính ≥ 7 : 1', () {
    final s = AppTheme.highContrastScheme;
    expect(_contrast(s.onSurface, s.surface), greaterThanOrEqualTo(7));
    expect(_contrast(s.onSurfaceVariant, s.surface), greaterThanOrEqualTo(7));
    expect(_contrast(s.onPrimary, s.primary), greaterThanOrEqualTo(7));
    expect(_contrast(s.onPrimaryContainer, s.primaryContainer),
        greaterThanOrEqualTo(7));
    expect(_contrast(s.onError, s.error), greaterThanOrEqualTo(7));
    expect(_contrast(s.onErrorContainer, s.errorContainer),
        greaterThanOrEqualTo(7));
    expect(AppTheme.highContrast().scaffoldBackgroundColor,
        AppColorsHighContrast.background);
  });

  test('mặc định cỡ chữ Lớn, tương phản cao tắt', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(fontScaleProvider), AppFontScale.lon);
    expect(container.read(highContrastProvider), isFalse);
  });

  testWidgets('đổi cỡ chữ / tương phản cao áp dụng toàn app', (tester) async {
    final container = demoContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const AnNhienApp()));
    await tester.pumpAndSettle();

    BuildContext ctx() => tester.element(find.byType(Scaffold).first);
    double scale() => MediaQuery.textScalerOf(ctx()).scale(1);

    expect(scale(), closeTo(1.15, 0.001));
    container.read(fontScaleProvider.notifier).set(AppFontScale.ratLon);
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1.3, 0.001));
    container.read(fontScaleProvider.notifier).set(AppFontScale.vua);
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1.0, 0.001));

    expect(Theme.of(ctx()).colorScheme.onSurface, AppColors.onSurface);
    container.read(highContrastProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(
        Theme.of(ctx()).colorScheme.onSurface, AppColorsHighContrast.onSurface);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
  });
}
