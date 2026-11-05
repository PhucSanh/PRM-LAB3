import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Thanh "‹ Quay lại" (Figma: "Thanh tiêu đề/Quay lại + bước" `138:111`; S04 Back + "Sửa" `1:580`).
/// Ba biến thể: chỉ Quay lại · Quay lại + "Bước x/y" ([step]) · Quay lại + nút bên phải ([trailing]).
/// Nút quay lại luôn có chữ (rule.md R-NAV-02), vùng chạm 72 dp.
class AppBackBar extends StatelessWidget implements PreferredSizeWidget {
  const AppBackBar({
    super.key,
    this.backLabel = 'Quay lại',
    this.step,
    this.trailing,
    this.onBack,
    double height = AppSizes.appBar,
    bool stacked = false,
    double? backWidth,
  })  : _height = height,
        _stacked = stacked,
        _backWidth = backWidth;

  /// Resolve preferred height before Scaffold lays out its app bar.
  /// Never shrink Back/step labels when the system text size increases.
  factory AppBackBar.adaptive(
    BuildContext context, {
    Key? key,
    String backLabel = 'Quay lại',
    String? step,
    Widget? trailing,
    VoidCallback? onBack,
  }) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final width = MediaQuery.sizeOf(context).width - buttonPadding.horizontal;
    final hasEnd = step != null || trailing != null;
    final buttonPadding = (theme.textButtonTheme.style?.padding?.resolve({}) ??
            const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md))
        .resolve(Directionality.of(context));
    double naturalWidth(String label, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final backNaturalWidth =
        naturalWidth(backLabel, theme.textTheme.labelLarge) +
            AppSizes.icon +
            AppSpacing.sm +
            buttonPadding.horizontal;
    final endNaturalWidth = step != null
        ? naturalWidth(step, theme.textTheme.labelMedium)
        : naturalWidth(trailing is AppBarEditButton ? trailing.label : 'Sửa',
                theme.textTheme.labelLarge) +
            AppSizes.iconInChip +
            AppSpacing.sm +
            buttonPadding.horizontal;
    final stacked =
        hasEnd && backNaturalWidth + endNaturalWidth + AppSpacing.sm > width;
    final backWidth = hasEnd && !stacked
        ? backNaturalWidth.clamp(
            width / 2, width - endNaturalWidth - AppSpacing.sm)
        : width;
    double measure(String label, TextStyle? style, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout(maxWidth: maxWidth.clamp(1, double.infinity));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final backHeight = measure(
            backLabel,
            theme.textTheme.labelLarge,
            backWidth -
                AppSizes.icon -
                AppSpacing.sm -
                buttonPadding.horizontal) +
        2 * AppSpacing.md;
    final endHeight = step != null
        ? measure(
            step, theme.textTheme.labelMedium, stacked ? width : width / 2)
        : scaler.scale(theme.textTheme.labelLarge!.fontSize!) *
                theme.textTheme.labelLarge!.height! +
            2 * AppSpacing.md;
    final firstHeight = backHeight.clamp(AppSizes.minTarget, double.infinity);
    final height = stacked
        ? firstHeight + endHeight.clamp(AppSizes.minTarget, double.infinity)
        : firstHeight.clamp(hasEnd ? endHeight : 0, double.infinity);
    return AppBackBar(
      key: key,
      backLabel: backLabel,
      step: step,
      trailing: trailing,
      onBack: onBack,
      height: height + 2 * AppSpacing.sm,
      stacked: stacked,
      backWidth: hasEnd && !stacked ? backWidth : null,
    );
  }

  AppBackBar adapt(BuildContext context) => AppBackBar.adaptive(context,
      key: key,
      backLabel: backLabel,
      step: step,
      trailing: trailing,
      onBack: onBack);

  final String backLabel;
  final String? step;
  final Widget? trailing;
  final VoidCallback? onBack;
  final double _height;
  final bool _stacked;
  final double? _backWidth;

  @override
  Size get preferredSize => Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    assert(step == null || trailing == null,
        'AppBackBar: chỉ dùng step hoặc trailing, không dùng cả hai');
    final theme = Theme.of(context);
    final back = TextButton(
      onPressed: onBack ??
          () {
            final router = GoRouter.maybeOf(context);
            if (router != null && !router.canPop()) {
              router.go('/calendar');
            } else {
              Navigator.of(context).maybePop();
            }
          },
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(AppIcons.chevronLeft, size: AppSizes.icon),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(backLabel)),
      ]),
    );
    final end = trailing ??
        (step == null
            ? null
            : Text(step!,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)));
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          child: _stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: back),
                      if (end != null)
                        Expanded(
                            child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: end)),
                    ])
              : Row(children: [
                  if (end == null)
                    Expanded(
                        child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: back))
                  else
                    SizedBox(
                        width: _backWidth ??
                            (MediaQuery.sizeOf(context).width -
                                    2 * AppSpacing.base) /
                                2,
                        child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: back)),
                  if (end != null)
                    Expanded(
                        child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: end)),
                ]),
        ),
      ),
    );
  }
}

/// Nút "Sửa" viền bo tròn đặt ở [AppBackBar.trailing] (S04, flutter-handoff.md › Bảng 2 › Back+Action).
class AppBarEditButton extends StatelessWidget {
  const AppBarEditButton(
      {super.key, required this.onPressed, this.label = 'Sửa'});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
      icon: const Icon(AppIcons.pencil, size: AppSizes.iconInChip),
      label: Text(label),
    );
  }
}
