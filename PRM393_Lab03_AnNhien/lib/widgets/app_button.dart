import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Nút chuẩn của An Nhiên (Figma: "Nút/Chính (filled)" `138:103`, "Nút/Phụ (viền)" `138:107`;
/// biến thể theo flutter-handoff.md › Bảng 2). Cao ≥ 72 dp, luôn có icon + chữ.
/// Mỗi màn tối đa 1 nút [AppButtonKind.primary].
enum AppButtonKind {
  /// Nền `primary`, chữ trắng – hành động chính.
  primary,

  /// Viền `primary` 2 dp – hành động phụ.
  secondary,

  /// Nền `primaryContainer` – hành động phụ nổi hơn ("Thêm việc").
  tonal,

  /// Chỉ chữ – lựa chọn huỷ trong hộp thoại ("Không dời nữa").
  text,

  /// Nền `error`, chữ trắng – xoá / ngưng, chỉ sau khi đã hỏi lại.
  danger,

  /// Viền `error` 2 dp – nút xoá đứng dưới nút an toàn (DLG-Delete, SG-19).
  dangerOutline,
}

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
        ? const SizedBox.square(
            dimension: AppSizes.spinnerInButton,
            child: CircularProgressIndicator(strokeWidth: AppSizes.spinnerStroke),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.icon),
              const SizedBox(width: AppSpacing.md),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    final action = busy ? null : onPressed;
    final button = switch (kind) {
      AppButtonKind.primary => FilledButton(onPressed: action, child: child),
      AppButtonKind.secondary => OutlinedButton(onPressed: action, child: child),
      AppButtonKind.tonal => FilledButton.tonal(
          onPressed: action,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
          child: child,
        ),
      AppButtonKind.text => TextButton(onPressed: action, child: child),
      AppButtonKind.danger => FilledButton(
          onPressed: action,
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          child: child,
        ),
      AppButtonKind.dangerOutline => OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error, width: AppSizes.border),
          ),
          child: child,
        ),
    };
    return Semantics(
      button: true,
      enabled: action != null,
      label: label,
      excludeSemantics: true,
      child: SizedBox(width: double.infinity, child: button),
    );
  }
}
