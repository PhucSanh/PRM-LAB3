import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Thanh "‹ Quay lại" (Figma: "Thanh tiêu đề/Quay lại + bước" `138:111`; S04 Back + "Sửa" `1:580`).
/// Ba biến thể: chỉ Quay lại · Quay lại + "Bước x/y" ([step]) · Quay lại + nút bên phải ([trailing]).
/// Nút quay lại luôn có chữ (rule.md R-NAV-02), vùng chạm 72 dp.
class AppBackBar extends StatelessWidget implements PreferredSizeWidget {
  const AppBackBar({super.key, this.backLabel = 'Quay lại', this.step, this.trailing, this.onBack});

  final String backLabel;
  final String? step;

  /// Nút bên phải, vd. [AppBarEditButton] ở S04. Không dùng cùng [step].
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBar);

  @override
  Widget build(BuildContext context) {
    assert(step == null || trailing == null, 'AppBackBar: chỉ dùng step hoặc trailing, không dùng cả hai');
    final theme = Theme.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: AppSizes.backButtonWidth,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: TextButton.icon(
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(AppIcons.chevronLeft, size: AppSizes.icon),
          label: Text(backLabel, overflow: TextOverflow.ellipsis),
        ),
      ),
      actions: [
        if (step != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screen),
            child: Text(step!, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        if (trailing != null) Padding(padding: const EdgeInsets.only(right: AppSpacing.screen), child: trailing),
      ],
    );
  }
}

/// Nút "Sửa" viền bo tròn đặt ở [AppBackBar.trailing] (S04, flutter-handoff.md › Bảng 2 › Back+Action).
class AppBarEditButton extends StatelessWidget {
  const AppBarEditButton({super.key, required this.onPressed, this.label = 'Sửa'});

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
