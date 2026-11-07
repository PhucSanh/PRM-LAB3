import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'form_parts.dart';

/// Ô chọn dạng danh sách thả xuống, cùng kiểu với `AppTextField`: nhãn ở
/// trên, ô cao ≥ `AppSizes.minTarget`, bấm vào hiện danh sách để chọn.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
    this.labelOf,
  });

  final String label;
  final List<T> options;
  final T? value;
  final ValueChanged<T?>? onChanged;

  /// Chữ mờ trong ô khi chưa chọn gì.
  final String? hint;

  /// Chữ hiện cho mỗi lựa chọn; mặc định `toString()`.
  final String Function(T)? labelOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    String text(T v) => labelOf?.call(v) ?? v.toString();
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: AppRadius.inputAll,
          borderSide: BorderSide(color: color, width: width),
        );
    final style =
        theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: FieldLabel(label)),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: label,
            child: DropdownButtonFormField<T>(
              initialValue: value,
              isExpanded: true,
              itemHeight: AppSizes.minTarget,
              iconSize: AppSizes.icon + 8,
              icon: const Icon(Icons.expand_more_rounded),
              borderRadius: AppRadius.inputAll,
              dropdownColor: scheme.surface,
              style: style?.copyWith(color: scheme.onSurface),
              hint: hint == null
                  ? null
                  : Text(hint!,
                      style: style?.copyWith(color: scheme.onSurfaceVariant)),
              decoration: InputDecoration(
                fillColor: scheme.secondaryContainer,
                constraints:
                    const BoxConstraints(minHeight: AppSizes.minTarget),
                enabledBorder: border(scheme.outlineVariant, 1),
                focusedBorder: border(scheme.primary, 2 * AppSizes.border),
              ),
              items: [
                for (final option in options)
                  DropdownMenuItem<T>(
                      value: option,
                      child: Text(text(option),
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: onChanged,
            ),
          ),
        ]);
  }
}
