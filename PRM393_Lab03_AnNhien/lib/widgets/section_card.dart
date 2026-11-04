import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Khung thẻ trắng, viền nhạt, bo 16 (Figma S10 `1:2340` "Card Cỡ chữ", `1:2374` "Card 3 công tắc").
/// Tuỳ chọn đầu thẻ: icon 32 màu `primary` + tiêu đề (đọc là heading). Nội dung tự cao theo chữ.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.icon, this.title, required this.child});

  final IconData? icon;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (title != null) ...[
            Row(children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.icon, color: scheme.primary),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Semantics(
                    header: true,
                    child: Text(title!, style: theme.textTheme.titleLarge)),
              ),
            ]),
            const SizedBox(height: AppSpacing.base),
          ],
          child,
        ]),
      ),
    );
  }
}
