import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Icon lớn trong vòng tròn nền nhạt, đầu hộp thoại và màn ST-* (Figma DLG-*, ST-Loading / Empty / Error).
/// Mặc định nền `primaryContainer`, icon `primary`; [danger] = nền `errorContainer`, icon `error`.
class IconCircle extends StatelessWidget {
  const IconCircle(
      {super.key,
      this.icon,
      this.child,
      this.color,
      this.background,
      this.danger = false})
      : assert(icon != null || child != null);

  final IconData? icon;

  /// Thay cho [icon], vd. vòng xoay của ST-Loading.
  final Widget? child;
  final Color? color;
  final Color? background;
  final bool danger;

  /// Đường kính vòng tròn: icon 64 + 2 × 24.
  static const double diameter = AppSizes.stateIcon + 2 * AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? (danger ? scheme.error : scheme.primary);
    final bg = background ??
        (danger ? scheme.errorContainer : scheme.primaryContainer);
    return ExcludeSemantics(
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(diameter * .34)),
        child: child ?? Icon(icon, size: AppSizes.stateIcon, color: fg),
      ),
    );
  }
}
