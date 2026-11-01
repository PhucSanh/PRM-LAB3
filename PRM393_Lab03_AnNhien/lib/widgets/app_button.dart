import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Nút chuẩn của An Nhiên (Figma: "Nút/Chính (filled)", "Nút/Phụ (viền)").
/// Cao 72 dp, luôn có icon + chữ. Mỗi màn tối đa 1 nút [AppButtonKind.primary].
enum AppButtonKind { primary, secondary, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = busy
        ? const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.icon),
              const SizedBox(width: AppSpacing.md),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    final action = busy ? null : onPressed;
    final button = switch (kind) {
      AppButtonKind.primary => FilledButton(onPressed: action, child: child),
      AppButtonKind.secondary => OutlinedButton(onPressed: action, child: child),
      AppButtonKind.danger => OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error, width: 2),
          ),
          child: child,
        ),
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(width: double.infinity, child: button),
    );
  }
}
