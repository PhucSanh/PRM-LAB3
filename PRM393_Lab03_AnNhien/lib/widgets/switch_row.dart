import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Hàng công tắc (Figma S10 `1:2325` / `1:2474`, N07 `41:2`): ô icon 48 tuỳ chọn, tiêu đề + câu phụ,
/// chữ "Đang bật / Đang tắt" (N07 – không chỉ dựa vào màu), công tắc bên phải. **Cả hàng** bấm được, cao ≥ 72.
/// Chữ phóng to (> 1.5) thì công tắc xuống dòng dưới để tiêu đề không bị bóp.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// `null` = khoá, không bấm được.
  final ValueChanged<bool>? onChanged;
  final IconData? icon;

  /// Hệ số chữ mà từ đó công tắc xuống dòng.
  static const double stackedScale = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onChanged != null;
    final stacked = MediaQuery.textScalerOf(context).scale(1) > stackedScale;
    void toggle() => onChanged?.call(!value);

    // "Đang bật / Đang tắt" nằm dưới câu phụ (N07 đặt dưới công tắc) để cột chữ không bị bóp hẹp.
    final texts = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: theme.textTheme.titleMedium),
      if (subtitle != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
      ],
      const SizedBox(height: AppSpacing.xs),
      Text(
        value ? 'Đang bật' : 'Đang tắt',
        style: theme.textTheme.labelMedium?.copyWith(color: value ? scheme.primary : scheme.onSurfaceVariant),
      ),
    ]);
    final trackColor = WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? scheme.primary : scheme.outline,
    );
    final control = Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStatePropertyAll(scheme.surface),
      trackColor: trackColor,
      trackOutlineColor: trackColor,
    );
    final leading = icon == null
        ? null
        : Container(
            width: AppSizes.habitIcon,
            height: AppSizes.habitIcon,
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: AppRadius.mdAll),
            child: Icon(icon, size: AppSizes.icon, color: scheme.primary),
          );
    final head = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (leading != null) ...[leading, const SizedBox(width: AppSpacing.md)],
      Expanded(child: texts),
    ]);

    final Widget content = stacked
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            head,
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: AlignmentDirectional.centerEnd, child: control),
          ])
        : Row(children: [
            Expanded(child: head),
            const SizedBox(width: AppSpacing.sm),
            control,
          ]);

    return Semantics(
      container: true,
      toggled: value,
      enabled: enabled,
      label: subtitle == null ? title : '$title. $subtitle',
      excludeSemantics: true,
      onTap: enabled ? toggle : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? toggle : null,
          borderRadius: AppRadius.mdAll,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Align(alignment: AlignmentDirectional.centerStart, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
