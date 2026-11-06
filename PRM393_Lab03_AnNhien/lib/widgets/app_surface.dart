import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Shared matte surface for forms, account, reminders and feature cards.
/// High-contrast outlines are inherited from the application's card theme.
class AppSurface extends StatelessWidget {
  const AppSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(AppSpacing.screen),
      this.color,
      this.onTap,
      this.selected = false});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    final themedShape = theme.cardTheme.shape;
    final shape = RoundedRectangleBorder(
        borderRadius: AppRadius.cardAll,
        side: selected
            ? BorderSide(color: colors.primary, width: 1.5)
            : (themedShape is OutlinedBorder
                ? themedShape.side
                : BorderSide.none));
    return Material(
        color: color ??
            (selected ? colors.primaryContainer : colors.secondaryContainer),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap, child: Padding(padding: padding, child: child)));
  }
}
