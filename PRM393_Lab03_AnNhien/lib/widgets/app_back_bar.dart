import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Thanh "‹ Quay lại" + "Bước x/y" (Figma: "Thanh tiêu đề/Quay lại + bước").
/// Nút quay lại luôn có chữ (rule.md R-NAV-02), vùng chạm 72 dp.
class AppBackBar extends StatelessWidget implements PreferredSizeWidget {
  const AppBackBar({super.key, this.backLabel = 'Quay lại', this.step, this.onBack});

  final String backLabel;
  final String? step;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 180,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: TextButton.icon(
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.chevron_left, size: AppSizes.icon),
          label: Text(backLabel, overflow: TextOverflow.ellipsis),
        ),
      ),
      actions: [
        if (step != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screen),
            child: Text(step!, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}
