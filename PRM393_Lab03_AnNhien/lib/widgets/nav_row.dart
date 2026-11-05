import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Hàng điều hướng dạng thẻ (Figma S10 `1:2434`–`1:2464`: Cách dùng đơn giản, Thông tin của Bác, Lời nhắc,
/// Dữ liệu trên điện thoại): ô icon 48 nền `primaryContainer`, tiêu đề (+ câu phụ), mũi tên › cuối hàng.
/// **Cả hàng** bấm được, cao ≥ 72; chữ dài thì xuống dòng, không cắt.
class NavRow extends StatelessWidget {
  const NavRow(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      required this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      label: title,
      hint: subtitle,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: scheme.secondaryContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.md),
              child: Row(children: [
                Container(
                  width: AppSizes.habitIcon,
                  height: AppSizes.habitIcon,
                  decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: AppRadius.mdAll),
                  child: Icon(icon, size: AppSizes.icon, color: scheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(subtitle!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ]),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(AppIcons.chevronRight,
                    size: AppSizes.icon, color: scheme.onSurfaceVariant),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
