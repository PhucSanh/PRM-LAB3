import 'package:flutter/material.dart';
import '../theme/app_icons.dart';

/// A quiet, code-native brand tile. Decorative next to the app's written name.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 112});
  final double size;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
        child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * .3),
        border: Border.all(color: scheme.primary.withValues(alpha: .18)),
      ),
      child: Icon(AppIcons.tabHabits,
          size: size * .56, color: scheme.onPrimaryContainer),
    ));
  }
}
