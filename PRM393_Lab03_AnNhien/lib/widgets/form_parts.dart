import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';

/// Nhãn đặt **trên** ô nhập / ô giờ / nhóm lựa chọn (Figma S02, S06, S12: chữ 24 đậm, icon 32 tuỳ chọn).
/// Vd. "✎ Tên việc", "Là gì của Bác?".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = Text(text, style: theme.textTheme.titleMedium);
    if (icon == null) return label;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: AppSizes.icon, color: theme.colorScheme.primary),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: label),
    ]);
  }
}

/// Dòng chữ dưới ô nhập: [FieldMessage.error] ("ⓘ Bác chưa nhập tên việc." – đỏ, đậm, TalkBack tự đọc)
/// hoặc [FieldMessage.hint] ("ⓘ Ví dụ: Mai, Hùng" – xám). Figma ST-Validation `29:2`, S12e `14:196`.
class FieldMessage extends StatelessWidget {
  const FieldMessage.error(this.text, {super.key})
      : isError = true,
        showIcon = true;

  /// [showIcon] = false khi đứng ngay dưới dòng lỗi: chữ thụt vào thẳng hàng với câu lỗi (S12e).
  const FieldMessage.hint(this.text, {super.key, this.showIcon = true}) : isError = false;

  final String text;
  final bool isError;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = isError
        ? theme.textTheme.titleMedium?.copyWith(color: scheme.error)
        : theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final icon = isError ? AppIcons.alert : AppIcons.info;
    final line = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showIcon)
        ExcludeSemantics(
          child: Icon(icon, size: AppSizes.icon, color: isError ? scheme.error : scheme.onSurfaceVariant),
        )
      else
        const SizedBox(width: AppSizes.icon),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(text, style: style)),
    ]);
    return isError ? Semantics(liveRegion: true, child: line) : line;
  }
}

/// Thêm tiền tố "Ví dụ: " cho câu gợi ý nếu chưa có (AppStyleGuide SG-15, "Lỗi nhập" 3 phần).
String exampleHint(String hint) => hint.startsWith('Ví dụ') ? hint : 'Ví dụ: $hint';
