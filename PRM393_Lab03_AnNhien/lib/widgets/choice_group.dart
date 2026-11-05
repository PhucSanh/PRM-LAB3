import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Cách xếp của [ChoiceGroup].
enum ChoiceLayout {
  /// Xếp dọc, full-width (S01 cỡ chữ, S10, S12 "Là gì của Bác?", N12 / C07 Lặp lại).
  list,

  /// Xếp ngang, chia đều (S02 Ông / Bà, S06 Mỗi ngày / Chọn ngày). Chỉ nên 2–3 lựa chọn (SG-29).
  segmented,
}

/// Một lựa chọn trong [ChoiceGroup].
class ChoiceOption<T> {
  const ChoiceOption(
      {required this.value,
      required this.label,
      this.description,
      this.icon,
      this.previewScale});

  final T value;
  final String label;

  /// Câu phụ dưới nhãn, vd. "Lập lịch giúp bố mẹ, ông bà" (C01). Chỉ hiện ở [ChoiceLayout.list].
  final String? description;

  /// Icon minh hoạ sau dấu chọn, vd. 🙂 cho "Con".
  final IconData? icon;

  /// S01 / S10: vẽ nhãn ở đúng hệ số chữ của lựa chọn (1.0 / 1.15 / 1.3) để Bác xem trước cỡ chữ.
  final double? previewScale;
}

/// Nhóm chọn một (Figma S01 `1:2`, N12 Lặp lại `43:95`, C07 Lặp lại `1:2764`; S10, S12 cùng kiểu).
/// Đang chọn: nền `primaryContainer`, viền `primary`, **dấu tích** + chữ "Đang chọn" (không chỉ dựa vào màu).
/// Mỗi ô cao ≥ 72, cả ô bấm được, TalkBack đọc là nút radio.
class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.layout = ChoiceLayout.list,
  });

  final List<ChoiceOption<T>> options;

  /// `null` = chưa chọn gì.
  final T? value;
  final ValueChanged<T> onChanged;
  final ChoiceLayout layout;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (final option in options)
        _ChoiceTile<T>(
          option: option,
          selected: option.value == value,
          segmented: layout == ChoiceLayout.segmented,
          onTap: () => onChanged(option.value),
        ),
    ];
    return switch (layout) {
      ChoiceLayout.list =>
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.betweenTargets),
            tile,
          ],
        ]),
      ChoiceLayout.segmented => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final (i, tile) in tiles.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.betweenTargets),
              Expanded(child: tile),
            ],
          ]),
        ),
    };
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile(
      {required this.option,
      required this.selected,
      required this.segmented,
      required this.onTap});

  final ChoiceOption<T> option;
  final bool selected;
  final bool segmented;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final sub = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    final mark = Icon(
      selected ? AppIcons.radioOn : AppIcons.radioOff,
      size: AppSizes.icon,
      color: selected ? scheme.primary : scheme.outline,
    );
    Widget label = Text(
      option.label,
      style: (option.previewScale != null
              ? theme.textTheme.bodyMedium
              : theme.textTheme.titleMedium)
          ?.copyWith(color: fg, fontWeight: FontWeight.w600),
      textAlign: segmented ? TextAlign.center : TextAlign.start,
    );
    if (option.previewScale != null) {
      label = MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(option.previewScale!)),
        child: label,
      );
    }
    final icon = option.icon == null
        ? null
        : Icon(option.icon, size: AppSizes.icon, color: fg);

    final Widget content;
    if (segmented) {
      content = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        mark,
        const SizedBox(width: AppSpacing.sm),
        if (icon != null) ...[icon, const SizedBox(width: AppSpacing.sm)],
        Flexible(child: label),
      ]);
    } else {
      content = Row(children: [
        mark,
        const SizedBox(width: AppSpacing.md),
        if (icon != null) ...[icon, const SizedBox(width: AppSpacing.md)],
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Nhãn bên trái, "Đang chọn" bên phải; hẹp quá thì "Đang chọn" xuống dòng.
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  label,
                  if (selected)
                    Text('Đang chọn',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
            if (option.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(option.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: sub)),
            ],
          ]),
        ),
      ]);
    }

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      selected: selected,
      label: option.label,
      hint: option.description,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardAll,
          side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: AppSizes.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.md),
              child: Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
