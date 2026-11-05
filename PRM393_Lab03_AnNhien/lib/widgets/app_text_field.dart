import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'form_parts.dart';

/// Ô nhập chữ (Figma S02 `1:103`, S02 Nhập lại tên `1:176`, S06e `12:193`, S12e `14:196`, ST-Validation `29:2`).
/// Nhãn đặt **trên** ô (không floating label); [hint] hiện **dưới** ô, tự thêm "Ví dụ: ".
/// Có [errorText]: nền `errorContainer`, viền `error`, dòng lỗi có icon (TalkBack tự đọc), gợi ý vẫn giữ bên dưới.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
    this.icon,
    this.autofillHints,
    this.textInputAction,
    this.prefixIcon,
    this.placeholder,
  });

  final String label;

  /// Câu gợi ý, vd. "Đi bộ buổi sáng" → hiện "Ví dụ: Đi bộ buổi sáng".
  final String? hint;
  final TextEditingController? controller;

  /// Câu lỗi nói rõ thiếu gì, vd. "Bác chưa nhập tên việc." (AppStyleGuide › Lỗi nhập).
  final String? errorText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  /// Icon trước nhãn (S06: ✎ "Tên việc").
  final IconData? icon;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  /// Icon **trong** ô, bên trái (S12 danh bạ `1:2169`: kính lúp ô "Tìm tên"). F11 bước 03 đề xuất.
  final IconData? prefixIcon;

  /// Chữ mờ trong ô khi trống (S12 danh bạ: "Nhập tên người thân"). Không thay cho [hint] "Ví dụ…".
  /// F11 bước 03 đề xuất.
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = errorText != null;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldLabel(label, icon: icon),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              onChanged: onChanged,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                fillColor: hasError ? scheme.errorContainer : scheme.surface,
                hintText: placeholder,
                hintStyle: placeholder == null
                    ? null
                    : theme.textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                prefixIcon: prefixIcon == null
                    ? null
                    : ExcludeSemantics(
                        child: Icon(prefixIcon,
                            size: AppSizes.icon,
                            color: scheme.onSurfaceVariant)),
                enabledBorder: border(
                    hasError ? scheme.error : scheme.outline, AppSizes.border),
                // Viền dày gấp đôi khi đang gõ: dấu hiệu tiêu điểm không chỉ bằng màu.
                focusedBorder: border(hasError ? scheme.error : scheme.primary,
                    2 * AppSizes.border),
              ),
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldMessage.error(errorText!),
          ],
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FieldMessage.hint(exampleHint(hint!), showIcon: !hasError),
          ],
        ]);
  }
}
