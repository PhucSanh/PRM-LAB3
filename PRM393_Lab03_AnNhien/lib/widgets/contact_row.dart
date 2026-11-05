import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import 'relative_card.dart';

/// Hàng liên hệ trong danh bạ (Figma S12 "Chọn từ danh bạ" `1:2175`). F11 bước 03 đề xuất, F0 – Sanh duyệt.
///
/// Avatar **chữ cái đầu** trong ô tròn 48 nền `primaryContainer`, tên (`titleMedium`), dòng phụ
/// ("Con gái · 0912 345 678"), mũi tên › cuối hàng. **Cả hàng** bấm được, cao ≥ 72; chữ dài xuống dòng, không cắt.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.name,
    this.subtitle,
    required this.onTap,
  });

  final String name;
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
      label: subtitle == null ? name : '$name, $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(color: scheme.outlineVariant),
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
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: scheme.primaryContainer, shape: BoxShape.circle),
                  child: Text(
                    RelativeCard.initial(name),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: scheme.primary),
                    textScaler: TextScaler
                        .noScaling, // chữ trong ô cố định 48; tên bên cạnh vẫn phóng to
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: theme.textTheme.titleMedium),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant)),
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
